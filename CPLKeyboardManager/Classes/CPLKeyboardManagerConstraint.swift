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

    internal override func shouldProcess(givenKeyboardEvent event: KeyboardEventType, andKeyboardEventData keyboardData: KeyboardEventData) -> Bool {
        if !isTracking {
            return false
        }

        if keyboardData.isLocal {
            guard let _ = self.currentFirstResponder else {
                return false
            }
            return true
        } else {
            return true
        }
    }

    internal override func handleKeyboardEvent(ofType type: KeyboardEventType, withKeyboardData keyboardData: KeyboardEventData) {
        switch type {
        case .willShow:
            handleKeyboardShowEvent(withKeyboardData: keyboardData)
        case .willHide:
            handleKeyboardHideEvent(withKeyboardData: keyboardData)
        default:
            break
        }
    }

    private func handleKeyboardShowEvent(withKeyboardData keyboardData: KeyboardEventData) {

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

    private func handleKeyboardHideEvent(withKeyboardData keyboardData: KeyboardEventData) {
        bottomConstraint.constant = initialBottomConstraint
        performAnimation(withDuration: keyboardData.getDuration(usingDefaultValue: defaultAnimationDuration), andAnimationOptions: keyboardData.getDefaultAnimationOptions(), action: { [weak self] in
            self?.view.layoutIfNeeded()
            }, completion: nil)
    }
}
