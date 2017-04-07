//
//  KeyboardEventData.swift
//  Pods
//
//  Created by Michal Zietera on 07.04.2017.
//
//

import Foundation

public struct KeyboardEventData {
    public let isLocal: Bool
    public let animationCurve: NSNumber
    public let duration: NSNumber
    public let beginKeyboardRect: CGRect
    public let endKeyboardRect: CGRect

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
                isLocal = true
            }
        } else {
            isLocal = true
        }

        self.animationCurve = animationCurve
        self.beginKeyboardRect = beginKeyboardRect
        self.endKeyboardRect = endKeyboardRect
        self.duration = duration
    }

    public func getDefaultAnimationOptions() -> UIViewAnimationOptions {
        let animationOptions: UIViewAnimationOptions = [UIViewAnimationOptions(rawValue: animationCurve.uintValue << 16), .beginFromCurrentState, .allowUserInteraction]
        return animationOptions
    }

    public func getDuration(usingDefaultValue defVal: Double) -> Double {
        if duration == 0.0 {
            return defVal
        } else {
            return duration.doubleValue
        }
    }
}
