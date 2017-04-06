//
//  CPLKeyboardManagerConstraint.swift
//  Pods
//
//  Created by Michal Zietera on 06.04.2017.
//
//

import Foundation

internal class CPLKeyboardManagerConstraint: CPLKeyboardManagerBase {

    private var initialBottomConstraint: CGFloat
    private var bottomConstraint: NSLayoutConstraint

    internal init(bottomConstraint: NSLayoutConstraint) {
        self.bottomConstraint = bottomConstraint
        self.initialBottomConstraint = bottomConstraint.constant
    }

    @objc override func keyboardWillShow(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }

        if shouldProceed(withKeyboardData: keyboardData) {
            if areShownKeyboardParametersCorrect(beginRect: keyboardData.beginKeyboardRect, endRect: keyboardData.endKeyboardRect) {

            }
        }
    }

    @objc override func keyboardDidShow(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }

        if shouldProceed(withKeyboardData: keyboardData) {
            if areShownKeyboardParametersCorrect(beginRect: keyboardData.beginKeyboardRect, endRect: keyboardData.endKeyboardRect) {

            }
        }
    }

    @objc override func keyboardWillHide(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }

        bottomConstraint.constant = initialBottomConstraint
    }

    private func shouldProceed(withKeyboardData keyboardData: KeyboardEventData) -> Bool {
        if keyboardData.isLocal {
            guard let currentFirstResponder = self.currentFirstResponder else {
                return false
            }
            return true
        } else {
            return true
        }
    }

    private func handleKeyboardShownEvent(withKeyboardData keyboardData: KeyboardEventData) {

        let currentConstraintConst = bottomConstraint.constant
        let endKbHeight = keyboardData.endKeyboardRect.height

        if currentConstraintConst >= keyboardData.endKeyboardRect.height {
            return
        }

        let diff = endKbHeight - currentConstraintConst

    }

}
