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

//let FIREBASE_URL_DEV = "https://us-central1-rollcall-and-random-dev.cloudfunctions.net"
//let FIREBASE_URL_PROD = "https://us-central1-rollcall-and-random-drawing.cloudfunctions.net"
let FIREBASE_URL_DEV = "https://us-central1-balizinha-dev.cloudfunctions.net"
let FIREBASE_URL_PROD = "https://us-central1-balizinha-c9cd7.cloudfunctions.net"

class Globals {
    static let firRef: DatabaseReference = Database.database().reference()
    static let firAuth: Auth = Auth.auth()
    static var apiService: CloudAPIService = RenderAPIService(baseUrl: TESTING ? FIREBASE_URL_DEV : FIREBASE_URL_PROD)
    static var consoleLogger: LoggingService = { return ConsoleLogger(tag: "RenderPayLogging") }()
    static var defaultLogger: LoggingService? = nil
    static var stripeConnectService: StripeConnectService = StripeConnectService(clientId: TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD, apiService: Globals.apiService, baseRef: firRef, logger: TESTING ? Globals.consoleLogger : Globals.defaultLogger)
    static var stripePaymentService: StripePaymentService = StripePaymentService(apiService: Globals.apiService)
}
