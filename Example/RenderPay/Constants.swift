//
//  Constants.swift
//  RenderPay_Example
//
//  Created by Bobby Ren on 12/25/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth
import RenderPay
import RenderCloud

let TESTING: Bool = true
let STRIPE_CLIENT_ID_DEV = "ca_ECowy0cLCEaImKunoIsUfm2n4EbhxrMO"
let STRIPE_CLIENT_ID_PROD = "ca_ECowdoBb2DfRFlBMQSZ2jT4SSXAUJ6Lx"

let STRIPE_PUBLISHABLE_KEY_DEV = "pk_test_YYNWvzYJi3bTyOJi2SNK3IkE"
let STRIPE_PUBLISHABLE_KEY_PROD = "pk_live_IziZ9EDk1374oI3rXjEciLBG"

let FIREBASE_URL_DEV = "https://us-central1-rollcall-and-random-dev.cloudfunctions.net"
let FIREBASE_URL_PROD = "https://us-central1-rollcall-and-random-drawing.cloudfunctions.net"

class Globals {
    static var apiService: CloudAPIService = FirebaseAPIService()
    static var stripeConnectService: StripeConnectService = StripeConnectService(clientId: TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD, apiService: Globals.apiService)
    static var stripePaymentService: StripePaymentService = StripePaymentService(apiService: Globals.apiService)
}
