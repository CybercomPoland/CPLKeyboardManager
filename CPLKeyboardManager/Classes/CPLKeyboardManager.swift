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

//extension UIResponder {
//    @nonobjc private static var firstResponder: UIResponder?
//
//    static func getCurrentFirstResponder() -> UIResponder? {
//        UIResponder.firstResponder = nil
//        UIApplication.shared.sendAction(#selector(findFirstResponder), to: nil, from: nil, for: nil)
//        return UIResponder.firstResponder
//    }
//
//    @objc private func findFirstResponder(sender: AnyObject) {
//        UIResponder.firstResponder = self
//    }
//}

public class CPLKeyboardManager {
    let tableView: UITableView?
    let scrollView: UIScrollView?
    let notificationCenter = NotificationCenter.default
    weak var viewController: UIViewController?

    ////CONFIGURATION////
    public var spaceBetweenEditableAndKeyboardTop: CGFloat = 15.0
    public var shouldPreserveContentInset = true
    public var defaultAnimationDuration: Double = 0.25 //used when duration is not provided in userInfo
    ////CONFIGURATION////

    private var mode: Mode
    private var keyboardState: KeyboardState = .Hidden
    private var isKeyboardVisible: Bool = false //we set this in didChange (as undocked kb doesn't send will/did show/hide)

//    private var showKeyboardOperationCount = 0
//    private var keyboardIsShown: Bool {
//        return showKeyboardOperationCount == 0 && keyboardState == .Shown
//    }

//    private var changeKeyboardOperationCount = 0
//    private var handlingKeyboardChange: Bool {
//        return changeKeyboardOperationCount > 0 && keyboardState == .Shown
//    }

    private var standardKeyboard = false

    private var currentFirstResponder: UIView? = nil

    private var initialContentInset: UIEdgeInsets? = nil
    private var currentContentInset: UIEdgeInsets

    //In some cases KbEndFrame is the same as KBbeginFrame despite beign actually different (for example user taps on search bar and bar with predictions disappears)
    //This property is used to additionaly keep track of height
    private var currentKeyboardHeight: CGFloat = 0.0

    public init(tableView: UITableView, inViewController viewController: UIViewController) {
        self.currentContentInset = tableView.contentInset
        self.viewController = viewController
        self.tableView = tableView
        self.scrollView = nil
        self.mode = .TableView
    }

    public init(scrollView: UIScrollView, inViewController viewController: UIViewController) {
        self.currentContentInset = scrollView.contentInset
        self.viewController = viewController
        self.tableView = nil
        self.scrollView = scrollView
        self.mode = .ScrollView
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
        let endKb = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! CGRect)
        print("\(#function) \n      beginKbFrame: \(notification.userInfo![UIKeyboardFrameBeginUserInfoKey]!) \n    endKbFrame: \(endKb) \n    maxY: \(endKb.maxY)")

        standardKeyboard = true
        if shouldProcess(givenKeyboardEvent: .WillShow, andNotification: notification) {
            handleKeyboardEvent(ofType: .WillShow, notification: notification)
        }
    }

    @objc func keyboardDidShow(notification: Notification) {
        if shouldProcess(givenKeyboardEvent: .DidShow, andNotification: notification) {
            handleKeyboardEvent(ofType: .DidShow, notification: notification)
        }
    }

    @objc func keyboardDidChange(notification: Notification) {
        print("\(#function)  standardKb: \(standardKeyboard) \n     beginKbFrame: \(notification.userInfo![UIKeyboardFrameBeginUserInfoKey]!) \n    endKbFrame: \(notification.userInfo![UIKeyboardFrameEndUserInfoKey]!)")
//        if shouldProcess(givenKeyboardEvent: .DidChange, andNotification: notification) {
        if let userInfo = notification.userInfo,
            let begin = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
            let end = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {

            isKeyboardVisible = viewController!.view.bounds.contains(end)
            if isKeyboardVisible && keyboardState == .Shown {
                if begin != CGRect.zero && end != CGRect.zero { //needs checking if keyboard exits undocked state
                    handleKeyboardEvent(ofType: .DidChange, notification: notification)
                }
            }
        }
        
//        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        let contentInset = initialContentInset ?? UIEdgeInsets.zero
        switch mode {
        case .TableView:
            tableView?.contentInset = contentInset
            tableView?.scrollIndicatorInsets = contentInset
        case .ScrollView:
            scrollView?.contentInset = contentInset
            scrollView?.scrollIndicatorInsets = contentInset
        }

        currentContentInset = contentInset
        keyboardState = .Hidden
        currentKeyboardHeight = 0.0
        initialContentInset = nil
    }

    @objc func keyboardDidHide(notification: Notification) {
    }

    //TextView should be processed in Didxxxxx series of keyboard events (due to incorrect selectedRange value during willxxxxx events)
    private func shouldProcess(givenKeyboardEvent event: KeyboardEventType, andNotification notification: Notification) -> Bool {
        guard let userInfo = notification.userInfo,
            let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
            let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let view = viewController?.view,
            let currentFirstResponder = currentFirstResponder else {
            return false
        }

        let convertedBeginKeyboardRect = convertRect(rect: beginKeyboardRect, toView: view, fromView: view.window)
        let convertedEndKeyboardRect = convertRect(rect: endKeyboardRect, toView: view, fromView: view.window)

        //TODO: if not local - should slide whole view
//        if #available(iOS 9.0, *) {
//            if let keyboardLocal = userInfo[UIKeyboardIsLocalUserInfoKey] as? Bool, !keyboardLocal {
//                return false
//            }
//        }

//        if event == .WillChange || event == .DidChange {
//            if isKeyboardUndockedOrSplit(beginRect: beginKeyboardRect, endRect: endKeyboardRect) {
//                return false
//            }
//        }

        let isResponderTextView = currentFirstResponder.isKind(of: UITextView.self)

        if isResponderTextView {
            switch event {
            case .DidShow, .DidChange:
                return currentKeyboardStateAllowsForProceeding(consideringGivenEvent: event, beginKeyboardRect: convertedBeginKeyboardRect, andEndKeyboardRect: convertedEndKeyboardRect)
            case .WillShow, .WillChange:
                return false
            }
        } else {
            switch event {
            case .WillShow,. WillChange:
                return currentKeyboardStateAllowsForProceeding(consideringGivenEvent: event, beginKeyboardRect: convertedBeginKeyboardRect, andEndKeyboardRect: convertedEndKeyboardRect)
            case .DidShow, .DidChange:
                return false
            }
        }
    }

    private func currentKeyboardStateAllowsForProceeding(consideringGivenEvent event: KeyboardEventType, beginKeyboardRect: CGRect, andEndKeyboardRect endKeyboardRect: CGRect) -> Bool {

        if isKeyboardFrameSame(beginRect: beginKeyboardRect, endRect: endKeyboardRect) {
            return false
        }

        switch event {
        case .WillShow, .DidShow:
            if !isShownKeyboardFrameCorrect(beginRect: beginKeyboardRect, endRect: endKeyboardRect) ||
                isKeyboardBeingHidden(beginRect: beginKeyboardRect, endRect: endKeyboardRect) { //somtimes endKB == 0 for some reason for 3rd party keyboards
                return false
            } else {
                return true
            }
        case .WillChange, .DidChange:
            if isKeyboardBeingHidden(beginRect: beginKeyboardRect, endRect: endKeyboardRect) {
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
            let currentFirstResponderView = currentFirstResponder,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else {
                return
        }

        let convertedBeginKeyboardRect = view.convert(beginKeyboardRect, from: view.window)
        let convertedEndKeyboardRect = view.convert(endKeyboardRect, from: view.window)
        let convertedFirstResponderRect = getRect(forGivenFirstResponder: currentFirstResponderView, convertedToCoordinatesSystemOf: view)

        var insetDifference: CGFloat
        switch type {
        case .WillShow, .DidShow: //there should not be situation when for single currentFirstResponder both WillShow and DidShow will be handled here
            saveInitialContentInsetIfNeeded()
            keyboardState = .Shown
            //showKeyboardOperationCount += 1
            insetDifference = getBottomInsetChangeForKeyboardShown(keyboardRect: convertedEndKeyboardRect)
        case .WillChange, .DidChange:
            //changeKeyboardOperationCount += 1
            insetDifference = getBottomInsetChangeForKeboardChanged(beginKeyboardRect: convertedBeginKeyboardRect, endKeyboardRect: convertedEndKeyboardRect)
        }

        currentContentInset.bottom += insetDifference

        let newContentOffset = getNewContentOffset(textFieldRect: convertedFirstResponderRect, keyboardRect: convertedEndKeyboardRect)
        currentKeyboardHeight = convertedEndKeyboardRect.height

        let options: UIViewAnimationOptions = [UIViewAnimationOptions(rawValue: animationCurve.uintValue << 16), UIViewAnimationOptions.beginFromCurrentState]
        let durationValue = duration.doubleValue == 0.0 ? defaultAnimationDuration : duration.doubleValue

        performAnimation(withDuration: durationValue, andOptions: options, insetDifference: insetDifference, newContentOffset: newContentOffset, completion: { [weak self] in

            switch type {
            case .WillShow, .DidShow:
                self?.keyboardState = .Shown
                //self?.showKeyboardOperationCount -= 1
            case .WillChange, .DidChange:
                break
                //self?.changeKeyboardOperationCount -= 1
            }
        })
    }

    private func performAnimation(withDuration duration: Double, andOptions options: UIViewAnimationOptions, insetDifference: CGFloat, newContentOffset: CGPoint?, completion: @escaping (() -> Void)) {

        UIView.animate(withDuration: duration, delay: 0.0, options: options, animations: { [weak self] in
            switch self!.mode {
            case .TableView:
                self?.tableView?.contentInset.bottom += insetDifference
                self?.tableView?.scrollIndicatorInsets.bottom += insetDifference
            case .ScrollView:
                self?.scrollView?.contentInset.bottom += insetDifference
                self?.scrollView?.scrollIndicatorInsets.bottom += insetDifference
            }

            if let contentOffset = newContentOffset,
                let strongSelf = self {
                switch strongSelf.mode {
                case .TableView:
                    strongSelf.tableView?.setContentOffset(contentOffset, animated: false)
                case .ScrollView:
                    strongSelf.scrollView?.setContentOffset(contentOffset, animated: false)
                }
            }
            }, completion: { _ in completion() })
    }

    private func convertRect(rect: CGRect, toView: UIView, fromView: UIView?) -> CGRect {
        return toView.convert(rect, from: fromView)
    }

    private func getRect(forGivenFirstResponder firstResponder: UIView, convertedToCoordinatesSystemOf view: UIView) -> CGRect {
        let convertedRect = view.convert(firstResponder.frame, from: firstResponder.superview)

        if let textView = firstResponder as? UITextView,
            let selectedTextRange = textView.selectedTextRange,
            let selectionRects = textView.selectionRects(for: selectedTextRange) as? [UITextSelectionRect] {

            if let lowestTextSelectionRect = selectionRects.reduce(selectionRects.first, { (firstRect, secondRect) -> UITextSelectionRect in
                return firstRect!.rect.origin.y > secondRect.rect.origin.y ? firstRect! : secondRect
            }) {
                let convertedLowestRect = view.convert(lowestTextSelectionRect.rect, from: textView)
                return convertedLowestRect
            }
        }
        return convertedRect
    }

    private func saveInitialContentInsetIfNeeded() {
        if initialContentInset == nil {
            switch mode {
            case .TableView:
                if let tableView = tableView {
                    initialContentInset = tableView.contentInset
                }
            case .ScrollView:
                if let scrollView = scrollView {
                    initialContentInset = scrollView.contentInset
                }
            }
        }
    }

    private func isShownKeyboardFrameCorrect(beginRect: CGRect, endRect: CGRect) -> Bool {
        if let view = viewController?.view {
            return endRect.maxY == view.bounds.maxY
        } else {
            //should not happen as we pass view controller in init
            let mainScreen = UIScreen.main.bounds
            return endRect.maxY == mainScreen.maxY
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

//    private func isKeyboardUndockedOrSplit(beginRect: CGRect, endRect: CGRect) -> Bool {
//        //in case of split/undocked state begin (or end) rect has origin and size equal zero (in case of iOS 9)
//        //in case of iOS 8 we need to check if maxY is above bottom of the screen
//        let mainScreenBounds = UIScreen.main.bounds
//        if beginRect == CGRect.zero || endRect == CGRect.zero ||
//            beginRect.maxY < mainScreenBounds.height || endRect.maxY < mainScreenBounds.height {
//            return true
//        }
//        return false
//    }

    private func getBottomInsetChangeForKeboardChanged(beginKeyboardRect: CGRect, endKeyboardRect: CGRect) -> CGFloat {
        var keyboardHeightDifference: CGFloat
        let endKbHeight = endKeyboardRect.height

        if endKbHeight != currentKeyboardHeight {
            keyboardHeightDifference = endKbHeight - currentKeyboardHeight
        } else {
            let mainScreenBounds = UIScreen.main.bounds
            if beginKeyboardRect.origin.y == mainScreenBounds.height {
                //after orientation change there is 'change' notification for keyboard (after 'show') with beginning frame's origin.y equal to screen height.
                //so, if origin.y == to height of the screen, that means that we're dealing with such situation (since this method handles kb frame changes only) - we don't want to handle this as we would end up with duplicated inset (we already calculated inset after 'show' notification)
                return 0.0
            } else {
                keyboardHeightDifference = beginKeyboardRect.origin.y - endKeyboardRect.origin.y
            }
        }

        return keyboardHeightDifference
    }

    private func getBottomInsetChangeForKeyboardShown(keyboardRect: CGRect) -> CGFloat {
        var insetFix: CGFloat = 0.0
        if let initialBottomInset = initialContentInset?.bottom, shouldPreserveContentInset {
            insetFix = initialBottomInset
        }

        var bottomInsetDiff: CGFloat = 0.0

        switch mode {
        case .TableView:
            if let tableView = tableView {
                bottomInsetDiff = tableView.frame.maxY - keyboardRect.origin.y + insetFix - currentContentInset.bottom
            }
        case .ScrollView:
            if let scrollView = scrollView {
                bottomInsetDiff = scrollView.frame.maxY - keyboardRect.origin.y + insetFix - currentContentInset.bottom
            }
        }

        return bottomInsetDiff
    }

    private func getNewContentOffset(textFieldRect: CGRect, keyboardRect: CGRect) -> CGPoint? {
        let textFieldRectWithBottomSpace = CGRect(origin: textFieldRect.origin, size: CGSize(width: textFieldRect.width, height: textFieldRect.height + spaceBetweenEditableAndKeyboardTop))

        if textFieldRectWithBottomSpace.intersects(keyboardRect) {
            var contentOffset: CGPoint? = nil

            switch mode {
            case .TableView:
                if let tableView = tableView {
                    contentOffset = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + textFieldRectWithBottomSpace.maxY - keyboardRect.origin.y)
                }
            case .ScrollView:
                if let scrollView = scrollView {
                    contentOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + textFieldRectWithBottomSpace.maxY - keyboardRect.origin.y)
                }
            }
            return contentOffset
        } else {
            return nil
        }
    }

    private func registerForNotifications() {
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidShow), name: .UIKeyboardDidShow, object: nil)

        notificationCenter.addObserver(self, selector: #selector(keyboardDidChange), name: .UIKeyboardDidChangeFrame, object: nil)

        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidHide), name: .UIKeyboardDidHide, object: nil)

        notificationCenter.addObserver(self, selector: #selector(didBeginEditing), name: .UITextViewTextDidBeginEditing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(didEndEditing), name: .UITextViewTextDidEndEditing, object: nil)

        notificationCenter.addObserver(self, selector: #selector(didBeginEditing), name: .UITextFieldTextDidBeginEditing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(didEndEditing), name: .UITextFieldTextDidEndEditing, object: nil)
    }

    @objc func didBeginEditing(notification: Notification) {
        currentFirstResponder = notification.object as? UIView
    }

    @objc func didEndEditing(notification: Notification) {
        currentFirstResponder = nil
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

    private enum Mode {
        case TableView
        case ScrollView
    }
}
