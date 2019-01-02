//
//  ViewController.swift
//  RenderPay
//
//  Created by bobbyren on 12/25/2018.
//  Copyright (c) 2018 bobbyren. All rights reserved.
//

import UIKit
import RenderPay
import RxSwift
import RxCocoa
import Balizinha

//
//  MenuViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

enum MenuItem: String {
    case stripe = "Stripe connect"
    case charge = "Test payment"
    case version = "Version"
    case login = "Login"
    case logout = "Logout"
}
fileprivate var loggedInMenu: [MenuItem] = [.stripe, .charge, .version, .logout]
fileprivate let loggedOutMenu: [MenuItem] = [.login]

class MenuViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    fileprivate var disposeBag = DisposeBag()
    var stripeService: StripeService?
    
    var menuItems: [MenuItem] = loggedOutMenu
    var userId: String? {
        didSet {
            if let userId = userId, oldValue == nil {
                let baseUrl = TESTING ? FIREBASE_URL_DEV : FIREBASE_URL_PROD
                stripeService = StripeService(clientId: userId, baseUrl: baseUrl)
                stripeService?.startListeningForAccount(userId: userId)
                
                stripeService?.accountState.skip(1).distinctUntilChanged().subscribe(onNext: { [weak self] state in
                    print("StripeService accountState changed: \(state)")
                    self?.reloadTable()
                }).disposed(by: disposeBag)

            }
        }
    }

    @IBOutlet weak var buttonConnect: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        navigationItem.title = "Balizinha Admin Menu"
        
        AuthService.shared.startup()
        AuthService.shared.loginState.skip(1).subscribe(onNext: { [weak self] state in
            if state == .loggedOut {
                self?.menuItems = loggedOutMenu
                self?.reloadTable()
                self?.promptForLogin()
            } else {
                self?.userId = AuthService.currentUser?.uid
                self?.menuItems = loggedInMenu
                self?.reloadTable()
            }
        }).disposed(by: disposeBag)
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
        AuthService.shared.loginUser(email: email, password: password) { [weak self] error in
            if let error = error {
                print("Error!")
                let alert = UIAlertController(title: "Login error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true)
            } else {
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
        guard let userId = userId, let urlString = stripeService?.getOAuthUrl(userId), let url = URL(string: urlString) else { return }
        UIApplication.shared.openURL(url)
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
            case .stripe:
                cell.textLabel?.text = stripeService?.accountState.value.description
            case .charge:
                cell.textLabel?.text = menuItems[indexPath.row].rawValue
                switch stripeService?.accountState.value ?? .none {
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
        case .stripe:
            connectToStripe()
        case .charge:
            switch stripeService?.accountState.value ?? .none {
            case .account:
                goToCharge()
            default:
                simpleAlert("Cannot test charges", message: "A stripe account must be connected first")
            }
        case .version:
            break
        case .logout:
            AuthService.shared.logout()
            reloadTable()
        }
    }
    
    func goToCharge() {
        // TODO: display a payment processor
    }
}
