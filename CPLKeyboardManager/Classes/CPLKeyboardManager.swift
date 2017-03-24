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

    private var handlingKeyboardChange = false
    private var keyboardIsShown = false
    private var initialContentInset: UIEdgeInsets? = nil

    //In some cases KbEndFrame is the same as KBbeginFrame despite beign different (for example user taps on search bar and bar with predictions disappears)
    //This property is used to additionaly keep track of height
    private var lastKeyboardHeightAfterChange: CGFloat = 0.0

    public init(tableView: UITableView, inViewController viewController: UIViewController) {
        self.tableView = tableView
        self.viewController = viewController
        self.scrollView = nil
    }

    public init(scrollView: UIScrollView, inViewController viewController: UIViewController) {
        self.tableView = nil
        self.viewController = viewController
        self.scrollView = scrollView
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
        if keyboardIsShown || handlingKeyboardChange {
            return
        }

        if let userInfo = notification.userInfo,
            let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
            let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {

            if isKeyboardFrameSame(beginRect: beginKeyboardRect, endRect: endKeyboardRect) {
                return
            }

            handleKeyboardEvent(ofType: .Show, userInfo: userInfo)
        }
    }

    @objc func keyboardWillChange(notification: Notification) {
        if !keyboardIsShown || handlingKeyboardChange {
            return
        }

        guard let userInfo = notification.userInfo,
            let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
            let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect else {
                return
        }

        if  isKeyboardFrameSame(beginRect: beginKeyboardRect, endRect: endKeyboardRect) ||
            isKeyboardBeingHidden(beginRect: beginKeyboardRect, endRect: endKeyboardRect) { //hiding is handled in KBWillHide
            return
        }

        handleKeyboardEvent(ofType: .Change, userInfo: userInfo)
    }

    @objc func keyboardWillHide(notification: Notification) {
        if let tableView = tableView {
            let contentInset = initialContentInset ?? UIEdgeInsets.zero
            tableView.contentInset = contentInset
            tableView.scrollIndicatorInsets = contentInset
        } else if let scrollView = scrollView {
            let contentInset = initialContentInset ?? UIEdgeInsets.zero
            scrollView.contentInset = UIEdgeInsets.zero
            scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        }

        keyboardIsShown = false
        handlingKeyboardChange = false
        lastKeyboardHeightAfterChange = 0.0
    }

    private func handleKeyboardEvent(ofType type: KeyboardEventType,  userInfo: [AnyHashable:Any]) {
        guard let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
            let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let view = viewController?.view,
            let currentFirstResponderView = UIResponder.getCurrentFirstResponder() as? UIView,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else {
                return
        }

        let convertedBeginKeyboardRect = view.convert(beginKeyboardRect, to: view.window)
        let convertedEndKeyboardRect = view.convert(endKeyboardRect, from: view.window)
        let convertedFirstResponderView = view.convert(currentFirstResponderView.frame, from: currentFirstResponderView.superview)

        var insetDifference: CGFloat
        switch type {

        case .Show:
            saveCurrentContentInset()
            insetDifference = getBottomInsetChangeForKeyboardShown(keyboardRect: endKeyboardRect)
        case .Change:
            handlingKeyboardChange = true
            insetDifference = getBottomInsetChangeForKeboardChanged(beginKeyboardRect: beginKeyboardRect, endKeyboardRect: endKeyboardRect)
        }

        let newContentOffset = getNewContentOffset(textFieldRect: convertedFirstResponderView, keyboardRect: endKeyboardRect)

        performAnimation(withDuration: duration.doubleValue, andOptions: UIViewAnimationOptions(rawValue: animationCurve.uintValue), insetDifference: insetDifference, newContentOffset: newContentOffset, completion: { [weak self] in

            self?.lastKeyboardHeightAfterChange = endKeyboardRect.height

            switch type {
            case .Show:
                self?.keyboardIsShown = true
            case .Change:
                self?.handlingKeyboardChange = false
            }
        })
    }

    private func performAnimation(withDuration duration: Double, andOptions options: UIViewAnimationOptions, insetDifference: CGFloat, newContentOffset: CGPoint?, completion: @escaping (() -> Void)) {
        UIView.animate(withDuration: duration, delay: 0.0, options: options, animations: { [weak self] in
            if let tableView = self?.tableView {
                tableView.contentInset.bottom += insetDifference
                tableView.scrollIndicatorInsets.bottom += insetDifference
                if let newContentOffset = newContentOffset {
                    tableView.setContentOffset(newContentOffset, animated: false)
                }
            }
            }, completion: { _ in completion() })
    }

    private func saveCurrentContentInset() {
        if let tableView = tableView {
            initialContentInset = tableView.contentInset
        } else if let scrollView = scrollView {
            initialContentInset = scrollView.contentInset
        }
    }

    private func isKeyboardBeingHidden(beginRect: CGRect, endRect: CGRect) -> Bool {
        return beginRect.origin.y + beginRect.height == endRect.origin.y
    }

    private func isKeyboardFrameSame(beginRect: CGRect, endRect: CGRect) -> Bool {
        if endRect.height == lastKeyboardHeightAfterChange {
            return beginRect.equalTo(endRect)
        } else {
            return false
        }
    }

    private func getBottomInsetChangeForKeboardChanged(beginKeyboardRect: CGRect, endKeyboardRect: CGRect) -> CGFloat {
        var keyboardHeightDifference: CGFloat
        let endKbHeight = endKeyboardRect.height

        if endKbHeight != lastKeyboardHeightAfterChange {
            keyboardHeightDifference = endKbHeight - lastKeyboardHeightAfterChange
        } else {
            //origin is rising from top to bottom - that's why we substract from begin
            keyboardHeightDifference = beginKeyboardRect.origin.y - endKeyboardRect.origin.y
        }

        return keyboardHeightDifference
    }

    private func getBottomInsetChangeForKeyboardShown(keyboardRect: CGRect) -> CGFloat {
        if let tableView = tableView {
            var insetFix: CGFloat = 0.0
            if let currentBottomInset = initialContentInset?.bottom, !shouldPreserveContentInset {
                insetFix = currentBottomInset
            }
            return tableView.frame.maxY - keyboardRect.origin.y - insetFix
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
        notificationCenter.addObserver(self, selector: #selector(keyboardWillChange), name: .UIKeyboardWillChangeFrame, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }

    private func unregisterFromNotifications() {
        notificationCenter.removeObserver(self)
    }

    private enum KeyboardEventType {
        case Show
        case Change
    }
}
