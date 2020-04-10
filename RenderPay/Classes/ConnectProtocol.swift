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
    var accountState: BehaviorRelay<AccountState> { get }
    
    init(clientId: String, apiService: CloudAPIService, baseRef: Reference, logger: LoggingService?)
    func connectToAccount(_ userId: String)
    func startListeningForAccount(userId: String)
    func stopListeningForAccount()
}
