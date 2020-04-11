//
//  UIViewController+Utils.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/8/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import Foundation
import UIKit

fileprivate let LOADING_VIEW_TAG = 25341
fileprivate let LOADING_INDICATOR_TAG = 25342
public extension UIViewController {
    func showLoadingIndicator() {
        var frame = self.view.frame
        frame.origin.y = 0
        let view = UIView(frame: frame)
        view.tag = LOADING_VIEW_TAG
        view.backgroundColor = .black
        view.alpha = 0.5
        
        self.view.addSubview(view)
        
        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        activityIndicator.tag = LOADING_INDICATOR_TAG
        self.view.addSubview(activityIndicator)
    }
    
    func hideLoadingIndicator() {
        for view in self.view.subviews {
            if view.tag == LOADING_VIEW_TAG || view.tag == LOADING_INDICATOR_TAG {
                view.removeFromSuperview()
            }
        }
    }
}

public extension UIViewController {
    
    func simpleAlert(_ title: String, defaultMessage: String?, error: NSError?) {
        if let error = error {
            if let msg = error.userInfo["error"] as? String {
                self.simpleAlert(title, message: msg)
                return
            }
        }
        self.simpleAlert(title, message: defaultMessage ?? error?.localizedDescription)
    }
    
    func simpleAlert(_ title: String, message: String?) {
        self.simpleAlert(title, message: message, completion: nil)
    }
    
    func simpleAlert(_ title: String, message: String?, completion: (() -> Void)?) {
        let alert: UIAlertController = UIAlertController.simpleAlert(title, message: message, completion: completion)
        self.present(alert, animated: true, completion: nil)
    }
}

public extension UIAlertController {
    class func simpleAlert(_ title: String, message: String?, completion: (() -> Void)?) -> UIAlertController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.view.tintColor = UIColor.black
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: { (action) -> Void in
            print("cancel")
            if completion != nil {
                completion!()
            }
        }))
        return alert
    }
}
