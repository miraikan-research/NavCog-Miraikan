//
//
//  TabController.swift
//  NavCogMiraikan
//
/*******************************************************************************
 * Copyright (c) 2022 © Miraikan - The National Museum of Emerging Science and Innovation  
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *******************************************************************************/

import Foundation
import UIKit

/**
 Tabs for Home, Login and others
 */
class TabController: UITabBarController, UITabBarControllerDelegate {

    private var voiceGuideButton = VoiceGuideButton()
    private var logButton = LocationRecordingButton()
    private var locationButton = LocationInputButton()
    private var locationInputView = LocationInputView()
    var observer: NSKeyValueObservation?
    var debugObserver: NSKeyValueObservation?
    var debugLocationObserver: NSKeyValueObservation?
    var locationObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self

        let tabs = TabItem.allCases.filter({ item in
            if MiraikanUtil.isLoggedIn {
                return item != .login
            }
            return true
        })

        self.viewControllers = tabs.map({ $0.vc })
        self.selectedIndex = tabs.firstIndex(where: { $0 == .home })!
        if let items = self.tabBar.items {
            for (i, t) in tabs.enumerated() {
                items[i].title = t.title
                items[i].accessibilityLabel = t.accessibilityTitle
                items[i].image = UIImage(named: t.imgName)
            }
        }

        AudioGuideManager.shared.active()
        AudioGuideManager.shared.isActive(UserDefaults.standard.bool(forKey: "isVoiceGuideOn"))
        setLayerButton()
        setKVO()
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let navigationController = viewController as? UINavigationController {
            navigationController.popToRootViewController(animated: true)
        } else if let navigationController = viewController as? BaseTabController {
            navigationController.popToRootViewController(animated: true)
        }
        return true
    }

    private func setKVO() {
        observer = AudioGuideManager.shared.observe(\.isDisplay,
                                                     options: [.initial, .new],
                                                     changeHandler: { [weak self] (defaults, change) in
            guard let self = self else { return }
            if let change = change.newValue {
                self.voiceGuideButton.isDisplayButton(change)
            }
        })
        
        locationObserver = UserDefaults.standard.observe(\.isLocationInput, options: [.initial, .new], changeHandler: { [weak self] (defaults, change) in
            guard let self = self else { return }
            if let change = change.newValue {
                self.locationInputView.isDisplayButton(change)
            }
        })

        debugObserver = UserDefaults.standard.observe(\.DebugMode, options: [.initial, .new], changeHandler: { [weak self] (defaults, change) in
            guard let self = self else { return }
            if let change = change.newValue {
                UserDefaults.standard.set(false, forKey: "isMoveLogStart")
                self.logButton.isDisplayButton(change)
            }
        })

        debugLocationObserver = UserDefaults.standard.observe(\.DebugLocationInput, options: [.initial, .new], changeHandler: { [weak self] (defaults, change) in
            guard let self = self else { return }
            if let change = change.newValue {
                self.locationButton.isDisplayButton(change)
                if !change {
                    let center = NotificationCenter.default
                    center.post(name: NSNotification.Name(rawValue: "request_location_restart"), object: self)
                }
            }
        })
    }

    private func setLayerButton() {
        var rightPadding: CGFloat = 0
        var leftPadding: CGFloat = 0
        var bottomPadding: CGFloat = 0
        if let window = UIApplication.shared.windows.first {
            rightPadding = window.safeAreaInsets.right
            leftPadding = window.safeAreaInsets.left
            bottomPadding = window.safeAreaInsets.bottom
        }

        let tabHeight = self.tabBar.frame.height
        
        voiceGuideButton.frame = CGRect(x: UIScreen.main.bounds.width - 100 - rightPadding,
                                        y: UIScreen.main.bounds.height - 90 - tabHeight - bottomPadding,
                                        width: 80,
                                        height: 80)
        self.view.addSubview(voiceGuideButton)

        logButton.frame = CGRect(x: UIScreen.main.bounds.width - 100 - 10 - 60 - rightPadding,
                                 y: UIScreen.main.bounds.height - 90 + 10 - tabHeight - bottomPadding,
                                 width: 60,
                                 height: 60)
        self.view.addSubview(logButton)
        
        locationButton.frame = CGRect(x: leftPadding + leftPadding + 100,
                                      y: UIScreen.main.bounds.height - 90 + 10 - tabHeight - bottomPadding,
                                      width: 60,
                                      height: 60)
        self.view.addSubview(locationButton)

        locationInputView.frame = CGRect(x: 0,
                                         y: 0,
                                         width: 360,
                                         height: 440)
        locationInputView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3)
        self.view.addSubview(locationInputView)
    }
}


extension UserDefaults {
    @objc dynamic var isMoveLogStart: Bool {
        return Bool("isMoveLogStart") ?? false
    }

    @objc dynamic var isLocationInput: Bool {
        return Bool("isLocationInput") ?? false
    }

    @objc dynamic var DebugMode: Bool {
        return Bool("DebugMode") ?? false
    }

    @objc dynamic var DebugLocationInput: Bool {
        return Bool("DebugLocationInput") ?? false
    }
}
