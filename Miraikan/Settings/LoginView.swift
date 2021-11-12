//
//  LoginView.swift
//  NavCogMiraikan
//
/*******************************************************************************
 * Copyright (c) 2021 © Miraikan - The National Museum of Emerging Science and Innovation
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

// Layout for login
class LoginView: BaseView {
    
    private let btnLogin = BaseButton()
    
    override func setup() {
        super.setup()
        
        btnLogin.setTitle("Login", for: .normal)
        btnLogin.setTitleColor(.black, for: .normal)
        btnLogin.sizeToFit()
        btnLogin.tapInside({ [weak self] _ in
            guard let _self = self else { return }
            
            UserDefaults.standard.setValue(true, forKey: "LoggedIn")
            
            // Remove the tab after login
            if let t = _self.tabVC,
               var tabs = t.viewControllers {
                tabs.remove(at: TabItem.login.rawValue)
                t.viewControllers = tabs
                t.selectedIndex = TabItem.home.rawValue
            }
            
            // Navigate to the Home view
            if let n = _self.navVC {
                n.show(BaseController(Home(), title: TabItem.home.title), sender: nil)
            }
        })
        
        addSubview(btnLogin)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        btnLogin.center = self.center
    }
}
