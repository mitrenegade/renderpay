//
//  ConsoleLogger.swift
//  RenderPay_Example
//
//  Created by Bobby Ren on 4/5/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//
import RenderCloud

class ConsoleLogger: LoggingService {
    let tag: String
    init(tag: String) {
        self.tag = tag
    }

    func logEvent(_ eventName: String) {
        logEvent(eventName, params: nil)
    }

    func logEvent(_ eventName: String, params: [String : Any]?) {
        var string: String = "\(tag): \(eventName)"
        if let params = params {
            string = string + " -> \(params)"
        }
        print(string)
    }
}
