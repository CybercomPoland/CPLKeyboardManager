//
//  ScrollViewController.swift
//  CPLKeyboardManager
//
//  Created by Michal Zietera on 20.03.2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CPLKeyboardManager

class ScrollViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!

    var keyboardManager: CPLKeyboardManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardManager = CPLKeyboardManager(scrollView: scrollView, inViewController: self)
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardManager?.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager?.stop()
    }
}
