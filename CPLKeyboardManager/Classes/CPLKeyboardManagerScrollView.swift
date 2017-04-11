//
//  CPLKeyboardManagerScrollView.swift
//  Pods
//
//  Created by Michal Zietera on 17.03.2017.
//
//

import Foundation

internal class CPLKeyboardManagerScrollView: CPLKeyboardManagerBase {
    //implicitly unwrapped optionals, to keep code cleaner. It is safe because we use init to set mode of keyboard manager
    private let tableView: UITableView!
    private let scrollView: UIScrollView!

    private var mode: Mode

    private var initialContentInset: UIEdgeInsets? = nil
    private var previousContentOffset: CGPoint
    private var firstResponderBelongsToScrollView: Bool = false
    private var shouldSetOffsetInCompletion = false

    internal init(tableView: UITableView, inViewController viewController: UIViewController) {
        self.mode = .TableView
        self.previousContentOffset = tableView.contentOffset
        self.tableView = tableView
        self.scrollView = nil
        super.init(view: viewController.view)
    }

    public init(scrollView: UIScrollView, inViewController viewController: UIViewController) {
        self.mode = .ScrollView
        self.previousContentOffset = scrollView.contentOffset
        self.tableView = nil
        self.scrollView = scrollView
        super.init(view: viewController.view)
    }

    override func didBeginEditing(notification: Notification) {
        super.didBeginEditing(notification: notification)
        self.firstResponderBelongsToScrollView = isFirstResponderChildOfScrollView()
    }

    //TextView should be processed in Didxxxxx series of keyboard events (due to incorrect selectedRange value during willxxxxx events)
    internal override func shouldProcess(givenKeyboardEvent event: KeyboardEventType, andKeyboardEventData keyboardData: KeyboardEventData) -> Bool {
        if !isTracking {
            return false
        }

        if keyboardData.isLocal {
            guard let currentFirstResponder = self.currentFirstResponder else {
                return false
            }

            let isResponderTextView = currentFirstResponder.isKind(of: UITextView.self)

            if isResponderTextView {
                switch event {
                case .didShow, .willHide:
                    return true
                case .willShow, .willChange, .didChange, .didHide:
                    return false
                }
            } else {
                switch event {
                case .willShow, .willHide:
                    return true
                case .didShow, .didChange, .willChange, .didHide:
                    return false
                }
            }
        } else {
            return true
        }
    }

    internal override func handleKeyboardEvent(ofType type: KeyboardEventType, withKeyboardData keyboardData: KeyboardEventData) {
        switch type {
        case .willShow, .didShow:
            handleKeyboardShowEvent(withKeyboardEventData: keyboardData)
        case .willHide:
            handleKeyboardHideEvent(withKeyboardEventData: keyboardData)
        default:
            break
        }
    }

    private func handleKeyboardShowEvent(withKeyboardEventData keyboardData: KeyboardEventData) {

        if !keyboardData.isLocal {
            currentFirstResponder = nil //because didEndEditing in such case is later than willShow notif
        }

        let convertedEndKeyboardRect = view.convert(keyboardData.endKeyboardRect, from: view.window)
        currentKeyboardHeight = convertedEndKeyboardRect.height

        saveInitialContentInsetIfNeeded()
        let insetDifference = getBottomInsetChangeForKeyboardShown(keyboardRect: convertedEndKeyboardRect)

        var currentContentInsetBottom: CGFloat!
        switch mode {
        case .TableView:
            currentContentInsetBottom = tableView.contentInset.bottom
        case .ScrollView:
            currentContentInsetBottom = scrollView.contentInset.bottom
        }

        let newBottomContentInset = currentContentInsetBottom + insetDifference

        var newContentOffset: CGPoint? = nil

        if let currentFirstResponderView = currentFirstResponder, firstResponderBelongsToScrollView {
            let convertedFirstResponderRect = getRect(forGivenFirstResponder: currentFirstResponderView, convertedToCoordinatesSystemOf: view)
            newContentOffset = getNewContentOffset(textFieldRect: convertedFirstResponderRect, keyboardRect: convertedEndKeyboardRect, bottomInset: newBottomContentInset)
        }

        previousContentOffset = newContentOffset ?? previousContentOffset

        let options = keyboardData.getDefaultAnimationOptions()
        let durationValue = keyboardData.getDuration(usingDefaultValue: defaultAnimationDuration)

        performAnimation(withDuration: durationValue, andOptions: options, newBottomContentInset: newBottomContentInset, newContentOffset: newContentOffset, completion: { [weak self] in
            self?.keyboardState = .shown
        })
    }

    private func handleKeyboardHideEvent(withKeyboardEventData keyboardData: KeyboardEventData) {
        if keyboardState == .hidden {
            return
        }

        let contentInset = initialContentInset ?? UIEdgeInsets.zero
        let duration = keyboardData.getDuration(usingDefaultValue: defaultAnimationDuration)

        performAnimation(withDuration: duration, andOptions: keyboardData.getDefaultAnimationOptions(), newBottomContentInset: contentInset.bottom, newContentOffset: nil, completion: nil)

        keyboardState = .hidden
        initialContentInset = nil
    }

    private func performAnimation(withDuration duration: Double, andOptions options: UIViewAnimationOptions, newBottomContentInset: CGFloat, newContentOffset: CGPoint?, completion: (() -> Void)?) {

        super.performAnimation(withDuration: duration, andAnimationOptions: options, action: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            switch strongSelf.mode {
            case .TableView:
                strongSelf.tableView.contentInset.bottom = newBottomContentInset
                strongSelf.tableView.scrollIndicatorInsets.bottom = newBottomContentInset
            case .ScrollView:
                strongSelf.scrollView.contentInset.bottom = newBottomContentInset
                strongSelf.scrollView.scrollIndicatorInsets.bottom = newBottomContentInset
            }

            if !strongSelf.shouldSetOffsetInCompletion {
                if let contentOffset = newContentOffset,
                    let strongSelf = self {

                    switch strongSelf.mode {
                    case .TableView:
                        strongSelf.tableView.setContentOffset(contentOffset, animated: false)
                    case .ScrollView:
                        strongSelf.scrollView.setContentOffset(contentOffset, animated: false)
                    }
                }
            }
        }) {
            [weak self] finished in
            if let strongSelf = self,
                let newContentOffset = newContentOffset {
                if strongSelf.shouldSetOffsetInCompletion {

                    UIView.animate(withDuration: duration, delay: 0.0, options: options, animations: {
                        switch strongSelf.mode {
                        case .TableView:
                            strongSelf.tableView.setContentOffset(newContentOffset, animated: false)
                        case .ScrollView:
                            strongSelf.scrollView.setContentOffset(newContentOffset, animated: false)
                        }
                        strongSelf.shouldSetOffsetInCompletion = false
                    }, completion: nil)

                }
            }
            completion?()
        }
    }

    private func convertRect(rect: CGRect, toView: UIView, fromView: UIView?) -> CGRect {
        return toView.convert(rect, from: fromView)
    }

    private func getRect(forGivenFirstResponder firstResponder: UIView, convertedToCoordinatesSystemOf view: UIView) -> CGRect {
        let convertedRect = view.convert(firstResponder.frame, from: firstResponder.superview)

        if let textView = firstResponder as? UITextView,
            let selectedTextRange = textView.selectedTextRange,
            let selectionRects = textView.selectionRects(for: selectedTextRange) as? [UITextSelectionRect],
            let firstSelectionRect = selectionRects.first {

            let lowestTextSelectionRect = selectionRects.reduce(firstSelectionRect, { (firstRect, secondRect) -> UITextSelectionRect in
                return firstRect.rect.origin.y > secondRect.rect.origin.y ? firstRect : secondRect
            })

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
        return convertedRect
    }

    //This method ensures that position of selection in textView doesn't affect final contentOffset of wrapping scrollView (by changing origin.y of selection rect to match bounds of textview)
    //For example when users selects text, then scrolls textView up so selection is below it's bounds, then rotates - we scroll main scrollView to selection but we don't want to scroll it further than bottom of this textView + specified margin (without this fix it would because selection was beyond textView's bounds)
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
                initialContentInset = tableView.contentInset
            case .ScrollView:
                initialContentInset = scrollView.contentInset
            }
        }
    }

    private func getBottomInsetChangeForKeyboardShown(keyboardRect: CGRect) -> CGFloat {
        var insetFix: CGFloat = 0.0
        if let initialBottomInset = initialContentInset?.bottom, shouldPreserveContentInset {
            insetFix = initialBottomInset
        }

        var bottomInsetDiff: CGFloat = 0.0

        switch mode {
        case .TableView:
            bottomInsetDiff = tableView.frame.maxY - keyboardRect.origin.y + insetFix - tableView.contentInset.bottom
        case .ScrollView:
            bottomInsetDiff = scrollView.frame.maxY - keyboardRect.origin.y + insetFix - scrollView.contentInset.bottom
        }

        return bottomInsetDiff
    }

    private func isFirstResponderChildOfScrollView() -> Bool {
        var scrollView: UIView
        switch mode {
        case .ScrollView:
            scrollView = self.scrollView
        case .TableView:
            scrollView = self.tableView
        }

        var superView = currentFirstResponder?.superview
        while let _superView = superView {
            if _superView == scrollView {
                return true
            } else {
                superView = _superView.superview
            }
        }
        return false
    }

    private func getNewContentOffset(textFieldRect: CGRect, keyboardRect: CGRect, bottomInset: CGFloat) -> CGPoint? {
        let newOrigin = CGPoint(x: textFieldRect.origin.x, y: textFieldRect.origin.y - spaceBelowAndAboveEditable)
        let textFieldRectWithBottomAndUpperSpace = CGRect(origin: newOrigin, size: CGSize(width: textFieldRect.width, height: textFieldRect.height + 2*spaceBelowAndAboveEditable))

        var scrollViewRectConverted: CGRect!
        var currentContentOffset: CGPoint!
        var maxContentOffset: CGPoint!

        switch mode {
        case .TableView:
            scrollViewRectConverted = view.convert(tableView.frame, from: tableView.superview)
            currentContentOffset = tableView.contentOffset
            maxContentOffset = CGPoint(x: tableView.contentOffset.x, y: tableView.contentSize.height - (tableView.bounds.height - bottomInset))
        case .ScrollView:
            scrollViewRectConverted = view.convert(scrollView.frame, from: scrollView.superview)
            currentContentOffset = scrollView.contentOffset
            maxContentOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentSize.height - (scrollView.bounds.height - bottomInset))
        }

        var newContentOffset: CGPoint? = nil

        if textFieldRectWithBottomAndUpperSpace.intersects(keyboardRect) ||
            textFieldRectWithBottomAndUpperSpace.maxY > keyboardRect.maxY { //rotation case

            newContentOffset = CGPoint(x: currentContentOffset.x, y: currentContentOffset.y + textFieldRectWithBottomAndUpperSpace.maxY - keyboardRect.origin.y)
        } else if textFieldRectWithBottomAndUpperSpace.minY < scrollViewRectConverted.minY { //control is above view - we need to scroll it down

            let distanceBetweenViewTopAndTextFieldTop = scrollViewRectConverted.minY - textFieldRectWithBottomAndUpperSpace.minY
            newContentOffset = CGPoint(x: currentContentOffset.x, y: currentContentOffset.y - distanceBetweenViewTopAndTextFieldTop)
        }

        if let _newContentOffset = newContentOffset {
            if currentContentOffset.y < 0.0 {
                //we don't want to handle this immediately as it causes some weird animation issues
                shouldSetOffsetInCompletion = true
            }
            
            if _newContentOffset.y > maxContentOffset.y {
                newContentOffset?.y = maxContentOffset.y
            } else if _newContentOffset.y < 0.0 {
                newContentOffset?.y = 0.0
            }
        }
        
        return newContentOffset
    }
    
    private enum Mode {
        case TableView
        case ScrollView
    }
}
