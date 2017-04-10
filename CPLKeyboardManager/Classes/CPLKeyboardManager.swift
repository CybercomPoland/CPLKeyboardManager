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

    /**
     Starts handling incoming keyboard events.
    */
    public func start() {
        manager.start()
    }

    /**
     Stops handling incoming keyboard events. Manager is still registered for events.
    */
    public func stop() {
        manager.stop()
    }

    /**
     Set handler for given keyboard-related event type

     - Parameters:
        - forEventType: Type of event that should be handled
        - action: Logic that should be executed when event occurs
        - keyboardEventData: Gathered data about keyboard event that occured.
        - firstResponder:   Current first responder that triggered keyboard appearance.
        - shouldOverride: 
            - true: Given logic should be executed instead default one.
            - false: Given logic should be executed with default one. If given event by default doesn't have handler (i.e. willShow when textView is first responder), action passed in this method will be still executed.

     */
    public func setHandler(forEventType type: KeyboardEventType, action: @escaping ((_ keyboardEventData: KeyboardEventData, _ firstResponder: UIResponder?) -> Void), shouldOverride: Bool) {
        manager.keyboardEventHandlers[type] = (action, shouldOverride)
    }
}
