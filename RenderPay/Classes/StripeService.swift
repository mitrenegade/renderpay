//
//  StripeService.swift
//  Pods-RenderPay_Example
//
//  Created by Bobby Ren on 12/25/18.
//

import UIKit

let CLIENT_ID_DEV = "ca_ECowy0cLCEaImKunoIsUfm2n4EbhxrMO"
let CLIENT_ID_PROD = "ca_ECowdoBb2DfRFlBMQSZ2jT4SSXAUJ6Lx"

let TESTING = true
public class StripeService: NSObject {
    public func oauth_url(_ userId: String) -> String {
        let client_id = TESTING ? CLIENT_ID_DEV : CLIENT_ID_PROD
        // to pass the userId through the redirect: https://stackoverflow.com/questions/32501820/associate-application-user-with-stripe-user-after-stripe-connect-oauth-callback
        return "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=\(client_id)&scope=read_write&state=\(userId)"
    }
}
