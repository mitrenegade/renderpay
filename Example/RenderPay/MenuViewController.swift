//
//  MenuViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import RenderPay
import RxSwift
import RxCocoa
import Stripe
import RenderCloud


enum MenuItem: String {
    case stripeConnect = "Stripe connect"
    case stripePayment = "Payment info"
    case charge = "Test payment"
    case version = "Version"
    case login = "Login"
    case logout = "Logout"
}
fileprivate var loggedInMenu: [MenuItem] = [.stripeConnect, .stripePayment, .charge, .version, .logout]
fileprivate let loggedOutMenu: [MenuItem] = [.login]

class MenuViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    fileprivate var disposeBag = DisposeBag()
    var connectService: ConnectService!
    var paymentService: PaymentService!
    var apiService: CloudAPIService!

    var paymentStatus: PaymentStatus = .loading
    
    var menuItems: [MenuItem] = loggedOutMenu
    var email: String?
    var userId: String? {
        didSet {
            if let userId = userId, oldValue == nil {
                connectService.startListeningForAccount(userId: userId)
                connectService.accountState.skip(1).distinctUntilChanged().subscribe(onNext: { [weak self] state in
                    Globals.consoleLogger.logEvent("StripeConnectService accountState changed: \(state)")
                    self?.reloadTable()
                }).disposed(by: disposeBag)

                paymentService.startListeningForAccount(userId: userId)
                paymentService.statusObserver
                    .asObservable()
                    .distinctUntilChanged( {$0 == $1} )
                    .subscribe(onNext: refresh)
                    .disposed(by: disposeBag)
            }
        }
    }

    @IBOutlet weak var buttonConnect: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        apiService = Globals.apiService
        connectService = Globals.stripeConnectService
        paymentService = Globals.stripePaymentService

        navigationItem.title = "RenderPay Menu"
        AuthService.shared.startup()
        AuthService.shared.loginState.subscribe(onNext: { [weak self] state in
            Globals.consoleLogger.logEvent("MenuViewController authService state changed: \(state)")
            if state == .loggedOut {
                self?.menuItems = loggedOutMenu
                self?.reloadTable()
                self?.promptForLogin()
            } else {
                self?.email = AuthService.currentUser?.email
                self?.userId = AuthService.currentUser?.uid
                self?.menuItems = loggedInMenu
                self?.reloadTable()
            }
        }).disposed(by: disposeBag)
    }
    
    
    lazy var refresh: (PaymentStatus)->() = { [weak self] (status) in
        self?.paymentStatus = status
        switch status {
        case .loading:
            Globals.consoleLogger.logEvent("PaymentStatus: loading")
            if let self = self {
                self.paymentService.loadPayment(hostController: self)
            }
        case .ready(let source):
            if let last4 = source.last4, let userId = self?.userId {
                Globals.consoleLogger.logEvent("PaymentStatus: ready with updated source \(source.id) last4 \(last4)) label \(source.label)")
                self?.paymentService.savePaymentInfo(userId: userId, source: source.id, last4: last4, label: source.label)
            }
        case .needsRefresh(let card):
            Globals.consoleLogger.logEvent("PaymentStatus: needsRefresh")
            self?.simpleAlert("Please refresh your card", message: "We have updated our payment methods. Please remove and enter your payment method again.")
        default:
            break
        }
        DispatchQueue.main.async {
            self?.reloadTable()
        }
    }

    func promptForLogin() {
        let alert = UIAlertController(title: "Please Login", message: "Enter your email", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Email"
        }
        alert.addAction(UIAlertAction(title: "Next", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let email = textField.text, !email.isEmpty {
                self.promptForPassword(email: email)
            } else {
                print("Invalid email")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func promptForPassword(email: String) {
        let alert = UIAlertController(title: "Please Login", message: "Enter your password", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Next", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let password = textField.text, !password.isEmpty {
                self.doLogin(email: email, password: password)
            } else {
                print("Invalid password")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func doLogin(email: String, password: String) {
        Globals.consoleLogger.logEvent("Do login")
        AuthService.shared.loginUser(email: email, password: password) { [weak self] error in
            if let error = error {
                Globals.consoleLogger.logEvent("Do login with error", params:["error": error])
                print("Error!")
                let alert = UIAlertController(title: "Login error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true)
            } else {
                Globals.consoleLogger.logEvent("Do login with success")
                print("Login success")
                let alert = UIAlertController(title: "Login success", message: nil, preferredStyle: .alert)
                self?.present(alert, animated: true)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            }
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
    
    func connectToStripe() {
        guard let userId = userId else { return }
        connectService.connectToAccount(userId)
    }
    
    func refreshPayment() {
        Globals.consoleLogger.logEvent("RefreshPayment called")
        switch paymentStatus {
        case .loading:
            break
        case .noCustomer:
            guard let userId = userId, let email = email else {
                simpleAlert("Cannot create customer", message: "userId and email must exist for user")
                return
            }
            paymentService.createCustomer(userId: userId, email: email, completion: { [weak self] (customerId, error) in
                if let error = error as NSError? {
                    self?.simpleAlert("Could not create customer", defaultMessage: "There was an error", error: error)
                } else if let customerId = customerId {
                    print("CustomerId created: \(customerId)")
                    // let customerId BehaviorRelay handle updates
                }
            })
        case .needsRefresh:
            // show payment methods
            paymentService.shouldShowPaymentController()
            break
        case .noPaymentMethod:
            // show payment methods
            paymentService.shouldShowPaymentController()
        case .ready:
            // change payment method or show it
            // show payment methods
            paymentService.shouldShowPaymentController()
            break
        }
    }
}

extension MenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.row < menuItems.count {
            switch menuItems[indexPath.row] {
            case .stripeConnect:
                cell.textLabel?.text = connectService.accountState.value.description
            case .stripePayment:
                print("StripePaymentService status changed: \(paymentStatus)")
                let paymentAccountString: String
                switch paymentStatus {
                case .loading:
                    paymentAccountString = "Loading..."
                case .noCustomer:
                    paymentAccountString = "No customer found"
                case .noPaymentMethod:
                    paymentAccountString = "Click to add payment method"
                case .ready(let source):
                    paymentAccountString = "Payment account: \(source.label)"
                case .needsRefresh:
                    paymentAccountString = "Card needs refresh"
                }
                cell.textLabel?.text = paymentAccountString
            case .charge:
                cell.textLabel?.text = menuItems[indexPath.row].rawValue
                switch connectService.accountState.value {
                case .account:
                    cell.textLabel?.alpha = 1
                default:
                    cell.textLabel?.alpha = 0.5
                }
            case .version:
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                cell.textLabel?.text = "Version: \(version ?? "unknown") (\(build ?? "unknown"))\(TESTING ? "t" : "")"
            default:
                cell.textLabel?.text = menuItems[indexPath.row].rawValue
            }
        } else {
            cell.textLabel?.text = nil
        }
        return cell
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < menuItems.count else { return }
        let selection = menuItems[indexPath.row]
        switch selection {
        case .login:
            promptForLogin()
        case .stripeConnect:
            connectToStripe()
        case .stripePayment:
            refreshPayment()
        case .charge:
            switch (connectService.accountState.value, paymentStatus) {
            case (.account, .ready):
                // connectId and payment source are found by the server
                if let userId = userId {
                    goToCharge(customerId: userId, connectId: userId)
                } else {
                    simpleAlert("Cannot test charge", message: "No userId found")
                }
            default:
                simpleAlert("Cannot test charges", message: "A stripe account must be connected first")
            }
        case .version:
            break
        case .logout:
            Globals.consoleLogger.logEvent("AuthService logout")
            userId = nil
            AuthService.shared.logout()
            connectService.stopListeningForAccount();
            reloadTable()
        }
    }
    
    func goToCharge(customerId: String, connectId: String) {
        let params: [String: Any] = ["amount": 100, "customerId": customerId, "connectId": connectId, "eventId": "456"]
        apiService.cloudFunction(functionName: "createStripeConnectCharge", method: "POST", params: params) { [weak self] (result, error) in
            print("CreateStripeConnectCharge: result: \(String(describing: result)) error: \(String(describing: error))")
            if let error = error as NSError? {
                self?.simpleAlert("Create charge error", defaultMessage: nil, error: error)
            } else {
                self?.simpleAlert("Create charge results", message: "\(String(describing: result))")
            }
        }
    }
}
