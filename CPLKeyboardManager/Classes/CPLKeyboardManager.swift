//
//  CPLKeyboardManager.swift
//  Pods
//
//  Created by Michal Zietera on 17.03.2017.
//
//

import Foundation


//There is inconcistency for UITextView where keyboardWillShow notification is sent before didBeginEditing (as opposed to UITextField where latter is first)
//That's why this extension is introduced - to get first responder during keyboardWillShow handling
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

    private var currentTextFieldView: UIView?
    private var spaceBetweenEditableAndKeyboardTop: CGFloat = 10.0

    private var keyboardChangeWasHandled = false
    private var keyboardIsShown = false

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
    //iOS 9: This method is called only once (like it should)
    //iOS 8: This method is called every time keyboard changes
    @objc func keyboardWillShow(notification: Notification) {
        if keyboardIsShown || keyboardChangeWasHandled {
            keyboardChangeWasHandled = false
            return
        }

        currentTextFieldView = UIResponder.getCurrentFirstResponder() as? UIView

        if let userInfo = notification.userInfo,
            let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
            let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let view = viewController?.view,
            let currentTextFieldView = currentTextFieldView  {

            if beginKeyboardRect.equalTo(endKeyboardRect) {
                return
            }

            let convertedEndKeyboardRect = view.convert(endKeyboardRect, from: view.window)
            let convertedTextFieldViewRect = view.convert(currentTextFieldView.frame, from: currentTextFieldView.superview)

            handleKeyboardAppearance(fieldRect: convertedTextFieldViewRect, keyboardRect: convertedEndKeyboardRect, userInfo: userInfo)
        }
    }

    @objc func keyboardWillChange(notification: Notification) {
        if !keyboardIsShown {
            return
        }

        currentTextFieldView = UIResponder.getCurrentFirstResponder() as? UIView

        guard let userInfo = notification.userInfo,
            let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
            let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let view = viewController?.view else {
            return
        }

        if  isKeyboardFrameSame(beginRect: beginKeyboardRect, endRect: endKeyboardRect) ||
            isKeyboardBeingHidden(beginRect: beginKeyboardRect, endRect: endKeyboardRect) { //hiding is handled in KBWillHide
            return
        }

        let insetDifference = calculateBottomInsetChangeForKeboardFrameChange(beginKeyboardRect: beginKeyboardRect, endKeyboardRect: endKeyboardRect)

        tableView?.contentInset.bottom += insetDifference
        tableView?.scrollIndicatorInsets.bottom += insetDifference

        keyboardChangeWasHandled = true
        lastKeyboardHeightAfterChange = endKeyboardRect.height
    }

    @objc func keyboardWillHide(notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {

            if let tableView = tableView {
                tableView.contentInset = UIEdgeInsets.zero
                tableView.scrollIndicatorInsets = UIEdgeInsets.zero
            } else if let scrollView = scrollView {
                scrollView.contentInset = UIEdgeInsets.zero
                scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
            }

            keyboardIsShown = false
            keyboardChangeWasHandled = false
            lastKeyboardHeightAfterChange = 0.0
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

    private func calculateBottomInsetChangeForKeboardFrameChange(beginKeyboardRect: CGRect, endKeyboardRect: CGRect) -> CGFloat {
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

    private func handleKeyboardAppearance(fieldRect: CGRect, keyboardRect: CGRect, userInfo: [AnyHashable:Any]) {
        guard let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else {
                return
        }

        let textFieldRectWithBottomSpace = CGRect(origin: fieldRect.origin, size: CGSize(width: fieldRect.width, height: fieldRect.height + spaceBetweenEditableAndKeyboardTop))
        let fieldIsCoveredByKeyboard = keyboardRect.intersects(fieldRect)
        //TODO: Text field: position at middle; TextView: wait 0.01 and calculate position
        UIView.animate(withDuration: duration.doubleValue, delay: 0, options: UIViewAnimationOptions(rawValue: animationCurve.uintValue), animations: { [weak self] in
            if let tableView = self?.tableView {
                let keyboardOverlap = tableView.frame.maxY - keyboardRect.origin.y

                tableView.contentInset.bottom = keyboardOverlap
                tableView.scrollIndicatorInsets.bottom = keyboardOverlap

                if fieldIsCoveredByKeyboard {
                    let newContentOffset = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + textFieldRectWithBottomSpace.maxY - keyboardRect.origin.y)
                    tableView.setContentOffset(newContentOffset, animated: false)
                }
            }
            }, completion: { [weak self] _ in
                self?.keyboardIsShown = true
                self?.lastKeyboardHeightAfterChange = keyboardRect.height })
    }

    private func handleKeyboardFrameChange(fieldRect: CGRect, keyboardRect: CGRect, userInfo: [AnyHashable:Any]) {
        guard let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else {
                return
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
}
