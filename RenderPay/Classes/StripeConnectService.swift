//
//  StripeConnectService.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/12/19.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseDatabase
import RenderCloud

public class StripeConnectService: ConnectService {
    public var clientId: String?
    public var redirectUrl: String? // used for redirect
    public var apiService: CloudAPIService?
    
    public var accountState: BehaviorRelay<AccountState> = BehaviorRelay<AccountState>(value: .unknown)
    
    required public init(clientId: String, apiService: CloudAPIService? = nil) {
        // for connect
        self.clientId = clientId
        self.apiService = apiService
    }
    
    public func startListeningForAccount(userId: String) {
        accountState.accept(.loading)
        
        let ref = Database.database().reference().child("stripeConnectAccounts").child(userId)
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
        if let baseUrl = FirebaseAPIService.baseURL?.absoluteString {
            url = "\(url)&redirect_uri=\(baseUrl)/stripeConnectRedirectHandler"
        }
        return url
    }
}
