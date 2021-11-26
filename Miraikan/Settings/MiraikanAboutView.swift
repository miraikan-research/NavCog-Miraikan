//
//  ExhibitionView.swift
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
import WebKit

/**
 The WebView retrieved from Miraikan About page
 */
class MiraikanAboutView: BaseView, WKNavigationDelegate {
    
    private let btnNavi = NaviButton()
    private let webView = WKWebView()
    private let lblLoading = UILabel()
    
    private let gap = CGFloat(10)
    
    override func setup() {
        super.setup()
        
        let url = URL(string: "\(MiraikanUtil.miraikanHost)/aboutus/")
        let req = URLRequest(url: url!)
        webView.navigationDelegate = self
        webView.load(req)
        addSubview(webView)
        
        // Display: Loading
        lblLoading.sizeToFit()
        addSubview(lblLoading)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Loading
        lblLoading.center = CGPoint(x: frame.midX, y: frame.midY)
        
        // Loaded
        webView.frame = CGRect(x: insets.left,
                               y: insets.top,
                               width: innerSize.width,
                               height: innerSize.height)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        lblLoading.text = "Loading"
        lblLoading.sizeToFit()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        lblLoading.text = ""
        
        let jsClearHeader = "document.getElementsByTagName('header')[0].innerHTML = '';"
        let jsClearFooter = "document.getElementsByTagName('footer')[0].innerHTML = '';"
        let js = "\(jsClearHeader)\(jsClearFooter)"
        webView.evaluateJavaScript(js, completionHandler: {(html, err) in
            if let e = err {
                print(e.localizedDescription)
            }
        })
    }
    
    
    
}
