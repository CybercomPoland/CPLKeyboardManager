//
//  CPLKeyboardManager.swift
//  Pods
//
//  Created by Michal Zietera on 06.04.2017.
//
//

import Foundation

/**
 This class is responsible for managing view when keyboard appears.
 
 In case of scrollView it will modify its insets, so user could still scroll to the bottom of the view. It also manages to scroll to current first responder if it is obscured by something (this feature is free to have from iOS but this manager adds some space so e.g. textField is not touching keyboard frame).
 In case of constraint it will modify just its constant.
 
 When textView is first responder, the exact position of carret is known during "didShow" notification, so there is actually slight delay between showing keyboard and scrolling view (if it is needed).
 */
public class CPLKeyboardManager {
    private var manager: CPLKeyboardManagerBase

    //TODO: create dedicated configuration struct

    //CONFIGURATION
    public var spaceBelowAndAboveEditable: CGFloat = 15.0 {
        didSet {
            manager.spaceBelowAndAboveEditable = spaceBelowAndAboveEditable
        }
    }

    public var shouldPreserveContentInset = true {
        didSet {
            manager.shouldPreserveContentInset = shouldPreserveContentInset
        }
    }

    public var defaultAnimationDuration: Double = 0.25 { //used when duration is not provided in userInfo
        didSet {
            manager.defaultAnimationDuration = defaultAnimationDuration
        }
    }
    //CONFIGURATION

    public init(tableView: UITableView, inViewController viewController: UIViewController) {
        manager = CPLKeyboardManagerScrollView(tableView: tableView, inViewController: viewController)
    }

    public init(scrollView: UIScrollView, inViewController viewController: UIViewController) {
        manager = CPLKeyboardManagerScrollView(scrollView: scrollView, inViewController: viewController)
    }

    /**
     Manager will modify bottom constraint to move view when keyboard appears.

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
            - false: Given logic should be executed with default one. If given event by default doesn't have handler (e.g. willShow when textView is first responder), action passed in this method will be still executed.

     */
    public func setHandler(forEventType type: KeyboardEventType, action: @escaping ((_ keyboardEventData: KeyboardEventData, _ firstResponder: UIResponder?) -> Void), shouldOverride: Bool) {
        manager.keyboardEventHandlers[type] = (action, shouldOverride)
    }
}
