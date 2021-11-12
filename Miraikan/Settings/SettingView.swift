//
//  SettingView.swift
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
 Caution: This is related to but not the same as the modes in NavCog3
 */
enum RouteMode : String, CaseIterable {
    case general
    case wheelchair
    case blind
    
    var description: String {
        switch self {
        case .general:
            return "一般モード"
        case .wheelchair:
            return "車椅子モード"
        case .blind:
            return "視覚障害者モード"
        }
    }
}

// TODO: Display route histories
/**
 Current usage: select navigation mode
 */
class SettingView: BaseView {
    
    private var radioGroup = [RouteMode: RadioButton]()
    
    override func setup() {
        super.setup()
        
        RouteMode.allCases.forEach({ mode in
            let btn = RadioButton()
            btn.setTitle(mode.description, for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.isChecked = mode == MiraikanUtil.routeMode
            btn.tapInside({ [weak self] _ in
                guard let _self = self else { return }
                if !btn.isChecked {
                    btn.isChecked = true
                    _self.radioGroup.forEach({
                        let (k, v) = ($0.key, $0.value)
                        if k != mode { v.isChecked = false }
                    })
                    UserDefaults.standard.setValue(mode.rawValue, forKey: "RouteMode")
                }
            })
            
            radioGroup[mode] = btn
            addSubview(btn)
        })
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let gap = CGFloat(10)
        var y = insets.top
        RouteMode.allCases.forEach({ mode in
            let btn = radioGroup[mode]!
            btn.frame = CGRect(origin: CGPoint(x: insets.left, y: y),
                               size: btn.sizeThatFits(innerSize))
            y += btn.frame.height + gap
        })
    }
    
}
