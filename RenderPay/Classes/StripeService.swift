//
//  StripeService.swift
//  Pods-RenderPay_Example
//
//  Created by Bobby Ren on 12/25/18.
//

import UIKit

public class StripeService {
    private let clientId: String

    public init(clientId: String) {
        self.clientId = clientId
    }
    public func oauth_url(_ userId: String) -> String {
        // to pass the userId through the redirect: https://stackoverflow.com/questions/32501820/associate-application-user-with-stripe-user-after-stripe-connect-oauth-callback
        return "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=\(clientId)&scope=read_write&state=\(userId)"
    }
}
