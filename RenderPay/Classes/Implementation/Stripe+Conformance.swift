//
//  Stripe+Conformance.swift
//  PannaPay
//
//  Created by Bobby Ren on 4/11/20.
//
//  Dependency inversion conformance for STPCard and STPSource to RenderPay.PaymentSource

import Stripe
import RenderPay

extension STPCard: PaymentSource {
    public var id: String {
        return stripeID
    }
    
     // true for STPCard. when we upgraded to stripeConnect, payment sources must be STPSource, not STPCard
    public var needsRefresh: Bool {
        return true
    }
    
    public var last4: String? {
        return dynamicLast4
    }
}

extension STPSource: PaymentSource {
    public var id: String {
        return stripeID
    }
    
    public var last4: String? {
        return cardDetails?.last4
    }
    
    public var needsRefresh: Bool {
        return false
    }
}
