//
//  Enums.swift
//  Balizinha
//
//  Created by Bobby Ren on 2/24/19.
//

// MARK: - Payment enums
public enum PaymentStatus {
    case loading
    case noCustomer
    case noPaymentMethod // no customer_id exists
    case needsRefresh(card: PaymentSource)
    case ready(source: PaymentSource)
    
    public static func ==(lhs: PaymentStatus, rhs: PaymentStatus) -> Bool {
        switch (lhs, rhs) {
        case (.noCustomer, .noCustomer):
            return true
        case (.noPaymentMethod, .noPaymentMethod):
            return true
        case (.loading, .loading):
            return true
        case (.needsRefresh(let c1), .needsRefresh(let c2)):
            return c1.id == c2.id
        case (.ready(let s1), .ready(let s2)):
            return s1.id == s2.id
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
