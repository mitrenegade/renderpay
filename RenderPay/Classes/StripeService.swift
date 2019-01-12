//
//  StripeService.swift
//  Pods-RenderPay_Example
//
//  Created by Bobby Ren on 12/25/18.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseDatabase
import Balizinha

public enum AccountState: Equatable {
    case unknown
    case loading
    case account(String)
    case none
    
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .loading: return "loading..."
        case .account(let acct): return "account: \(acct)"
        case .none: return "none"
        }
    }
}

public class StripeService {
    fileprivate var customers: [String: String] = [:]

    public var clientId: String?
    public var baseUrl: String? // used for redirect
    public var apiService: CloudAPIService?

    public var accountState: BehaviorRelay<AccountState> = BehaviorRelay<AccountState>(value: .unknown)

    public init(clientId: String,  baseUrl: String, apiService: CloudAPIService? = nil) {
        // for connect
        self.clientId = clientId
        self.baseUrl = baseUrl
        self.apiService = apiService
        getStripeCustomers(completion: nil)
        
//        // for payments
//        STPPaymentConfiguration.shared().publishableKey = "pk_test_YYNWvzYJi3bTyOJi2SNK3IkE"
    }
    
    public func startListeningForAccount(userId: String) {
        accountState.accept(.loading)
        
        let ref = Database.database().reference().child("stripeAccounts").child(userId)
        ref.observe(.value) { [weak self] (snapshot) in
            guard snapshot.exists(), let info = snapshot.value as? [String: Any] else {
                self?.accountState.accept(.none)
                return
            }
            print("Account info: \(info)")
            if let stripeUserId = info["stripeUserId"] as? String {
                self?.accountState.accept(.account(stripeUserId))
            } else {
                self?.accountState.accept(.unknown)
            }
        }
    }

    public func getOAuthUrl(_ userId: String) -> String? {
        // to pass the userId through the redirect: https://stackoverflow.com/questions/32501820/associate-application-user-with-stripe-user-after-stripe-connect-oauth-callback
        guard let clientId = clientId else { return nil }
        var url: String = "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=\(clientId)&scope=read_write&state=\(userId)"
        if let baseUrl = baseUrl {
            url = "\(url)&redirect_uri=\(baseUrl)/stripeConnectRedirectHandler"
        }
        return url
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
