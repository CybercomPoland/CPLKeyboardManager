//
//  ConstraintViewController.swift
//  CPLKeyboardManager
//
//  Created by Michal Zietera on 07.04.2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CPLKeyboardManager

class ConstraintViewController: UIViewController {

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!

    private var keyboardManager: CPLKeyboardManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.keyboardDismissMode = .interactive
        keyboardManager = CPLKeyboardManager(bottomConstraint: bottomConstraint, inViewController: self)
        keyboardManager?.setHandler(ofType: .WillShow, action: { [unowned self] (keyboardData) in
            let newContentOffset = CGPoint(x: self.scrollView.contentOffset.x, y: self.scrollView.contentOffset.y + keyboardData.endKeyboardRect.height)
            UIView.animate(withDuration: keyboardData.duration.doubleValue, animations: {
                self.scrollView.setContentOffset(newContentOffset, animated: false)
            })
        }, shouldOverride: false)
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
