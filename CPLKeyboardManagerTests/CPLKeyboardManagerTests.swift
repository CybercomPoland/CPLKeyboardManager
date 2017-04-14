//
//  CPLKeyboardManagerTests.swift
//  CPLKeyboardManagerTests
//
//  Created by Michal Zietera on 12.04.2017.
//  Copyright © 2017 Cybercom Poland. All rights reserved.
//

import XCTest
@testable import CPLKeyboardManager
import Quick
import Nimble

class CPLKeyboardBaseSpec: QuickSpec {

    class CPLFakeKeyboardManagerBase : CPLKeyboardManagerBase {
        var willShowNotificationReceived = false
        var didShowNotificationReceived = false
        var willChangeNotificationReceived = false
        var didChangeNotificationReceived = false
        var willHideNotificationReceived = false
        var didHideNotificationReceived = false
        //standard handlers flags
        var standardWillShowHandlerWasCalled = false
        var standardDidShowHandlerWasCalled = false
        var standardWillChangeHandlerWasCalled = false
        var standardDidChangeHandlerWasCalled = false
        var standardWillHideHandlerWasCalled = false
        var standardDidHideHandlerWasCalled = false

        override func keyboardWillShow(notification: Notification) {
            willShowNotificationReceived = true
            super.keyboardWillShow(notification: notification)
        }

        override func keyboardDidShow(notification: Notification) {
            didShowNotificationReceived = true
            super.keyboardDidShow(notification: notification)
        }

        override func keyboardWillChange(notification: Notification) {
            willChangeNotificationReceived = true
            super.keyboardWillChange(notification: notification)
        }

        override func keyboardDidChange(notification: Notification) {
            didChangeNotificationReceived = true
            super.keyboardDidChange(notification: notification)
        }

        override func keyboardWillHide(notification: Notification) {
            willHideNotificationReceived = true
            super.keyboardWillHide(notification: notification)
        }

        override func keyboardDidHide(notification: Notification) {
            didHideNotificationReceived = true
            super.keyboardDidHide(notification: notification)
        }

        override func handleKeyboardEvent(ofType type: KeyboardEventType, withKeyboardData keyboardData: KeyboardEventData) {
            switch type {
            case .willShow:
                standardWillShowHandlerWasCalled = true
            case .didShow:
                standardDidShowHandlerWasCalled = true
            case .willChange:
                standardWillChangeHandlerWasCalled = true
            case .didChange:
                standardDidChangeHandlerWasCalled = true
            case .willHide:
                standardWillHideHandlerWasCalled = true
            case .didHide:
                standardDidHideHandlerWasCalled = true
            }
        }
    }

    override func spec() {

        var window: UIWindow!

        let correctKeyboardNotificationUserInfo: [AnyHashable: Any] = [
            UIKeyboardFrameBeginUserInfoKey: CGRect(x: 0, y: 300, width: 200, height: 200),
            UIKeyboardFrameEndUserInfoKey: CGRect(x:0, y:100, width: 200, height: 200),
            UIKeyboardAnimationDurationUserInfoKey: NSNumber(value: 0.33),
            UIKeyboardAnimationCurveUserInfoKey: NSNumber(integerLiteral: 1)
        ]

        let textFieldWithoutAutocorrection = UITextField(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        textFieldWithoutAutocorrection.autocorrectionType = .no
        let textFieldWithAutocorrection = UITextField(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        textFieldWithAutocorrection.autocorrectionType = .yes

        var fakeKbManagerBase: CPLFakeKeyboardManagerBase!

        beforeEach {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            window = UIWindow()
            window.addSubview(view)
            view.addSubview(textFieldWithAutocorrection)
            view.addSubview(textFieldWithoutAutocorrection)

            fakeKbManagerBase = CPLFakeKeyboardManagerBase(view: view)
            fakeKbManagerBase.start()
            //RunLoop.current.run(until: Date())
        }

        afterEach {
            window = nil
            fakeKbManagerBase = nil
        }

        describe("when registered") {
            it("responds to all keyboard notifications", closure: {
                self.postAllKeyboardNotification()
                expect(fakeKbManagerBase.willShowNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.didShowNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.willChangeNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.didChangeNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.willHideNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.didHideNotificationReceived).to(beTrue())
            })
        }

        describe("when not registered") {
            it("doesn't respond to any keyboard notification", closure: {
                fakeKbManagerBase.unregisterFromNotifications()
                self.postAllKeyboardNotification()
                expect(fakeKbManagerBase.willShowNotificationReceived).to(beFalse())
                expect(fakeKbManagerBase.didShowNotificationReceived).to(beFalse())
                expect(fakeKbManagerBase.willChangeNotificationReceived).to(beFalse())
                expect(fakeKbManagerBase.didChangeNotificationReceived).to(beFalse())
                expect(fakeKbManagerBase.willHideNotificationReceived).to(beFalse())
                expect(fakeKbManagerBase.didHideNotificationReceived).to(beFalse())
            })
        }

        describe("when tracking is enabled") {
            it("handles correct keyboard notification", closure: {
                fakeKbManagerBase.start()
                self.postAllKeyboardNotification(withUserInfo: correctKeyboardNotificationUserInfo)
                expect(fakeKbManagerBase.standardWillShowHandlerWasCalled).to(beTrue())
                expect(fakeKbManagerBase.standardDidShowHandlerWasCalled).to(beTrue())
                expect(fakeKbManagerBase.standardWillChangeHandlerWasCalled).to(beTrue())
                expect(fakeKbManagerBase.standardDidChangeHandlerWasCalled).to(beTrue())
                expect(fakeKbManagerBase.standardWillHideHandlerWasCalled).to(beTrue())
                expect(fakeKbManagerBase.standardDidHideHandlerWasCalled).to(beTrue())
            })
        }

        describe("when tracking is disabled") {
            it("doesn't handle correct keyboard notification", closure: {
                fakeKbManagerBase.stop()
                self.postAllKeyboardNotification(withUserInfo: correctKeyboardNotificationUserInfo)
                expect(fakeKbManagerBase.standardWillShowHandlerWasCalled).to(beFalse())
                expect(fakeKbManagerBase.standardDidShowHandlerWasCalled).to(beFalse())
                expect(fakeKbManagerBase.standardWillChangeHandlerWasCalled).to(beFalse())
                expect(fakeKbManagerBase.standardDidChangeHandlerWasCalled).to(beFalse())
                expect(fakeKbManagerBase.standardWillHideHandlerWasCalled).to(beFalse())
                expect(fakeKbManagerBase.standardDidHideHandlerWasCalled).to(beFalse())
            })
        }

        describe("isKeyboardFrameSame") {
            var beginFrame: CGRect!
            var endFrame: CGRect!

            context("when begin height is equal to end height", {
                beforeEach {
                    beginFrame = CGRect(x: 0, y: 300, width: 200, height: 200)
                    endFrame = CGRect(x: 0, y: 300, width: 200, height: 200)
                }

                describe("when end height is equal to stored one", {
                    it("returns true", closure: {
                        fakeKbManagerBase.currentKeyboardHeight = endFrame.height
                        let result = fakeKbManagerBase.isKeyboardFrameSame(beginRect: beginFrame, endRect: endFrame)
                        expect(result).to(beTrue())
                    })
                })

                describe("end height is not equal to stored one", {
                    it("returns false", closure: {
                        fakeKbManagerBase.currentKeyboardHeight = endFrame.height + 100
                        let result = fakeKbManagerBase.isKeyboardFrameSame(beginRect: beginFrame, endRect: endFrame)
                        expect(result).to(beFalse())
                    })
                })
            })

            context("when begin height is not equal to end height", {
                beforeEach {
                    beginFrame = CGRect(x: 0, y: 300, width: 200, height: 200)
                    endFrame = CGRect(x: 0, y: 200, width: 200, height: 300)
                }

                describe("end height is equal to stored one", {
                    it("returns false", closure: {
                        fakeKbManagerBase.currentKeyboardHeight = endFrame.height
                        let result = fakeKbManagerBase.isKeyboardFrameSame(beginRect: beginFrame, endRect: endFrame)
                        expect(result).to(beFalse())
                    })
                })

                describe("end height is not equal to stored one", {
                    it("returns false", closure: {
                        fakeKbManagerBase.currentKeyboardHeight = endFrame.height + 100
                        let result = fakeKbManagerBase.isKeyboardFrameSame(beginRect: beginFrame, endRect: endFrame)
                        expect(result).to(beFalse())
                    })
                })
            })
        }
    }

    func postAllKeyboardNotification(withUserInfo userInfo: [AnyHashable: Any]? = nil) {
        let notifCenter = NotificationCenter.default
        notifCenter.post(name: NSNotification.Name.UIKeyboardWillShow, object: nil, userInfo: userInfo)
        notifCenter.post(name: NSNotification.Name.UIKeyboardDidShow, object: nil, userInfo: userInfo)
        notifCenter.post(name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil, userInfo: userInfo)
        notifCenter.post(name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil, userInfo: userInfo)
        notifCenter.post(name: NSNotification.Name.UIKeyboardWillHide, object: nil, userInfo: userInfo)
        notifCenter.post(name: NSNotification.Name.UIKeyboardDidHide, object: nil, userInfo: userInfo)
    }
}
