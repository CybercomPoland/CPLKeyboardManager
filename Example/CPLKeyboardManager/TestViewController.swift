//
//  TestViewController.swift
//  CPLKeyboardManager
//
//  Created by Michal Zietera on 03.04.2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func showPosition(_ sender: UIButton) {
        if let selectedRange = textView.selectedTextRange,
            let selectionRects = textView.selectionRects(for: selectedRange) as? [UITextSelectionRect] {

            if let lowestTextSelectionRect = selectionRects.reduce(selectionRects.first, { (firstRect, secondRect) -> UITextSelectionRect in
                return firstRect!.rect.origin.y > secondRect.rect.origin.y ? firstRect! : secondRect
            }) {
                let convertedLowestRect = view.convert(lowestTextSelectionRect.rect, from: textView)
                print(convertedLowestRect)
            }
        }
    }
}
