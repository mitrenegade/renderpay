//
//  StripeConnectService.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/12/19.
//

import UIKit
import RxSwift
import RxCocoa
import RenderCloud

public class StripeConnectService: ConnectService {

    let clientId: String
    let apiService: CloudAPIService
    let baseRef: Reference
    
    private let logger: LoggingService?
    private var accountRef: Reference?
    
    public let redirectUrl: String
    public var accountState: BehaviorRelay<AccountState> = BehaviorRelay<AccountState>(value: .unknown)
    
    required public init(clientId: String, apiService: CloudAPIService, baseRef: Reference, logger: LoggingService? = nil) {
        // for connect
        self.clientId = clientId
        self.apiService = apiService
        self.logger = logger
        self.baseRef = baseRef
        self.redirectUrl = "\(apiService.baseUrl.absoluteString)/stripeConnectRedirectHandler"
    }
    
    public func startListeningForAccount(userId: String) {
        accountState.accept(.loading)
        
        logger?.logEvent("Listening for account", params: ["userId": userId])
        
        accountRef = baseRef.child(path: "stripeConnectAccounts").child(path: userId)
        accountRef?.observeValue { [weak self] (snapshot) in
            guard snapshot.exists(), let info = snapshot.value as? [String: Any] else {
                self?.logger?.logEvent("Account state", params: ["state": "none"])
                self?.accountState.accept(.none)
                return
            }
            if let stripeUserId = info["stripeUserId"] as? String {
                self?.logger?.logEvent("Account state", params: ["stripeUserId": stripeUserId])
                self?.accountState.accept(.account(stripeUserId))
            } else {
                self?.logger?.logEvent("Account state", params: ["state": "invalid user id"])
                self?.accountState.accept(.unknown)
            }
        }
    }
    
    public func connectToAccount(_ userId: String) {
        guard let urlString = getOAuthUrl(userId), let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // on logout
    public func stopListeningForAccount() {
        logger?.logEvent("Stop listening for account")
        accountRef?.removeAllObservers()
        accountRef = nil
        accountState.accept(.none)
    }
}

// mark: - Internal functions
extension StripeConnectService {
    func getOAuthUrl(_ userId: String) -> String? {
        // to pass the userId through the redirect: https://stackoverflow.com/questions/32501820/associate-application-user-with-stripe-user-after-stripe-connect-oauth-callback
        let url: String = "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=\(clientId)&scope=read_write&state=\(userId)&redirect_uri=\(redirectUrl)"
        return url
    }
}
