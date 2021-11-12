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

// Layout for exhibition details
class ExhibitionView: BaseView, WKNavigationDelegate {
    
    private let btnNavi = NaviButton()
    private let webView = WKWebView()
    private let lblLoading = UILabel()
    
    private let gap = CGFloat(10)
    
    private let id: String?
    private var nodeId: String?
    private var isPreview: Bool?
    
    init(category: String, id: String, nodeId: String?) {
        self.id = id
        self.nodeId = nodeId
        super.init(frame: .zero)
        let address = "\(Host.miraikan.address)/exhibitions/\(category)/\(id)/"
        loadContent(address)
    }
    
    init(permalink: String) {
        self.id = nil
        super.init(frame: .zero)
        let address = "\(Host.miraikan.address)/\(permalink)"
        loadContent(address)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadContent(_ address: String) {
        
        if MiraikanUtil.routeMode == .blind {
            // TODO: Add description for Blind node when available
            return
        }
        
        webView.navigationDelegate = self
        addSubview(webView)
        
        let url = URL(string: address)
        let req = URLRequest(url: url!)
        webView.load(req)
    }
    
    override func setup() {
        super.setup()
        btnNavi.setTitle("この展示へナビ", for: .normal)
        btnNavi.sizeToFit()
        btnNavi.tapInside({ [weak self] _ in
            guard let _self = self else { return }
            if let n = _self.navVC {
                if let nodeId = _self.nodeId {
                    n.openMap(nodeId: nodeId)
                }
                if let locations = ExhibitionDataStore.shared.exhibitions?
                    .first(where: { $0.id == _self.id })?.locations {
                    let vc = FloorSelectionController(title: n.title)
                    vc.items = [0: locations]
                    n.show(vc, sender: nil)
                }
            }
        })
        addSubview(btnNavi)
        
        // Display: Loading
        lblLoading.sizeToFit()
        addSubview(lblLoading)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        btnNavi.frame = CGRect(x: insets.left,
                               y: y,
                               width: btnNavi.intrinsicContentSize.width + btnNavi.paddingX,
                               height: btnNavi.intrinsicContentSize.height)
        y += btnNavi.frame.height + gap
        
        // Loading
        lblLoading.center = CGPoint(x: frame.midX, y: frame.midY)
        
        // Loaded
        webView.frame = CGRect(x: insets.left,
                               y: y,
                               width: innerSize.width,
                               height: innerSize.height - y)
    }
    
    // MARK: WKNavigationDelegate
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
