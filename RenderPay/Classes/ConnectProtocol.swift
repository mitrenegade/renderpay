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
//    let clientId: String { get }
    var redirectUrl: String? { get }// used for redirect
//    let apiService: CloudAPIService { get }
//    let baseRef: Reference { get }
    
    var accountState: BehaviorRelay<AccountState> { get }
    
    init(clientId: String, apiService: CloudAPIService, baseRef: Reference, logger: LoggingService?)
    func startListeningForAccount(userId: String)
    func getOAuthUrl(_ userId: String) -> String?
    func stopListeningForAccount()
}
