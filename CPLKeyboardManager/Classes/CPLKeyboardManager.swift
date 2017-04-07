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

    /**
     - Parameter bottomConstraint: Constraint that is at bottom of the screen. It must be the one that connects bottom edge (bottom layout guide) with view you want to move when keyboard appears.
    */
    public init(bottomConstraint: NSLayoutConstraint, inViewController viewController: UIViewController) {
        manager = CPLKeyboardManagerConstraint(bottomConstraint: bottomConstraint, inViewController: viewController)
    }

    public func start() {
        manager.start()
    }

    public func stop() {
        manager.stop()
    }

    public func setHandler(ofType type: EventHandlerType, action: @escaping ((_ keyboardEventData: KeyboardEventData) -> Void), shouldOverride: Bool) {
        manager.keyboardEventHandlers[type] = (action, shouldOverride)
    }
}
