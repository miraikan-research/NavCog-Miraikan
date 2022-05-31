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

/**
 Tabs for Home, Login and others
 */
class TabController: UITabBarController, UITabBarControllerDelegate {

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
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let navigationController = viewController as? UINavigationController {
            navigationController.popToRootViewController(animated: true)
        } else if let navigationController = viewController as? BaseTabController {
            navigationController.popToRootViewController(animated: true)
        }
        return true
    }
}
