//
//  CPLKeyboardManager.swift
//  Pods
//
//  Created by Michal Zietera on 06.04.2017.
//
//

import Foundation

public class CPLKeyboardManager {
    private var manager: CPLKeyboardManagerBase

    public init(tableView: UITableView, inViewController viewController: UIViewController) {
        manager = CPLKeyboardManagerScrollView(tableView: tableView, inViewController: viewController)
    }

    public init(scrollView: UIScrollView, inViewController viewController: UIViewController) {
        manager = CPLKeyboardManagerScrollView(scrollView: scrollView, inViewController: viewController)
    }

    public init(bottomConstraint: NSLayoutConstraint) {
        manager = CPLKeyboardManagerConstraint(bottomConstraint: bottomConstraint)
    }

    public func start() {
        manager.start()
    }

    public func stop() {
        manager.stop()
    }
}
