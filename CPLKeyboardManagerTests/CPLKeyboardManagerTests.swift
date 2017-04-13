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

        describe("When willShow notification was send") {
            it("should execute standard willShow and didShow handler", closure: {
                textFieldWithoutAutocorrection.becomeFirstResponder()

                //RunLoop.current.run(until: Date())
                expect(fakeKbManagerBase.standardWillShowHandlerWasCalled).to(beTrue())

                //RunLoop.current.run(until: Date().addingTimeInterval(1.0))
                expect(fakeKbManagerBase.standardDidShowHandlerWasCalled).to(beTrue())
                textFieldWithoutAutocorrection.resignFirstResponder()
               // RunLoop.current.run(until: Date().addingTimeInterval(4.0))
            })

            it("should execute standard willChange and didChange handler", closure: {
                textFieldWithAutocorrection.becomeFirstResponder()

                expect(fakeKbManagerBase.standardWillChangeHandlerWasCalled).to(beTrue())
                expect(fakeKbManagerBase.standardDidChangeHandlerWasCalled).to(beTrue())
            })
        }

        describe("If registered") {
            it("should respond to all keyboard notifications", closure: {
                self.postAllKeyboardNotification()
                expect(fakeKbManagerBase.willShowNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.didShowNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.willChangeNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.didChangeNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.willHideNotificationReceived).to(beTrue())
                expect(fakeKbManagerBase.didHideNotificationReceived).to(beTrue())
            })
        }

        describe("If not registered") {
            it("should not respond to any keyboard notification", closure: {
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

        describe("If tracking is enabled") { 
            it("should handle correct keyboard notification", closure: {

            })
        }

        describe("If tracking is disabled") { 
            it("should not handle correct keyboard notification", closure: { 
                
            })
        }
    }

    func postAllKeyboardNotification() {
        let notifCenter = NotificationCenter.default
        notifCenter.post(name: NSNotification.Name.UIKeyboardWillShow, object: nil, userInfo: nil)
        notifCenter.post(name: NSNotification.Name.UIKeyboardDidShow, object: nil, userInfo: nil)
        notifCenter.post(name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil, userInfo: nil)
        notifCenter.post(name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil, userInfo: nil)
        notifCenter.post(name: NSNotification.Name.UIKeyboardWillHide, object: nil, userInfo: nil)
        notifCenter.post(name: NSNotification.Name.UIKeyboardDidHide, object: nil, userInfo: nil)
    }
}



//class CPLKeyboardManagerTests: XCTestCase {
//    
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//    
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }
//    
//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//    
//}
