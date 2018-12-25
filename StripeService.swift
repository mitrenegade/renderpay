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
class StripeService: NSObject {
    var oauth_url: String {
        let client_id = TESTING ? CLIENT_ID_DEV : CLIENT_ID_PROD
        return "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=\(client_id)&scope=read_write"
    }
}
