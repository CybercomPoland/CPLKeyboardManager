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

    internal init(bottomConstraint: NSLayoutConstraint, inViewController viewController: UIViewController) {
        self.bottomConstraint = bottomConstraint
        self.initialBottomConstraint = bottomConstraint.constant
        super.init(view: viewController.view)
    }

    override func keyboardWillShow(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }

        if shouldProceed(withKeyboardData: keyboardData) {
            if areShownKeyboardParametersCorrect(beginRect: keyboardData.beginKeyboardRect, endRect: keyboardData.endKeyboardRect) {
                //keyboardEventHandlers[.WillShow]?(keyboardData)
                handleKeyboardShownEvent(withKeyboardData: keyboardData)
            }
        }
    }

    override func keyboardDidShow(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }

        if shouldProceed(withKeyboardData: keyboardData) {
            if areShownKeyboardParametersCorrect(beginRect: keyboardData.beginKeyboardRect, endRect: keyboardData.endKeyboardRect) {
                //keyboardEventHandlers[.DidShow]?(keyboardData)
            }
        }
    }

    override func keyboardWillChange(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }

        if shouldProceed(withKeyboardData: keyboardData) {
            if areShownKeyboardParametersCorrect(beginRect: keyboardData.beginKeyboardRect, endRect: keyboardData.endKeyboardRect) {
                //keyboardEventHandlers[.WillChange]?(keyboardData)
            }
        }
    }
    
    override func keyboardDidChange(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }

        if shouldProceed(withKeyboardData: keyboardData) {
            if areShownKeyboardParametersCorrect(beginRect: keyboardData.beginKeyboardRect, endRect: keyboardData.endKeyboardRect) {
                //keyboardEventHandlers[.DidChange]?(keyboardData)
            }
        }
    }

    override func keyboardWillHide(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification), isTracking else {
            return
        }

        //keyboardEventHandlers[.WillHide]?(keyboardData)
        bottomConstraint.constant = initialBottomConstraint
        performAnimation(withDuration: keyboardData.getDuration(usingDefaultValue: defaultAnimationDuration), andAnimationOptions: keyboardData.getDefaultAnimationOptions(), action: { [weak self] in
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }

    override func keyboardDidHide(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification), isTracking else {
            return
        }

        //keyboardEventHandlers[.DidHide]?(keyboardData)
    }

    private func shouldProceed(withKeyboardData keyboardData: KeyboardEventData) -> Bool {
        if !isTracking {
            return false
        }

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
        currentKeyboardHeight = endKbHeight

        if currentConstraintConst >= keyboardData.endKeyboardRect.height {
            return
        }

        let diff = endKbHeight - currentConstraintConst

        bottomConstraint.constant += diff
        performAnimation(withDuration: keyboardData.getDuration(usingDefaultValue: defaultAnimationDuration), andAnimationOptions: keyboardData.getDefaultAnimationOptions(), action: { [weak self] in
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }

}
