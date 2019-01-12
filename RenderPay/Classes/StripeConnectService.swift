//
//  StripeConnectService.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/12/19.
//

import UIKit
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

public class StripeConnectService {
    public var clientId: String?
    public var baseUrl: String? // used for redirect
    public var apiService: CloudAPIService?
    
    public var accountState: BehaviorRelay<AccountState> = BehaviorRelay<AccountState>(value: .unknown)
    
    public init(clientId: String,  baseUrl: String, apiService: CloudAPIService? = nil) {
        // for connect
        self.clientId = clientId
        self.baseUrl = baseUrl
        self.apiService = apiService        
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
}
