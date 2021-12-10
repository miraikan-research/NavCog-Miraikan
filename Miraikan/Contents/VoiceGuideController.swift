//
//
//  VoiceGuideController.swift
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

fileprivate class VoiceGuideRow : BaseRow {
    
    private let lblDesc = AutoWrapLabel()
    
    public var title : String? {
        didSet {
            lblDesc.text = title
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        lblDesc.numberOfLines = 0
        lblDesc.lineBreakMode = .byCharWrapping
        lblDesc.textColor = .black
        addSubview(lblDesc)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let lblSz = CGSize(width: innerSize.width, height: lblDesc.intrinsicContentSize.height)
        lblDesc.frame = CGRect(x: insets.left,
                               y: insets.top,
                               width: innerSize.width,
                               height: lblDesc.sizeThatFits(lblSz).height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let lblSz = CGSize(width: innerSizing(parentSize: size).width,
                           height: lblDesc.intrinsicContentSize.height)
        let height = insets.top + insets.bottom + lblDesc.sizeThatFits(lblSz).height
        return CGSize(width: size.width, height: height)
    }
    
}

fileprivate class VoiceGuideListView : BaseListView {
    
    private let cellId = "cellId"
    
    override func initTable(isSelectionAllowed: Bool) {
        super.initTable(isSelectionAllowed: isSelectionAllowed)
        
        self.tableView.register(VoiceGuideRow.self, forCellReuseIdentifier: cellId)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let emptyCell = UITableViewCell()
        guard let description = (items as? [String])?[indexPath.row] else { return emptyCell }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
                as? VoiceGuideRow else { return emptyCell }
        cell.title = description
        return cell
    }
    
}

fileprivate class PanelView : BaseView {
    
    private enum AudioControl : CaseIterable {
        case main
        case prev
        case next
        
        var imgName : String {
            switch self {
            case .main:
                return "play"
            case .prev:
                return "backward"
            case .next:
                return "forward"
            }
        }
    }
    
    private var controls = [AudioControl: BaseButton]()
    
    override func setup() {
        super.setup()
        
        AudioControl.allCases.forEach({ control in
            let btn = BaseButton()
            let config = UIImage.SymbolConfiguration(pointSize: 20)
            let img = UIImage(systemName: "\(control.imgName).fill", withConfiguration: config)
            btn.setImage(img, for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.sizeToFit()
            controls[control] = btn
            addSubview(btn)
        })
    }
    
    override func layoutSubviews() {
        
        var x = insets.left
        AudioControl.allCases.forEach({ control in
            guard let btn = controls[control] else { return }
            btn.frame.origin = CGPoint(x: x, y: insets.top)
            x += btn.frame.width
        })
    }
    
}

class VoiceGuideController: BaseController {
    
    private let listView = VoiceGuideListView()
    
    public var items : [String]? {
        didSet {
            listView.items = items
        }
    }
    
    @objc init(title: String?) {
        super.init(listView, title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func setItems(_ items: [String]) {
        self.items = items
    }
    
}
