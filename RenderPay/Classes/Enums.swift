//
//  Enums.swift
//  Balizinha
//
//  Created by Bobby Ren on 2/24/19.
//

import Foundation
import Stripe

// MARK: - Payment enums
public enum PaymentStatus {
    case loading
    case noCustomer
    case noPaymentMethod // no customer_id exists
    case ready(source: STPSource)
    
    public static func ==(lhs: PaymentStatus, rhs: PaymentStatus) -> Bool {
        switch (lhs, rhs) {
        case (.noCustomer, .noCustomer):
            return true
        case (.noPaymentMethod, .noPaymentMethod):
            return true
        case (.loading, .loading):
            return true
        case (.ready(let s1), .ready(let s2)):
            return s1.stripeID == s2.stripeID
        default:
            return false
        }
    }
}

// MARK: - Connect enums
public enum AccountState: Equatable {
    case unknown
    case loading
    case account(String)
    case none
    
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .loading: return "loading..."
        case .account(let acct): return "Merchant account: \(acct)"
        case .none: return "none"
        }
    }
    
    public static func ==(lhs: AccountState, rhs: AccountState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.loading, .loading):
            return true
        case (.account(let p1), .account(let p2)):
            return p1 == p2
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}