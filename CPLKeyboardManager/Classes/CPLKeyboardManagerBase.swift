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
    internal var currentKeyboardHeight: CGFloat = 0.0
    internal var view: UIView

    typealias KeyboardEventHandler = ((KeyboardEventData) -> Void)
    internal var keyboardEventHandlers = [EventHandlerType : (action: KeyboardEventHandler, shouldOverride: Bool)]()

    public var spaceBetweenEditableAndKeyboardTop: CGFloat = 15.0
    public var shouldPreserveContentInset = true
    public var defaultAnimationDuration: Double = 0.25 //used when duration is not provided in userInfo

    init(view: UIView) {
        self.view = view
        registerForNotifications()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    private func registerForNotifications() {
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidShow), name: .UIKeyboardDidShow, object: nil)

        notificationCenter.addObserver(self, selector: #selector(keyboardWillChange), name: .UIKeyboardWillChangeFrame, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidChange), name: .UIKeyboardDidChangeFrame, object: nil)

        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidHide), name: .UIKeyboardDidHide, object: nil)

        notificationCenter.addObserver(self, selector: #selector(didBeginEditing), name: .UITextViewTextDidBeginEditing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(didEndEditing), name: .UITextViewTextDidEndEditing, object: nil)

        notificationCenter.addObserver(self, selector: #selector(didBeginEditing), name: .UITextFieldTextDidBeginEditing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(didEndEditing), name: .UITextFieldTextDidEndEditing, object: nil)
    }

    @objc public func keyboardWillShow(notification: Notification) {

    }

    @objc internal func keyboardDidShow(notification: Notification) {

    }

    @objc internal func keyboardWillChange(notification: Notification) {

    }

    @objc internal func keyboardDidChange(notification: Notification) {

    }

    @objc internal func keyboardWillHide(notification: Notification) {

    }

    @objc internal func keyboardDidHide(notification: Notification) {

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
        if endRect.height == currentKeyboardHeight {
            return beginRect.equalTo(endRect)
        } else {
            return false
        }
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

    //internal func assignHandler(ofType type: KeyboardHandlerType, )

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
}

public enum EventHandlerType: String {
    case WillShow = "WillShow"
    case DidShow = "DidShow"

    case WillChange = "WillChange"
    case DidChange = "DidChange"

    case WillHide = "WillHide"
    case DidHide = "DidHide"
}
