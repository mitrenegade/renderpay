//
//  ViewController.swift
//  RenderPay
//
//  Created by bobbyren on 12/25/2018.
//  Copyright (c) 2018 bobbyren. All rights reserved.
//

import UIKit
import RenderPay

class ViewController: UIViewController {
    let service = StripeService()

    @IBOutlet weak var buttonConnect: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didClickConnect() {
        let urlString = service.oauth_url
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.openURL(url)
    }
}

