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
    let view: UIView

    ////CONFIGURATION////
    public var spaceBetweenEditableAndKeyboardTop: CGFloat = 15.0
    public var shouldPreserveContentInset = true
    public var defaultAnimationDuration: Double = 0.25 //used when duration is not provided in userInfo
    public var keyboardDismissMode: UIScrollViewKeyboardDismissMode = .interactive
    ////CONFIGURATION////

    private var mode: Mode
    private var keyboardState: KeyboardState = .Hidden
    private var isTracking: Bool = false

    private var currentFirstResponder: UIView? = nil

    private var initialContentInset: UIEdgeInsets? = nil
    private var currentContentInset: UIEdgeInsets

    //In some cases KbEndFrame is the same as KBbeginFrame despite beign actually different (for example user taps on search bar and bar with predictions disappears)
    //This property is used to additionaly keep track of height
    private var currentKeyboardHeight: CGFloat = 0.0

    public init(tableView: UITableView, inViewController viewController: UIViewController) {
        self.currentContentInset = tableView.contentInset
        self.tableView = tableView
        self.tableView?.keyboardDismissMode = keyboardDismissMode
        self.scrollView = nil
        self.mode = .TableView
        self.view = viewController.view
        self.commonInit()
    }

    public init(scrollView: UIScrollView, inViewController viewController: UIViewController) {
        self.currentContentInset = scrollView.contentInset
        self.tableView = nil
        self.scrollView = scrollView
        self.scrollView?.keyboardDismissMode = keyboardDismissMode
        self.mode = .ScrollView
        self.view = viewController.view
        self.commonInit()
    }

    private func commonInit() {
        self.registerForNotifications()
        self.isTracking = false
    }

    public func start() {
        self.isTracking = true
    }

    public func stop() {
        self.isTracking = false
    }

    deinit {
        self.unregisterFromNotifications()
    }

    @objc func keyboardWillShow(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification), isTracking else {
            return
        }

        if shouldProcess(givenKeyboardEvent: .WillShow, andKeyboardEventData: keyboardData) {
            handleKeyboardEvent(ofType: .WillShow, withKeyboardEventData: keyboardData)
        }
    }

    @objc func keyboardDidShow(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification), isTracking else {
            return
        }

        if shouldProcess(givenKeyboardEvent: .DidShow, andKeyboardEventData: keyboardData) {
            handleKeyboardEvent(ofType: .DidShow, withKeyboardEventData: keyboardData)
        }
    }

    @objc func keyboardDidChange(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification), isTracking else {
            return
        }

    }

    @objc func keyboardWillHide(notification: Notification) {
        guard let keyboardData = KeyboardEventData(notification: notification), isTracking else {
            return
        }

        let contentInset = initialContentInset ?? UIEdgeInsets.zero
        var duration = keyboardData.duration.doubleValue
        if duration == 0.0 {
            duration = defaultAnimationDuration
        }

        performAnimation(withDuration: duration, andOptions: keyboardData.getDefaultAnimationOptions(), newBottomContentInset: contentInset.bottom, newContentOffset: nil, completion: nil)

        currentContentInset = contentInset
        keyboardState = .Hidden
        currentKeyboardHeight = 0.0
        initialContentInset = nil
    }

    //TextView should be processed in Didxxxxx series of keyboard events (due to incorrect selectedRange value during willxxxxx events)
    private func shouldProcess(givenKeyboardEvent event: KeyboardEventType, andKeyboardEventData keyboardData: KeyboardEventData) -> Bool {

        guard let currentFirstResponder = currentFirstResponder else {
            return false
        }

        let convertedBeginKeyboardRect = convertRect(rect: keyboardData.beginKeyboardRect, toView: view, fromView: view.window)
        let convertedEndKeyboardRect = convertRect(rect: keyboardData.endKeyboardRect, toView: view, fromView: view.window)

        //TODO: if not local - should slide whole view
//        if #available(iOS 9.0, *) {
//            if let keyboardLocal = userInfo[UIKeyboardIsLocalUserInfoKey] as? Bool, !keyboardLocal {
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
            if isKeyboardBeingHidden(beginRect: beginKeyboardRect, endRect: endKeyboardRect) { //somtimes endKB == 0 for some reason for 3rd party keyboards
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

    private func handleKeyboardEvent(ofType type: KeyboardEventType,  withKeyboardEventData keyboardData: KeyboardEventData) {
        guard let currentFirstResponderView = currentFirstResponder else {
            return
        }

        let convertedBeginKeyboardRect = view.convert(keyboardData.beginKeyboardRect, from: view.window)
        let convertedEndKeyboardRect = view.convert(keyboardData.endKeyboardRect, from: view.window)
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

        let options = keyboardData.getDefaultAnimationOptions()
        let durationValue = keyboardData.duration.doubleValue == 0.0 ? defaultAnimationDuration : keyboardData.duration.doubleValue

        performAnimation(withDuration: durationValue, andOptions: options, newBottomContentInset: currentContentInset.bottom, newContentOffset: newContentOffset, completion: { [weak self] in

            switch type {
            case .WillShow, .DidShow:
                self?.keyboardState = .Shown
            case .WillChange, .DidChange:
                break
            }
        })
    }

    private func performAnimation(withDuration duration: Double, andOptions options: UIViewAnimationOptions, newBottomContentInset: CGFloat, newContentOffset: CGPoint?, completion: (() -> Void)?) {

        UIView.animate(withDuration: duration, delay: 0.0, options: options, animations: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            switch strongSelf.mode {
            case .TableView:
                strongSelf.tableView?.contentInset.bottom = newBottomContentInset
                strongSelf.tableView?.scrollIndicatorInsets.bottom = newBottomContentInset
            case .ScrollView:
                strongSelf.scrollView?.contentInset.bottom = newBottomContentInset
                strongSelf.scrollView?.scrollIndicatorInsets.bottom = newBottomContentInset
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
            }, completion: { _ in completion?() })
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
                if lowestTextSelectionRect.rect.origin.y == CGFloat.infinity ||
                    lowestTextSelectionRect.rect.origin.x == CGFloat.infinity {
                    //carret is in the end of textView
                    if let lastPosition = textView.position(from: textView.endOfDocument, offset: 0),
                        let oneBeforeLastPosition = textView.position(from: textView.endOfDocument, offset: -1),
                        let range = textView.textRange(from: oneBeforeLastPosition, to: lastPosition) {
                        let lastCharRect = textView.firstRect(for: range)
                        let lastCharConvertedRect = view.convert(lastCharRect, from: textView)

                        let lastCharRectCorrected = getCorrectedRectForUITextView(selectionRect: lastCharConvertedRect, textView: textView)

                        return lastCharRectCorrected
                    }
                } else {
                    let convertedLowestRect = view.convert(lowestTextSelectionRect.rect, from: textView)
                    let lowestRectCorrected = getCorrectedRectForUITextView(selectionRect: convertedLowestRect, textView: textView)
                    return lowestRectCorrected
                }
            }
        }
        return convertedRect
    }

    //This method ensures that contentOffset of textView doesn't affect contentOffset of wrapping scrollView (by changing origin.y of selection rect to match bounds of textview)
    //For example when users selects text, then scrolls textView up so selection is below it's bounds, then rotates - we scroll main scrollView to selection but we don't want to scroll it further than bottom of this textView + specified margin
    private func getCorrectedRectForUITextView(selectionRect: CGRect, textView: UITextView) -> CGRect {
        let convertedTextViewFrame = view.convert(textView.frame, from: textView.superview)

        var newY: CGFloat? = nil

        if selectionRect.maxY > convertedTextViewFrame.maxY {
            newY = convertedTextViewFrame.maxY - selectionRect.height - textView.layoutMargins.bottom - textView.contentInset.bottom
        } else if selectionRect.minY < convertedTextViewFrame.minY {
            newY = convertedTextViewFrame.minY
        }

        if let newY = newY {
            let correctedRect = CGRect(x: selectionRect.origin.x, y: newY, width: selectionRect.width, height: selectionRect.height)
            return correctedRect
        } else {
            return selectionRect
        }
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
            keyboardHeightDifference = beginKeyboardRect.origin.y - endKeyboardRect.origin.y
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
        let newOrigin = CGPoint(x: textFieldRect.origin.x, y: textFieldRect.origin.y - spaceBetweenEditableAndKeyboardTop)
        let textFieldRectWithBottomAndUpperSpace = CGRect(origin: newOrigin, size: CGSize(width: textFieldRect.width, height: textFieldRect.height + 2*spaceBetweenEditableAndKeyboardTop))

        var scrollViewRectConverted: CGRect!

        switch mode {
        case .TableView:
            if let tableView = tableView {
                scrollViewRectConverted = view.convert(tableView.frame, from: tableView.superview)
            }
        case .ScrollView:
            if let scrollView = scrollView {
                scrollViewRectConverted = view.convert(scrollView.frame, from: scrollView.superview)
            }
        }

        var contentOffset: CGPoint? = nil
        var maxContentOffset: CGPoint? = nil

        if textFieldRectWithBottomAndUpperSpace.intersects(keyboardRect) ||
            textFieldRectWithBottomAndUpperSpace.maxY > keyboardRect.maxY { //rotation case

            switch mode {
            case .TableView:
                if let tableView = tableView {
                    contentOffset = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + textFieldRectWithBottomAndUpperSpace.maxY - keyboardRect.origin.y)
                    maxContentOffset = CGPoint(x: tableView.contentOffset.x, y: tableView.contentSize.height - tableView.bounds.height)
                }
            case .ScrollView:
                if let scrollView = scrollView {
                    contentOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + textFieldRectWithBottomAndUpperSpace.maxY - keyboardRect.origin.y)
                    maxContentOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentSize.height - scrollView.bounds.height)
                }
            }
        } else if textFieldRectWithBottomAndUpperSpace.minY < scrollViewRectConverted.minY { //control is above view - we need to scroll it down
            let distanceBetweenViewTopAndTextFieldTop = scrollViewRectConverted.minY - textFieldRectWithBottomAndUpperSpace.minY
            switch mode {
            case .TableView:
                if let tableView = tableView {
                    contentOffset = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y - distanceBetweenViewTopAndTextFieldTop)
                }
            case .ScrollView:
                if let scrollView = scrollView {
                    contentOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y - distanceBetweenViewTopAndTextFieldTop)
                }
            }
        }

        if let _contentOffset = contentOffset {
            if _contentOffset.y < 0.0 {
                contentOffset?.y = 0.0
            } else if let _maxContentOffset = maxContentOffset, _contentOffset.y > _maxContentOffset.y {
                contentOffset?.y = _maxContentOffset.y
            }
        }

        return contentOffset
    }

    private func registerForNotifications() {
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidShow), name: .UIKeyboardDidShow, object: nil)

        notificationCenter.addObserver(self, selector: #selector(keyboardDidChange), name: .UIKeyboardDidChangeFrame, object: nil)

        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)

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

    private struct KeyboardEventData {
        let isLocal: Bool?
        let animationCurve: NSNumber
        let duration: NSNumber
        let beginKeyboardRect: CGRect
        let endKeyboardRect: CGRect

        init?(notification: Notification) {
            guard let userInfo = notification.userInfo,
            let beginKeyboardRect = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect,
                let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            else {
                return nil
            }

            if #available(iOS 9.0, *) {
                if let isLocal = userInfo[UIKeyboardIsLocalUserInfoKey] as? Bool {
                    self.isLocal = isLocal
                } else {
                    isLocal = nil
                }
            } else {
                isLocal = nil
            }

            self.animationCurve = animationCurve
            self.beginKeyboardRect = beginKeyboardRect
            self.endKeyboardRect = endKeyboardRect
            self.duration = duration
        }

        func getDefaultAnimationOptions() -> UIViewAnimationOptions {
            let animationOptions: UIViewAnimationOptions = [UIViewAnimationOptions(rawValue: animationCurve.uintValue << 16), .beginFromCurrentState, .allowUserInteraction]
            return animationOptions
        }
    }
}
