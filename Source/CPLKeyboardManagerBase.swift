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
    internal var keyboardState: KeyboardState = .hidden
    internal var isTracking: Bool = false
    internal var currentFirstResponder: UIView? = nil
    internal var currentKeyboardHeight: CGFloat = 0.0
    internal var view: UIView

    typealias KeyboardEventHandler = ((KeyboardEventData, UIView?) -> Void)
    internal var keyboardEventHandlers = [KeyboardEventType : (action: KeyboardEventHandler, shouldOverride: Bool)]()

    public var spaceBelowAndAboveEditable: CGFloat = 15.0
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
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }
        checkIfCustomHandlerExistsAndProceed(forEventType: .willShow, keyboardData: keyboardData)
    }

    @objc internal func keyboardDidShow(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }
        checkIfCustomHandlerExistsAndProceed(forEventType: .didShow, keyboardData: keyboardData)
    }

    @objc internal func keyboardWillChange(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }
        checkIfCustomHandlerExistsAndProceed(forEventType: .willChange, keyboardData: keyboardData)
    }

    @objc internal func keyboardDidChange(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }
        checkIfCustomHandlerExistsAndProceed(forEventType: .didChange, keyboardData: keyboardData)
    }

    @objc internal func keyboardWillHide(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }
        checkIfCustomHandlerExistsAndProceed(forEventType: .willHide, keyboardData: keyboardData)
    }

    @objc internal func keyboardDidHide(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification) else {
            return
        }
        checkIfCustomHandlerExistsAndProceed(forEventType: .didHide, keyboardData: keyboardData)
    }

    @objc internal func didBeginEditing(notification: Notification) {
        currentFirstResponder = notification.object as? UIView
    }

    @objc internal func didEndEditing(notification: Notification) {
        currentFirstResponder = nil
    }

    internal func checkIfCustomHandlerExistsAndProceed(forEventType type: KeyboardEventType, keyboardData: KeyboardEventData) {
        if !isTracking {
            return
        }

        if let handler = keyboardEventHandlers[type] {
            if handler.shouldOverride {
                handler.action(keyboardData, currentFirstResponder)
                return
            }
        }

        if shouldProcess(givenKeyboardEvent: type, andKeyboardEventData: keyboardData) {
            if areKeyboardParametersCorrect(forKeyboardEvent: type, beginRect: keyboardData.beginKeyboardRect, endRect: keyboardData.endKeyboardRect) {
                handleKeyboardEvent(ofType: type, withKeyboardData: keyboardData)
            }
        }

        keyboardEventHandlers[type]?.action(keyboardData, currentFirstResponder)
    }

    //Dummy function - should be overriden in descendant
    internal func shouldProcess(givenKeyboardEvent event: KeyboardEventType, andKeyboardEventData keyboardData: KeyboardEventData) -> Bool {
        return isTracking
    }

    //Dummy function - should be overriden in descendant
    internal func handleKeyboardEvent(ofType type: KeyboardEventType, withKeyboardData keyboardData: KeyboardEventData) {
        return
    }

    internal func areKeyboardParametersCorrect(forKeyboardEvent type: KeyboardEventType, beginRect: CGRect, endRect: CGRect) -> Bool {
        let isKeyboardHidden = isKeyboardBeingHidden(beginRect: beginRect, endRect: endRect)
        let isKeyboardSizeSame = isKeyboardFrameSame(beginRect: beginRect, endRect: endRect)
        let isKeyboardEndSizeCorrect = isKeyboardEndFrameCorrect(endRect: endRect)
        let changeOrHideEventOccured = (type == .willChange || type == .didChange || type == .willHide || type == .didHide)

        if changeOrHideEventOccured {
            return !isKeyboardSizeSame && isKeyboardEndSizeCorrect
        } else {
            return !isKeyboardHidden && !isKeyboardSizeSame && isKeyboardEndSizeCorrect
        }
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


    internal enum KeyboardState {
        case shown
        case hidden
    }
}

public enum KeyboardEventType: String {
    case willShow = "willShow"
    case didShow = "didShow"

    case willChange = "willChange"
    case didChange = "didChange"

    case willHide = "willHide"
    case didHide = "didHide"
}
