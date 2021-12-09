//
//
//  NaviSettingController.swift
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
import simd

fileprivate class CurrentLocationRow : BaseRow {
    
    private let lblDescription = UILabel()
    private let lblLocation = UILabel()
    
    private let gap: CGFloat = 10
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        lblDescription.text = NSLocalizedString("Current Location", comment: "")
        lblDescription.font = .boldSystemFont(ofSize: 16)
        lblDescription.sizeToFit()
        if MiraikanUtil.isLocated {
            guard let loc = MiraikanUtil.location else { return }
            lblLocation.text = "\(loc.lat), \(loc.lng), \(loc.floor)F"
        } else {
            lblLocation.text = NSLocalizedString("not_located", comment: "")
        }
        lblLocation.adjustsFontSizeToFitWidth = true
        lblLocation.numberOfLines = 1
        lblLocation.lineBreakMode = .byClipping
        lblLocation.sizeToFit()
        addSubview(lblDescription)
        addSubview(lblLocation)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        lblDescription.frame.origin = CGPoint(x: insets.left, y: insets.top)
        lblLocation.frame.origin = CGPoint(x: insets.left, y: insets.top + lblDescription.frame.height + gap)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let totalHeight = [insets.top,
                           lblDescription.intrinsicContentSize.height,
                           lblLocation.intrinsicContentSize.height,
                           insets.bottom].reduce(gap, { $0 + $1 })
        return CGSize(width: size.width, height: totalHeight)
    }
    
}

fileprivate class PreviewSwitchRow : BaseRow {
    
    private let lblDescription = UILabel()
    private let swPreview = BaseSwitch()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        lblDescription.text = NSLocalizedString("Preview", comment: "")
        lblDescription.font = .boldSystemFont(ofSize: 16)
        lblDescription.sizeToFit()
        addSubview(lblDescription)
        
        swPreview.isOn = MiraikanUtil.isPreview
        swPreview.isEnabled = MiraikanUtil.isLocated
        swPreview.onSwitch({ sw in
            UserDefaults.standard.set(sw.isOn, forKey: "OnPreview")
        })
        swPreview.sizeToFit()
        addSubview(swPreview)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let midY = max(lblDescription.intrinsicContentSize.height,
                       swPreview.intrinsicContentSize.height) / 2 + insets.top
        lblDescription.frame.origin.x = insets.left
        lblDescription.center.y = midY
        swPreview.frame.origin.x = frame.width - insets.right - swPreview.frame.width
        swPreview.center.y = midY
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let totalHeight = [insets.top,
                           max(lblDescription.intrinsicContentSize.height,
                               swPreview.intrinsicContentSize.height),
                           insets.bottom].reduce(0, { $0 + $1 })
        return CGSize(width: size.width, height: totalHeight)
    }
    
}

class NaviSettingController : BaseListController, BaseListDelegate {
    
    private let locationId = "locationCell"
    private let previewId = "previewCell"
    
    override func initTable() {
        super.initTable()
        
        self.baseDelegate = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.register(CurrentLocationRow.self, forCellReuseIdentifier: locationId)
        self.tableView.register(PreviewSwitchRow.self, forCellReuseIdentifier: previewId)
        self.items = [0: [locationId, previewId]]
    }
    
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        
        let (sec, row) = (indexPath.section, indexPath.row)
        guard let cellId = items?[sec]?[row] as? String else { return nil }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        if let locationCell = cell as? CurrentLocationRow {
            return locationCell
        } else if let previewCell = cell as? PreviewSwitchRow {
            return previewCell
        }
        
        return nil
    }
    
}
