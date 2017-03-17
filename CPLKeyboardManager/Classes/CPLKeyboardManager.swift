//
//  CPLKeyboardManager.swift
//  Pods
//
//  Created by Michal Zietera on 17.03.2017.
//
//

import Foundation

public class CPLKeyboardManager {
    let tableView: UITableView
    let notificationCenter = NotificationCenter.default

    public init(withTableView tableView: UITableView) {
        self.tableView = tableView
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

    @objc func keyboardWillShow(notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            let newContentInsets = UIEdgeInsets(top: tableView.contentInset.top, left: tableView.contentInset.left, bottom: keyboardSize.height, right: tableView.contentInset.right)
            tableView.contentInset = newContentInsets
            tableView.scrollIndicatorInsets = newContentInsets
            print(keyboardSize)
        }
    }

    @objc func keyboardWillChange(notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            let newContentInsets = UIEdgeInsets(top: tableView.contentInset.top, left: tableView.contentInset.left, bottom: keyboardSize.height, right: tableView.contentInset.right)
            tableView.contentInset = newContentInsets
            tableView.scrollIndicatorInsets = newContentInsets
            print(keyboardSize)
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            let newContentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
            tableView.contentInset = newContentInsets
            tableView.scrollIndicatorInsets = newContentInsets
            print(keyboardSize)
        }
    }

    @objc func didBeginEditing(notification: Notification) {

    }

    private func registerForNotifications() {
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillChange), name: .UIKeyboardWillChangeFrame, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)

        notificationCenter.addObserver(self, selector: #selector(didBeginEditing), name: .UITextFieldTextDidBeginEditing, object: nil)
    }

    private func unregisterFromNotifications() {
        notificationCenter.removeObserver(self)
    }
}
