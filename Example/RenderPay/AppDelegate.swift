//
//  AppDelegate.swift
//  RenderPay
//
//  Created by bobbyren on 12/25/2018.
//  Copyright (c) 2018 bobbyren. All rights reserved.
//

import UIKit
import Firebase
import Stripe

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Firebase
        // Do not include infolist in project: https://firebase.google.com/docs/configure/#reliable-analytics
        let plistFilename = "GoogleService-Info\(TESTING ? "-dev" : "")"
        let filePath = Bundle.main.path(forResource: plistFilename, ofType: "plist")
        assert(filePath != nil, "File doesn't exist")
        if let path = filePath, let fileopts = FirebaseOptions.init(contentsOfFile: path) {
            FirebaseApp.configure(options: fileopts)
        }

        // stripe
        // for payments
        let config = STPPaymentConfiguration.shared()
        config.publishableKey = TESTING ? STRIPE_PUBLISHABLE_KEY_DEV : STRIPE_PUBLISHABLE_KEY_PROD

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), components.scheme == "rollcall" {
            let pathComponents = components.path.components(separatedBy: "/")
            print("url: \(url)\ncomponents: \(components)\npath: \(pathComponents)")
        }
        return false
    }

}

