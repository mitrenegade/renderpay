//
//  LoggingProtocol.swift
//  RenderPay
//
//  Created by Bobby Ren on 4/5/20.
//

public protocol LoggingService {
    func logEvent(_ eventName: String)
    func logEvent(_ eventName: String, params: [String: Any]?)
}
