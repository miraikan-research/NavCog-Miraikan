//
//  AppAboutView.swift
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

/**
 The about screen for this app.
 
 The copyright references should be placed here.
 */
class AppAboutView: BaseView {
    
    private let lblIcon8 = UILabel()
    private let lblVersion = UILabel()

    override func setup() {
        super.setup()
        
        lblIcon8.text = "Free Icons Retreived from: https://icons8.com for TabBar and NavBar."
        lblIcon8.numberOfLines = 0
        lblIcon8.lineBreakMode = .byWordWrapping
        lblIcon8.sizeToFit()
        addSubview(lblIcon8)

        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            lblVersion.text = "Version: \(version)    Buld: \(build)"
            lblVersion.numberOfLines = 0
            lblVersion.lineBreakMode = .byWordWrapping
            lblVersion.sizeToFit()
            addSubview(lblVersion)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var szFit = CGSize(width: innerSize.width, height: lblIcon8.intrinsicContentSize.height)
        lblIcon8.frame = CGRect(x: insets.left,
                                y: insets.top + 8,
                                width: innerSize.width,
                                height: lblIcon8.sizeThatFits(szFit).height)

        szFit = CGSize(width: innerSize.width, height: lblVersion.intrinsicContentSize.height)
        lblVersion.frame = CGRect(x: insets.left,
                                y: insets.top + 8 + lblIcon8.frame.height + 20,
                                width: innerSize.width,
                                height: lblVersion.sizeThatFits(szFit).height)
    }
}
