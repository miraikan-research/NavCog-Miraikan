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
            return NSLocalizedString("user_general", comment: "")
        case .wheelchair:
            return NSLocalizedString("user_wheelchair", comment: "")
        case .blind:
            return NSLocalizedString("user_blind", comment: "")
        }
    }
}

fileprivate class RouteModeRow: BaseRow {
    
    private var radioGroup = [RouteMode: RadioButton]()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        RouteMode.allCases.forEach({ mode in
            let btn = RadioButton()
            btn.setTitle(mode.description, for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.isChecked = mode == MiraikanUtil.routeMode
            btn.tapAction({ [weak self] _ in
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let gap: CGFloat = 10
        let innerSz = innerSizing(parentSize: size)
        let buttonHeight: [CGFloat] = RouteMode.allCases.map({ mode in
            guard let btn = radioGroup[mode] else { return 0 }
            return btn.sizeThatFits(innerSz).height
        })
        let heightList = [gap * 2] + buttonHeight
        let totalHeight = heightList.reduce((insets.top + insets.bottom), { $0 + $1})
        return CGSize(width: size.width, height: totalHeight)
    }
    
}

fileprivate class VoiceGuideRow : BaseRow {
    
    private let lblDescription = UILabel()
    private let swVoiceGuide = BaseSwitch()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        lblDescription.text = NSLocalizedString("Voice Guide", comment: "")
        lblDescription.font = .boldSystemFont(ofSize: 16)
        lblDescription.sizeToFit()
        addSubview(lblDescription)
        
        swVoiceGuide.isOn = UserDefaults.standard.bool(forKey: "isVoiceGuideOn")
        swVoiceGuide.onSwitch({ sw in
            UserDefaults.standard.set(sw.isOn, forKey: "isVoiceGuideOn")
        })
        swVoiceGuide.sizeToFit()
        addSubview(swVoiceGuide)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let midY = max(lblDescription.intrinsicContentSize.height,
                       swVoiceGuide.intrinsicContentSize.height) / 2 + insets.top
        lblDescription.frame.origin.x = insets.left
        lblDescription.center.y = midY
        swVoiceGuide.frame.origin.x = frame.width - insets.right - swVoiceGuide.frame.width
        swVoiceGuide.center.y = midY
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let totalHeight = [insets.top,
                           max(lblDescription.intrinsicContentSize.height,
                               swVoiceGuide.intrinsicContentSize.height),
                           insets.bottom].reduce(0, { $0 + $1 })
        return CGSize(width: size.width, height: totalHeight)
    }
    
}

// TODO: Display route histories
/**
 Current usage: select navigation mode
 */
class SettingView : BaseListView {
    
    private let routeModeId = "routeModeCell"
    private let switchId = "switchCell"
    
    override func initTable(isSelectionAllowed: Bool) {
        super.initTable(isSelectionAllowed: isSelectionAllowed)
        
        self.tableView.register(RouteModeRow.self, forCellReuseIdentifier: routeModeId)
        self.tableView.register(VoiceGuideRow.self, forCellReuseIdentifier: switchId)
        
        items = [routeModeId, switchId]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellId = (items as? [String])?[indexPath.row] else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        if let routeModeCell = cell as? RouteModeRow {
            return routeModeCell
        } else if let voiceGuideCell = cell as? VoiceGuideRow {
            return voiceGuideCell
        }
        
        return UITableViewCell()
    }
    
}
