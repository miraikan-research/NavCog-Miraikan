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

    private var voiceGuideButton = UIButton()
    private var isDisplayButton = false
    var observer: NSKeyValueObservation?

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
        setVoiceGuideButton()
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
                self.isDisplayButton(change)
            }
        })
    }

    private func setVoiceGuideButton() {
        var rightPadding: CGFloat = 0
        var bottomPadding: CGFloat = 0
        if let window = UIApplication.shared.windows.first {
            rightPadding = window.safeAreaInsets.right
            bottomPadding = window.safeAreaInsets.bottom
        }

        let tabHeight = self.tabBar.frame.height
        
        // Temporary design
        voiceGuideButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 100 - rightPadding,
                                                  y: UIScreen.main.bounds.height - 90 - tabHeight - bottomPadding,
                                                  width: 80,
                                                  height: 80))
        voiceGuideButton.backgroundColor = .white
        voiceGuideButton.layer.cornerRadius = 30

        voiceGuideButton.layer.borderColor = UIColor(red: 105/255, green: 0, blue: 50/255, alpha: 1).cgColor
        voiceGuideButton.layer.borderWidth = 6.0

        voiceGuideButton.layer.shadowColor = UIColor.black.cgColor
        voiceGuideButton.layer.shadowOpacity = 0.3
        voiceGuideButton.layer.shadowRadius = 5.0
        voiceGuideButton.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)

        voiceGuideButton.titleLabel?.numberOfLines = 0

        voiceGuideButton.setTitleColor(.black, for: .normal)
        voiceGuideButton.setTitle(NSLocalizedString("Voice Guide Off", comment: ""), for: .normal)
        voiceGuideButton.setTitle(NSLocalizedString("Voice Guide On", comment: ""), for: .selected)
        voiceGuideButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
        voiceGuideButton.titleLabel?.textAlignment = .center

        voiceGuideButton.setImage(UIImage(named: "icons8-mute-24"), for: .normal)
        voiceGuideButton.setImage(UIImage(named: "icons8-sound-24"), for: .selected)
        
        voiceGuideButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 30, right: 0)
        voiceGuideButton.titleEdgeInsets = UIEdgeInsets(top: 30, left: -20, bottom: 0, right: 0)

        voiceGuideButton.addTarget(self, action: #selector(self.buttonTapped(_:)), for: .touchUpInside)

        voiceGuideButton.isSelected = UserDefaults.standard.bool(forKey: "isVoiceGuideOn")

        self.view.addSubview(voiceGuideButton)
    }

    @objc func buttonTapped(_ sender: UIButton) {
        let isOn = !sender.isSelected
        sender.isSelected = isOn
        UserDefaults.standard.set(isOn, forKey: "isVoiceGuideOn")
        AudioGuideManager.shared.isActive(isOn)
    }

    func isDisplayButton(_ isDisplay: Bool) {
        if (voiceGuideButton.alpha == 1) == isDisplay {
            return
        }

        DispatchQueue.main.async{
            self.voiceGuideButton.alpha = isDisplay ? 0 : 1
            UIView.animate(withDuration: 0.1, animations: { [weak self] in
                guard let self = self else { return }
                self.voiceGuideButton.alpha = isDisplay ? 1 : 0
            })
        }
    }
}
