//
//  Protocols.swift
//  Balizinha
//
//  Created by Bobby Ren on 2/24/19.
//

import Foundation
import RxSwift
import RxCocoa
import RenderCloud
import Stripe

public protocol PaymentService {
    // payment method
    var storedPaymentSource: String? { get }
    
    // state observables
    var customerId: BehaviorRelay<String?> { get }
    var paymentSource: BehaviorRelay<STPPaymentMethod?> { get }
    var statusObserver: Observable<PaymentStatus> { get }
    
    init(apiService: CloudAPIService?)
    func resetOnLogout()
    func startListeningForAccount(userId: String)
    func loadPayment(hostController: UIViewController?)
    func checkForPayment(for eventId: String, by playerId: String, completion:@escaping ((Bool)->Void))
    func savePaymentInfo(userId: String, source: String, last4: String, label: String)
    func holdPayment(userId: String, eventId: String, completion: ((_ response: Any?, _ error: Error?) -> ())?)
    func capturePayment(userId: String, eventId: String, chargeId: String, params: [String: Any]?, completion: ((_ response: Any?, _ error: Error?) -> ())?)
    func makePayment(userId: String, eventId: String, completion: ((_ response: Any?, _ error: Error?) -> ())?)
    func refundPayment(eventId: String, chargeId: String, params: [String: Any]?, completion: ((_ response: Any?, _ error: Error?) -> ())?)
    func shouldShowPaymentController()
    
    // MARK: - customers
    func getStripeCustomers(completion: ((_ results: [String: String]) -> Void)?)
    func playerIdForCustomer(_ customerId: String) -> String?
    func createCustomer(userId: String, email: String, completion: ((String?, Error?)-> Void)?)
}
