//
//  PaymentSourceProtocol.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/11/20.
//
//  Interface for Stripe's Cards and Sources


public protocol PaymentSource {
    var id: String { get } // stripeID is available on both STPCard and STPSource
    var label: String { get }
    var image: UIImage { get }
    var last4: String? { get }
    
    var needsRefresh: Bool { get } // true if STPCard. when we upgraded to stripeConnect, payment sources must be STPSource, not STPCard
}
