//
//  AuthService.swift
//  RenderPay_Example
//
//  Created by Bobby Ren on 4/9/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import RxSwift
import RxCocoa
import FirebaseDatabase

let firRef: DatabaseReference = Database.database().reference()
let firAuth: Auth = Auth.auth()

public enum LoginState {
    case loggedOut
    case loggedIn
}

public class AuthService: NSObject {
    public static var shared: AuthService = AuthService()
    fileprivate var stateChangeHandler: AuthStateDidChangeListenerHandle?
    let defaultsProvider = UserDefaults.standard
    let auth = firAuth

    override public init() {
        super.init()
        
        stateChangeHandler = auth.addStateDidChangeListener({ [weak self] (state, user) in
            print("LoginLogout: auth state changed: \(state)")
            guard let self = self else { return }
            if let user = user, !user.isAnonymous {
                // already logged in, don't do anything
                print("FirAuth: user logged in")
                self.loginState.accept(.loggedIn)
            } else {
                print("Need to display login")
                self.loginState.accept(.loggedOut)
            }
        })
    }
    
    public var loginState: BehaviorRelay<LoginState> = BehaviorRelay<LoginState>(value: .loggedOut)

    public class var currentUser: User? {
        return firAuth.currentUser
    }

    public class var isAnonymous: Bool {
        guard let user = AuthService.currentUser else { return true }
        return user.isAnonymous
    }

    public func startup() {
        if defaultsProvider.value(forKey: "appFirstTimeOpened") == nil {
            //if app is first time opened, make sure no auth exists in keychain from previously deleted app
            defaultsProvider.setValue(true, forKey: "appFirstTimeOpened")
            // signOut from FIRAuth
            try! firAuth.signOut()
        }
    }

    public func loginUser(email: String, password: String, completion: ((Error?)->Void)?) {
        if email.isEmpty {
            print("Invalid email")
            return
        }
        
        if password.isEmpty {
            print("Invalid password")
            return
        }
        
        firAuth.signIn(withEmail: email, password: password, completion: { (user, error) in
            if let error: NSError = error as NSError? {
                print("Error: \(error)")
                // let observer handle things
                completion?(error)
            }
            else {
                print("LoginLogout: LoginSuccess from email, results: \(String(describing: user))")
                // let observer handle things
                completion?(nil)
            }
        })
    }
    
    public var hasFacebookProvider: Bool {
        guard let user = AuthService.currentUser else { return false }
        guard !user.providerData.isEmpty else { return false }
        for provider in user.providerData {
            if provider.providerID == "facebook.com" {
                return true
            }
        }
        return false
    }
    
    public func logout() {
        print("LoginLogout: logout called, trying firAuth.signout")
        try! firAuth.signOut()
    }
}
