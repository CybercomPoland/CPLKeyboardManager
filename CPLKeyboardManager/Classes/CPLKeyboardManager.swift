//
//  CPLKeyboardManager.swift
//  Pods
//
//  Created by Michal Zietera on 17.03.2017.
//
//

import Foundation


//There is inconcistency for UITextView where keyboardWillShow notification is sent before didBeginEditing (as opposed to UITextField where latter is first)
//That's why this extension is introduced - to get first responder during events handling
extension UIResponder {
    @nonobjc private static var firstResponder: UIResponder?

    static func getCurrentFirstResponder() -> UIResponder? {
        UIResponder.firstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder), to: nil, from: nil, for: nil)
        return UIResponder.firstResponder
    }

    @objc private func findFirstResponder(sender: AnyObject) {
        UIResponder.firstResponder = self
    }
}

public class CPLKeyboardManager {
    let tableView: UITableView?
    let scrollView: UIScrollView?
    let notificationCenter = NotificationCenter.default
    weak var viewController: UIViewController?

    ////CONFIGURATION////
    private var spaceBetweenEditableAndKeyboardTop: CGFloat = 10.0
    private var shouldPreserveContentInset = true
    ////CONFIGURATION////

    private var keyboardState: KeyboardState = .Hidden

    private var showKeyboardOperationCount = 0
    private var keyboardIsShown: Bool {
        return showKeyboardOperationCount == 0 && keyboardState == .Shown
    }

    private var changeKeyboardOperationCount = 0
    private var handlingKeyboardChange: Bool {
        return changeKeyboardOperationCount > 0 && keyboardState == .Shown
    }

    private var initialContentInset: UIEdgeInsets? = nil
    private var currentContentInset: UIEdgeInsets

    //In some cases KbEndFrame is the same as KBbeginFrame despite beign different (for example user taps on search bar and bar with predictions disappears)
    //This property is used to additionaly keep track of height
    private var currentKeyboardHeight: CGFloat = 0.0

    public init(tableView: UITableView, inViewController viewController: UIViewController) {
        self.tableView = tableView
        self.currentContentInset = tableView.contentInset
        self.viewController = viewController
        self.scrollView = nil
    }

    public init(scrollView: UIScrollView, inViewController viewController: UIViewController) {
        self.tableView = nil
        self.viewController = viewController
        self.scrollView = scrollView
        self.currentContentInset = scrollView.contentInset
    }

    public func start() {
        self.registerForNotifications()
    }

    public func stop() {
        self.unregisterFromNotifications()
    }

    deinit {
        self.unregisterFromNotifications()
    }

    //iOS 10: This method is called every time user taps input field and if keyboard changes
    //iOS 9 & 8: This method is called every time keyboard changes
    @objc func keyboardWillShow(notification: Notification) {
        if shouldProcess(givenKeyboardEvent: .WillShow, andNotification: notification) {
            handleKeyboardEvent(ofType: .WillShow, notification: notification)
        }
    }

    @objc func keyboardDidShow(notification: Notification) {
        if shouldProcess(givenKeyboardEvent: .DidShow, andNotification: notification) {
            handleKeyboardEvent(ofType: .DidShow, notification: notification)
        }
    }

    @objc func keyboardWillChange(notification: Notification) {
        if shouldProcess(givenKeyboardEvent: .WillChange, andNotification: notification) {
            handleKeyboardEvent(ofType: .WillChange, notification: notification)
        }
    }

    @objc func keyboardDidChange(notification: Notification) {
        if shouldProcess(givenKeyboardEvent: .DidChange, andNotification: notification) {
            handleKeyboardEvent(ofType: .DidChange, notification: notification)
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if let tableView = tableView {
            let contentInset = initialContentInset ?? UIEdgeInsets.zero
            tableView.contentInset = contentInset
            tableView.scrollIndicatorInsets = contentInset
            currentContentInset = tableView.contentInset
        } else if let scrollView = scrollView {
            let contentInset = initialContentInset ?? UIEdgeInsets.zero
            scrollView.contentInset = UIEdgeInsets.zero
            scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
            currentContentInset = scrollView.contentInset
        }

        keyboardState = .Hidden
        currentKeyboardHeight = 0.0
        initialContentInset = nil
    }

    //TextView should be processed in Didxxxxx series of keyboard events (due to incorrect selectedRange value during willxxxxx events)
    private func shouldProcess(givenKeyboardEvent event: KeyboardEventType, andNotification notification: Notification) -> Bool {
        guard let userInfo = notification.userInfo,
            let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
            let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let currentFirstResponder = UIResponder.getCurrentFirstResponder() as? UIView else {
            return false
        }

        if #available(iOS 9.0, *) {
            if let keyboardLocal = userInfo[UIKeyboardIsLocalUserInfoKey] as? Bool, !keyboardLocal {
                return false
            }
        }

        if isKeyboardFrameSame(beginRect: beginKeyboardRect, endRect: endKeyboardRect) {
            return false
        }

        let isResponderTextView = currentFirstResponder.isKind(of: UITextView.self)

        switch event {
        case .WillShow:
            if !isResponderTextView {
                return currentKeyboardStateAllowsForProceeding(consideringGivenEvent: event, beginKeyboardRect: beginKeyboardRect, andEndKeyboardRect: endKeyboardRect)
            } else {
                return false
            }
        case .DidShow:
            if isResponderTextView {
                return currentKeyboardStateAllowsForProceeding(consideringGivenEvent: event, beginKeyboardRect: beginKeyboardRect, andEndKeyboardRect: endKeyboardRect)
            } else {
                return false
            }
        case .WillChange:
            if !isResponderTextView {
                return currentKeyboardStateAllowsForProceeding(consideringGivenEvent: event, beginKeyboardRect: beginKeyboardRect, andEndKeyboardRect: endKeyboardRect)
            } else {
                return false
            }
        case .DidChange:
            if isResponderTextView {
                return currentKeyboardStateAllowsForProceeding(consideringGivenEvent: event, beginKeyboardRect: beginKeyboardRect, andEndKeyboardRect: endKeyboardRect)
            } else {
                return false
            }
        }
    }

    private func currentKeyboardStateAllowsForProceeding(consideringGivenEvent event: KeyboardEventType, beginKeyboardRect: CGRect, andEndKeyboardRect endKeyboardRect: CGRect) -> Bool {
        switch event {
        case .WillShow, .DidShow:
            if keyboardIsShown ||
                handlingKeyboardChange ||
                isKeyboardBeingHidden(beginRect: beginKeyboardRect, endRect: endKeyboardRect) { //somtimes endKB == 0 for some reason for 3rd party keyboards
                return false
            } else {
                return true
            }
        case .WillChange, .DidChange:
            if !keyboardIsShown ||
                isKeyboardBeingHidden(beginRect: beginKeyboardRect, endRect: endKeyboardRect) {
                return false
            } else {
                return true
            }
        }
    }

    private func handleKeyboardEvent(ofType type: KeyboardEventType,  notification: Notification) {
        guard let userInfo = notification.userInfo,
            let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
            let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let view = viewController?.view,
            let currentFirstResponderView = UIResponder.getCurrentFirstResponder() as? UIView,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else {
                return
        }

        let convertedBeginKeyboardRect = view.convert(beginKeyboardRect, to: view.window)
        let convertedEndKeyboardRect = view.convert(endKeyboardRect, from: view.window)
        let convertedFirstResponderRect = getRect(forGivenFirstResponder: currentFirstResponderView, convertedToCoordinatesSystemOf: view)

        var insetDifference: CGFloat
        switch type {
        case .WillShow, .DidShow: //there should not be situation when for single currentFirstResponder both WillShow and DidShow will be handled here
            saveInitialContentInsetIfNeeded()
            showKeyboardOperationCount += 1
            insetDifference = getBottomInsetChangeForKeyboardShown(keyboardRect: endKeyboardRect)
        case .WillChange, .DidChange:
            changeKeyboardOperationCount += 1
            insetDifference = getBottomInsetChangeForKeboardChanged(beginKeyboardRect: beginKeyboardRect, endKeyboardRect: endKeyboardRect)
        }

        currentContentInset.bottom += insetDifference

        let newContentOffset = getNewContentOffset(textFieldRect: convertedFirstResponderRect, keyboardRect: endKeyboardRect)
        currentKeyboardHeight = endKeyboardRect.height


        performAnimation(withDuration: duration.doubleValue, andOptions: UIViewAnimationOptions(rawValue: animationCurve.uintValue), insetDifference: insetDifference, newContentOffset: newContentOffset, completion: { [weak self] in

            switch type {
            case .WillShow, .DidShow:
                self?.keyboardState = .Shown
                self?.showKeyboardOperationCount -= 1
            case .WillChange, .DidChange:
                self?.changeKeyboardOperationCount -= 1
            }
        })
    }

    private func performAnimation(withDuration duration: Double, andOptions options: UIViewAnimationOptions, insetDifference: CGFloat, newContentOffset: CGPoint?, completion: @escaping (() -> Void)) {
        UIView.animate(withDuration: duration, delay: 0.0, options: options, animations: { [weak self] in
            if let tableView = self?.tableView {
                tableView.contentInset.bottom += insetDifference
                tableView.scrollIndicatorInsets.bottom += insetDifference
                //TODO: when user scrolls so current first reposnder is out of sight, kb frame change causes scroll despite reasigning current contentOffset below
                let contentOffset = newContentOffset ?? tableView.contentOffset
                tableView.setContentOffset(contentOffset, animated: false)
            }
            }, completion: { _ in completion() })
    }

    private func getRect(forGivenFirstResponder firstResponder: UIView, convertedToCoordinatesSystemOf view: UIView) -> CGRect {
        let convertedRect = view.convert(firstResponder.frame, from: firstResponder.superview)

        if let textView = firstResponder as? UITextView {
           let selectedRange = textView.selectedRange
        }
        return convertedRect
    }

    private func saveInitialContentInsetIfNeeded() {
        if !keyboardIsShown && initialContentInset == nil {
            if let tableView = tableView {
                initialContentInset = tableView.contentInset
            } else if let scrollView = scrollView {
                initialContentInset = scrollView.contentInset
            }
        }
    }

    private func isKeyboardBeingHidden(beginRect: CGRect, endRect: CGRect) -> Bool {
        return beginRect.origin.y + beginRect.height == endRect.origin.y
    }

    private func isKeyboardFrameSame(beginRect: CGRect, endRect: CGRect) -> Bool {
        if endRect.height == currentKeyboardHeight {
            return beginRect.equalTo(endRect)
        } else {
            return false
        }
    }

    private func getBottomInsetChangeForKeboardChanged(beginKeyboardRect: CGRect, endKeyboardRect: CGRect) -> CGFloat {
        var keyboardHeightDifference: CGFloat
        let endKbHeight = endKeyboardRect.height

        if endKbHeight != currentKeyboardHeight {
            keyboardHeightDifference = endKbHeight - currentKeyboardHeight
        } else {
            //origin is rising from top to bottom - that's why we substract from begin
            keyboardHeightDifference = beginKeyboardRect.origin.y - endKeyboardRect.origin.y
        }

        return keyboardHeightDifference
    }

    private func getBottomInsetChangeForKeyboardShown(keyboardRect: CGRect) -> CGFloat {
        if let tableView = tableView {
            var insetFix: CGFloat = 0.0
            if let initialBottomInset = initialContentInset?.bottom, shouldPreserveContentInset {
                insetFix = initialBottomInset
            }

            let bottomInsetDiff = tableView.frame.maxY - keyboardRect.origin.y + insetFix - currentContentInset.bottom
            return bottomInsetDiff
        }
        return 0.0
    }

    private func getNewContentOffset(textFieldRect: CGRect, keyboardRect: CGRect) -> CGPoint? {
        let textFieldRectWithBottomSpace = CGRect(origin: textFieldRect.origin, size: CGSize(width: textFieldRect.width, height: textFieldRect.height + spaceBetweenEditableAndKeyboardTop))

        if textFieldRectWithBottomSpace.intersects(keyboardRect) {
            if let tableView = tableView {
                return CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + textFieldRectWithBottomSpace.maxY - keyboardRect.origin.y)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    private func registerForNotifications() {
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidShow), name: .UIKeyboardDidShow, object: nil)

        notificationCenter.addObserver(self, selector: #selector(keyboardWillChange), name: .UIKeyboardWillChangeFrame, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidChange), name: .UIKeyboardDidChangeFrame, object: nil)

        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)

        notificationCenter.addObserver(self, selector: #selector(didbegin), name: .UITextViewTextDidBeginEditing, object: nil)
    }

    @objc func didbegin(not: Notification) {

    }

    private func unregisterFromNotifications() {
        notificationCenter.removeObserver(self)
    }

    private enum KeyboardEventType {
        case WillShow
        case DidShow
        case WillChange
        case DidChange
    }

    private enum KeyboardState {
        case Shown
        case Hidden
    }
}
