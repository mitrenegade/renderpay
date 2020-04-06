//
//  ConnectProtocol.swift
//  RenderPay
//
//  Created by Bobby Ren on 2/24/19.
//

import Foundation
import RxSwift
import RxCocoa
import RenderCloud

public protocol ConnectService {
    var clientId: String? { get }
    var redirectUrl: String? { get }// used for redirect
    var apiService: CloudAPIService? { get }
    
    var accountState: BehaviorRelay<AccountState> { get }
    
    init(clientId: String, apiService: CloudAPIService?, logger: LoggingService?)
    func startListeningForAccount(userId: String)
    func getOAuthUrl(_ userId: String) -> String?
}
