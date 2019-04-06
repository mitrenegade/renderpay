//
//  StripePaymentService.swift
//  Pods-RenderPay_Example
//
//  Created by Bobby Ren on 12/25/18.
//

import UIKit
import RxSwift
import RxCocoa
import RxOptional
import FirebaseDatabase
import Stripe
import RenderCloud

public class StripePaymentService: NSObject, PaymentService {
    fileprivate var customers: [String: String] = [:]
    fileprivate var userId: String?
    
    // payment method
    var paymentContext: STPPaymentContext? // from stripe library
    private var _storedPaymentSource: String? // from firebase
    public var storedPaymentSource: String? { return _storedPaymentSource }
    
    // state observables
    public let customerId: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    public let paymentSource: BehaviorRelay<STPPaymentMethod?> = BehaviorRelay<STPPaymentMethod?>(value: nil)
    fileprivate let paymentContextLoading: Variable<Bool> = Variable(false) // when paymentContext loading state changes, we don't get a reactive notification
    public let statusObserver: Observable<PaymentStatus>
    
    // customers
    public let customersDidLoad: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    fileprivate var disposeBag: DisposeBag
    
    public var apiService: CloudAPIService?
    required public init(apiService: CloudAPIService? = nil) {
        // for connect
        self.apiService = apiService
        // for payments
        let config = STPPaymentConfiguration.shared()
        config.createCardSources = true;
        
        // status: no customer_id = none
        // status: customer_id, no paymentContext = loading, should trigger creating payment context
        // status: customer_id, paymentContext.loading = loading
        // status: customer_id, !paymentContext.loading, paymentMethod is nil = Add a payment (none)
        // status: customer_id, !paymentContext.loading, paymentMethod exists = View payments (ready)
        disposeBag = DisposeBag()
        print("StripeService: starting observing to update status")
        statusObserver = Observable.combineLatest(paymentSource.asObservable(), customerId.asObservable(), paymentContextLoading.asObservable()) { source, customerId, loading in
            switch (customerId, loading, source) {
            case (nil, _, _):
                print("StripeService: status update: \(PaymentStatus.noCustomer)")
                return .noCustomer
            case (_, true, _):
                print("StripeService: status update: \(PaymentStatus.loading)")
                return .loading
            case (_, false, let source):
                // customer exists payment source exists
                if let source = source as? STPSource {
                    print("StripeService: status update: \(PaymentStatus.ready)")
                    return .ready(source: source)
                } else if let card = source as? STPCard {
                    print("StripeService: status update: \(PaymentStatus.needsRefresh)")
                    return .needsRefresh(card: card)
                } else {
                    print("StripeService: status update: \(PaymentStatus.noPaymentMethod)")
                    return .noPaymentMethod
                }
            }
        }
        super.init()
        getStripeCustomers(completion: nil)
    }
    
    public func resetOnLogout() {
        print("StripeService: resetting on logout")
        disposeBag = DisposeBag()
        customerId.accept(nil)
        _storedPaymentSource = nil
        paymentContextLoading.value = false
        paymentContext = nil
    }
    
    public func startListeningForAccount(userId: String) {
        paymentContextLoading.value = true
        self.userId = userId
        let firRef = Database.database().reference()
        let ref = firRef.child("stripeCustomers").child(userId)
        ref.observe(.value, with: { [weak self] (snapshot) in
            guard snapshot.exists(),
                let dict = snapshot.value as? [String: Any],
                let customerId = dict["customer_id"] as? String else {
                    print("Error no customer loaded")
                    self?.customerId.accept(nil)
                    self?._storedPaymentSource = nil
                    return
            }
            self?.customerId.accept(customerId)
            self?._storedPaymentSource = dict["source"] as? String
        })
    }
    
    public func loadPayment(hostController: UIViewController?) {
        guard let customerId = self.customerId.value else {
            return
        }
        print("StripeService: loadPayment for customer \(customerId)")
        let customerContext = STPCustomerContext(keyProvider: self)
        let paymentContext = STPPaymentContext(customerContext: customerContext)
        paymentContext.delegate = self
        if let hostController = hostController {
            paymentContext.hostViewController = hostController
        }
        self.paymentContext = paymentContext
    }
    
    /* MARK: - Payments */
    public func checkForPayment(for eventId: String, by playerId: String, completion:@escaping ((Bool)->Void)) {
        let ref = Database.database().reference().child("charges/events/\(eventId)")
        print("checking for payment on \(ref)")
        ref.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            guard snapshot.exists(), let payments = snapshot.value as? [String: [String: Any]] else {
                completion(false)
                return
            }
            for (_, info) in payments {
                if let player_id = info["player_id"] as? String, playerId == player_id, let status = info["status"] as? String, status == "succeeded", let refund = info["refunded"] as? Double, refund == 0 {
                    completion(true)
                    return
                }
            }
            completion(false)
        }
    }
    
    public func savePaymentInfo(userId: String, source: String, last4: String, label: String) {
        let params: [String: Any] = ["userId": userId, "source": source, "last4": last4, "label": label]
        apiService?.cloudFunction(functionName: "savePaymentInfo", method: "POST", params: params) { (result, error) in
            print("CloudAPIService: savePaymentInfo result \(String(describing: result)) error \(String(describing: error))")
        }
    }
    
    public func holdPayment(userId: String, eventId: String, completion: ((_ response: Any?, _ error: Error?) -> ())?) {
        let params = ["userId": userId, "eventId": eventId]
        apiService?.cloudFunction(functionName: "holdPayment", method: "POST", params: params) { (results, error) in
            completion?(results, error)
        }
    }
    
    public func capturePayment(userId: String, eventId: String, chargeId: String, params: [String: Any]? = nil, completion: ((_ response: Any?, _ error: Error?) -> ())?) {
        var info: [String: Any]?
        if let params = params {
            // this allows any params sent in for admin purposes to be included
            info = params
            info?["userId"] = userId
            info?["chargeId"] = chargeId
            info?["eventId"] = eventId
        } else {
            info = ["userId": userId, "eventId": eventId, "chargeId": chargeId]
        }
        apiService?.cloudFunction(functionName: "capturePayment", method: "POST", params: info) { (results, error) in
            completion?(results, error)
        }
    }
    
    public func makePayment(userId: String, eventId: String, completion: ((_ response: Any?, _ error: Error?) -> ())?) {
        let params = ["userId": userId, "eventId": eventId]
        apiService?.cloudFunction(functionName: "makePayment", method: "POST", params: params) { (results, error) in
            completion?(results, error)
        }
    }
    
    public func refundPayment(eventId: String, chargeId: String, params: [String: Any]? = nil, completion: ((_ response: Any?, _ error: Error?) -> ())?) {
        var info: [String: Any]?
        if let params = params {
            // this allows any params sent in for admin purposes to be included
            info = params
            info?["chargeId"] = chargeId
            info?["eventId"] = eventId
        } else {
            info = ["chargeId": chargeId, "eventId": eventId]
        }
        apiService?.cloudFunction(functionName: "refundCharge", method: "POST", params: info) { (results, error) in
            completion?(results, error)
        }
    }
    
    public func shouldShowPaymentController() {
        if let context = paymentContext.value {
            context.presentPaymentMethodsViewController()
        }
    }
    /* MARK: - Customers */
    public func getStripeCustomers(completion: ((_ results: [String: String]) -> Void)?) {
        // TODO: Balizinha must use stripe_customers until fully migrated
        let queryRef = Database.database().reference().child("stripeCustomers")
        queryRef.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard snapshot.exists() else {
                return
            }
            guard let self = self else { return }
            self.customers.removeAll()
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for dict: DataSnapshot in allObjects {
                    guard dict.exists() else { continue }
                    let playerId = dict.key
                    if let value = dict.value as? [String: String], let customerId = value["customer_id"] {
                        self.customers[playerId] = customerId
                    }
                }
            }
            self.customersDidLoad.accept(true)
            completion?(self.customers)
        }
    }
    
    public func playerIdForCustomer(_ customerId: String) -> String? {
        let result = customers.filter { (key, val) -> Bool in
            return val == customerId
        }
        if let playerId = result.first?.key {
            return playerId
        } else {
            return nil
        }
    }
    
    public func createCustomer(userId: String, email: String, completion: ((String?, Error?)-> Void)?) {
        let params: [String: Any] = ["userId": userId, "email": email]
        apiService?.cloudFunction(functionName: "validateStripeCustomer", method: "POST", params: params) { [weak self] (result, error) in
            print("CloudAPIService: createCustomer result \(String(describing: result)) error \(String(describing: error))")
            if let dict = result as? [String: Any], let customerId = dict["customer_id"] as? String {
                self?.customerId.accept(customerId)
                completion?(customerId, error)
            } else {
                completion?(nil, error)
            }
        }
    }
}

// MARK: - STPPaymentContextDelegate
extension StripePaymentService: STPPaymentContextDelegate {
    public func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print("StripeService: paymentContextDidChange. loading \(paymentContext.loading), selected payment \(String(describing: paymentContext.selectedPaymentMethod))")
        
        if let source = paymentContext.selectedPaymentMethod as? STPSource {
            paymentSource.accept(source)
        }
        // loading must be set after source is at the right value because loading is higher priority in determing status
        paymentContextLoading.value = paymentContext.loading
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        print("StripeService: paymentContext didFailToLoad error \(error)")
        // Show the error to your user, etc.
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        print("StripeService: paymentContext didCreatePayment with result \(paymentResult)")
        
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        print("StripeService: paymentContext didFinish")
        switch status {
        case .error: break
        //            self.showError(error)
        case .success: break
        //            self.showReceipt()
        case .userCancellation:
            return // Do nothing
        }
    }
}

// MARK: - Ephemeral keys
extension StripePaymentService: STPEphemeralKeyProvider {
    public func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        guard let customerId = self.customerId.value else { return }
        let params: [String: Any] = ["api_version": apiVersion, "customer_id": customerId]
        let method = "POST"
        apiService?.cloudFunction(functionName: "ephemeralKeys", method: method, params: params) { (result, error) in
            completion(result as? [AnyHashable: Any], error)
        }
    }
}
