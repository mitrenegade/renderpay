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


class Globals {
    static let firRef: DatabaseReference = Database.database().reference()
    static let firAuth: Auth = Auth.auth()
    static var apiService: CloudAPIService & CloudDatabaseService = RenderAPIService(baseUrl: TESTING ? FIREBASE_URL_DEV : FIREBASE_URL_PROD, baseRef: firRef)
    static var consoleLogger: LoggingService = { return ConsoleLogger(tag: "RenderPayLogging") }()
    static var defaultLogger: LoggingService? = nil
    static var stripeConnectService: StripeConnectService = StripeConnectService(clientId: TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD, apiService: Globals.apiService, baseRef: firRef, logger: TESTING ? Globals.consoleLogger : Globals.defaultLogger)
    static var stripePaymentService: StripePaymentService = StripePaymentService(apiService: Globals.apiService)
}
