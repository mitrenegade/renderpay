//
//  ConnectProtocol.swift
//  RenderPay
//
//  Created by Bobby Ren on 2/24/19.
//

import RenderCloud
import RxSwift
import RxCocoa

public protocol ConnectService {
    var accountState: BehaviorRelay<AccountState> { get }
    
    init(clientId: String, apiService: CloudAPIService & CloudDatabaseService, baseRef: Reference, logger: LoggingService?)
    func connectToAccount(_ userId: String)
    func startListeningForAccount(userId: String)
    func stopListeningForAccount()
}
