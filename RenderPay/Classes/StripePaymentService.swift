//
//  StripePaymentService.swift
//  Pods-RenderPay_Example
//
//  Created by Bobby Ren on 12/25/18.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseDatabase
import Balizinha
import Stripe

enum PaymentStatus {
    case none // no customer_id exists
    case loading // customer_id exists, loading payment
    case ready(paymentMethod: STPPaymentMethod?)
    
    static func ==(lhs: PaymentStatus, rhs: PaymentStatus) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.loading, .loading):
            return true
        case (.ready(let p1), .ready(let p2)):
            if p1 == nil && p2 == nil {
                return true
            }
            if p1 != nil && p2 != nil {
                return true
            }
            return false
        default:
            return false
        }
    }
}

public class StripePaymentService: NSObject {
    fileprivate var customers: [String: String] = [:]
    
    // payment method
    var paymentContext: Variable<STPPaymentContext?> = Variable(nil)
    var customerId: Variable<String?> = Variable(nil)
    fileprivate var paymentContextLoading: Variable<Bool> = Variable(false) // when paymentContext loading state changes, we don't get a reactive notification
    let status: Observable<PaymentStatus>

    weak var hostController: UIViewController? {
        didSet {
            self.paymentContext.value?.hostViewController = hostController
        }
    }
    
    fileprivate var disposeBag: DisposeBag

    public var apiService: CloudAPIService?
    public init(apiService: CloudAPIService? = nil) {
        // for connect
        self.apiService = apiService
        // for payments
        STPPaymentConfiguration.shared().publishableKey = "pk_test_YYNWvzYJi3bTyOJi2SNK3IkE"

        // status: no customer_id = none
        // status: customer_id, no paymentContext = loading, should trigger creating payment context
        // status: customer_id, paymentContext.loading = loading
        // status: customer_id, !paymentContext.loading, paymentMethod is nil = Add a payment (none)
        // status: customer_id, !paymentContext.loading, paymentMethod exists = View payments (ready)
        disposeBag = DisposeBag()
        print("StripeService: starting observing to update status")
        self.status = Observable.combineLatest(paymentContext.asObservable(), customerId.asObservable(), paymentContextLoading.asObservable()) {context, customerId, loading in
            guard let customerId = customerId else {
                return .none
            }
            guard let context = context else {
                return .loading
            }
            if context.loading { // use actual loading value; paymentContextLoading is only used as a trigger
                // customer exists, context exists, loading payment method
                print("StripeService: status update: \(PaymentStatus.loading)")
                return .loading
            }
            else if let paymentMethod = context.selectedPaymentMethod {
                // customer exists, context exists, payment exists
                print("StripeService: status update: \(PaymentStatus.ready)")
                return .ready(paymentMethod: paymentMethod)
            } else {
                // customer exists, context exists, no payment method
                print("StripeService: status update: \(PaymentStatus.none)")
                return .none
            }
        }
        
        // TODO: when customer ID is set, create context
        getStripeCustomers(completion: nil)
        self.customerId.asObservable().filterNil().subscribe(onNext: { (customerId) in
            self.loadPayment()
        }).disposed(by: disposeBag)
    }

    func resetOnLogout() {
        print("StripeService: resetting on logout")
        disposeBag = DisposeBag()
        customerId.value = nil
        paymentContextLoading.value = false
        paymentContext.value = nil
        hostController = nil
    }
    
    func loadPayment() {
        guard let customerId = self.customerId.value else { return }
        guard self.paymentContext.value == nil else { return }
        
        print("StripeService: loadPayment for customer \(customerId)")
        let customerContext = STPCustomerContext(keyProvider: self)
        let paymentContext = STPPaymentContext(customerContext: customerContext)
        paymentContext.delegate = self
        if let hostController = self.hostController {
            paymentContext.hostViewController = hostController
        }
        self.paymentContext.value = paymentContext
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
            print("FirebaseAPIService: savePaymentInfo result \(result) error \(error)")
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
    
/* MARK: - Customers */
    public func getStripeCustomers(completion: ((_ results: [String: String]) -> Void)?) {
        let queryRef = Database.database().reference().child("stripe_customers")
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
