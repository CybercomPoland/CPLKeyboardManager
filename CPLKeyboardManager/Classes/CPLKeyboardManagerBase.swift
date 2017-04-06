//
//  CPLKeyboardManagerBase.swift
//  Pods
//
//  Created by Michal Zietera on 06.04.2017.
//
//

import Foundation

internal class CPLKeyboardManagerBase {
    internal let notificationCenter = NotificationCenter.default

    internal var keyboardState: KeyboardState = .Hidden
    internal var isTracking: Bool = false
    internal var currentFirstResponder: UIView? = nil

    init() {
        registerForNotifications()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    private func registerForNotifications() {
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidShow), name: .UIKeyboardDidShow, object: nil)
        //notificationCenter.addObserver(self, selector: #selector(keyboardDidChange), name: .UIKeyboardDidChangeFrame, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)

        notificationCenter.addObserver(self, selector: #selector(didBeginEditing), name: .UITextViewTextDidBeginEditing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(didEndEditing), name: .UITextViewTextDidEndEditing, object: nil)

        notificationCenter.addObserver(self, selector: #selector(didBeginEditing), name: .UITextFieldTextDidBeginEditing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(didEndEditing), name: .UITextFieldTextDidEndEditing, object: nil)
    }

    @objc internal func keyboardWillShow(notification: Notification) {
        print("\(#function) Should be implemented in child class")
    }

    @objc internal func keyboardDidShow(notification: Notification) {
        fatalError("\(#function) Should be implemented in child class")
    }

    @objc internal func keyboardWillHide(notification: Notification) {
        fatalError("\(#function) Should be implemented in child class")
    }

    @objc internal func didBeginEditing(notification: Notification) {
        currentFirstResponder = notification.object as? UIView
    }

    @objc internal func didEndEditing(notification: Notification) {
        currentFirstResponder = nil
    }

    internal func areShownKeyboardParametersCorrect(beginRect: CGRect, endRect: CGRect) -> Bool {
        let isKeyboardHidden = isKeyboardBeingHidden(beginRect: beginRect, endRect: endRect)
        let isKeyboardSizeSame = isKeyboardFrameSame(beginRect: beginRect, endRect: endRect)
        let isKeyboardEndSizeCorrect = isKeyboardEndFrameCorrect(endRect: endRect)

        return !isKeyboardHidden && !isKeyboardSizeSame && isKeyboardEndSizeCorrect
    }

    internal func isKeyboardBeingHidden(beginRect: CGRect, endRect: CGRect) -> Bool {
        return beginRect.origin.y + beginRect.height == endRect.origin.y
    }

    internal func isKeyboardFrameSame(beginRect: CGRect, endRect: CGRect) -> Bool {
        return beginRect.equalTo(endRect)
    }

    internal func isKeyboardEndFrameCorrect(endRect: CGRect) -> Bool { //somtimes endKB == 0 for some reason for 3rd party keyboards
        return endRect.height > 0
    }

    internal func performAnimation(withDuration duration: Double, andAnimationOptions animationOptions: UIViewAnimationOptions, action: @escaping (()->Void), completion: (()->Void)?) {
        UIView.animate(withDuration: duration, delay: 0.0, options: animationOptions, animations: { 
            action()
        }) { (finished) in
            completion?()
        }
    }

    internal func start() {
        isTracking = true
    }

    internal func stop() {
        isTracking = false
    }

    internal func unregisterFromNotifications() {
        notificationCenter.removeObserver(self)
    }

    internal enum KeyboardEventType {
        case WillShow
        case DidShow
        case WillChange
        case DidChange
    }

    internal enum KeyboardState {
        case Shown
        case Hidden
    }

    internal struct KeyboardEventData {
        let isLocal: Bool
        let animationCurve: NSNumber
        let duration: NSNumber
        let beginKeyboardRect: CGRect
        let endKeyboardRect: CGRect

        init?(notification: Notification) {
            guard let userInfo = notification.userInfo,
                let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
                let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
                let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
                let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
                else {
                    return nil
            }

            if #available(iOS 9.0, *) {
                if let isLocal = userInfo[UIKeyboardIsLocalUserInfoKey] as? Bool {
                    self.isLocal = isLocal
                } else {
                    isLocal = true
                }
            } else {
                isLocal = true
            }

            self.animationCurve = animationCurve
            self.beginKeyboardRect = beginKeyboardRect
            self.endKeyboardRect = endKeyboardRect
            self.duration = duration
        }

        func getDefaultAnimationOptions() -> UIViewAnimationOptions {
            let animationOptions: UIViewAnimationOptions = [UIViewAnimationOptions(rawValue: animationCurve.uintValue << 16), .beginFromCurrentState, .allowUserInteraction]
            return animationOptions
        }

        func getDuration(usingDefaultValue defVal: Double) -> Double {
            if duration == 0.0 {
                return defVal
            } else {
                return duration.doubleValue
            }
        }
    }
}
