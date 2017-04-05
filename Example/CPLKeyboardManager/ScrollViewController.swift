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

   // @IBOutlet var textFieldsWithAccesoryView: [UITextField]!

    var keyboardManager: CPLKeyboardManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardManager = CPLKeyboardManager(scrollView: scrollView, inViewController: self)

//        let accView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
//        accView.backgroundColor = UIColor.red
//        for textFieldWithAccesoryView in textFieldsWithAccesoryView {
//            textFieldWithAccesoryView.inputAccessoryView = accView
//        }
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
