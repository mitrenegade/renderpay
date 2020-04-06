//
//  LoggingProtocol.swift
//  RenderPay
//
//  Created by Bobby Ren on 4/5/20.
//

import UIKit

protocol LoggingService {
    func logEvent(_ eventName: String, params: [String: Any]?)
}

class ConsoleLogger: LoggingService {
    let tag: String
    init(tag: String) {
        self.tag = tag
    }

    func logEvent(_ eventName: String, params: [String : Any]?) {
        var string: String = "\(tag): \(eventName)"
        if let params = params {
            string = string + " -> \(params)"
        }
        print(string)
    }
}
