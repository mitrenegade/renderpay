//
//  EventsViewController.swift
//  RenderPay_Example
//
//  Created by Bobby Ren on 4/3/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import RenderPay
import RxSwift
import RxCocoa

class EventsViewController: UIViewController {
    @IBOutlet weak var label: UILabel!

    var paymentStatus: PaymentStatus = .loading

    fileprivate var disposeBag = DisposeBag()

    var userId: String? {
        didSet {
            if let _ = userId, oldValue == nil {
                startListeningForAccount()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        print("Events: starting auth listener")
        AuthService.shared.loginState.subscribe(onNext: { [weak self] state in
            if state == .loggedOut {
                print("Events: auth logged out")
                self?.label.text = "Not logged in"
            } else {
                print("Events: auth logged in")
                self?.label.text = "Logged in"
                self?.userId = AuthService.currentUser?.uid
            }
        }).disposed(by: disposeBag)
    }
    
    func startListeningForAccount() {
        guard let userId = userId else { return }
        print("Events: starting paymentService listener")
        Globals.stripePaymentService.startListeningForAccount(userId: userId)
        Globals.stripePaymentService.statusObserver
            .asObservable()
            .distinctUntilChanged( {$0 == $1} )
            .subscribe(onNext: refresh)
            .disposed(by: disposeBag)
    }
    
    lazy var refresh: (PaymentStatus)->() = { [weak self] (status) in
        self?.paymentStatus = status
        switch status {
        case .loading:
            print("Events: paymentStatus loading")
            if let self = self {
                Globals.stripePaymentService.loadPayment(hostController: self)
                self.label.text = "Loading payment source..."
            }
        case .ready(let source):
            print("Events: paymentStatus ready")
            if let last4 = source.last4 {
                self?.label.text = "updated source \(source.id) last4 \(last4)) label \(source.label)"
            }
        default:
            break
        }
    }
}
