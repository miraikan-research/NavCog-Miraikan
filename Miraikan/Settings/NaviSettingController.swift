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
        lblDescription.font = .boldSystemFont(ofSize: 16)
        addSubview(lblDescription)
        addSubview(lblLocation)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lblDescription.text = nil
        lblLocation.text = nil
    }
    
    public func configure(title: String, isLocated: Bool, location: HLPLocation?) {
        lblDescription.text = title
        lblDescription.sizeToFit()
        if isLocated {
            guard let loc = location else { return }
            lblLocation.text = "\(loc.lat), \(loc.lng), \(loc.floor)F"
        } else {
            lblLocation.text = NSLocalizedString("not_located", comment: "")
        }
        lblLocation.sizeToFit()
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
    private let swPreview = UISwitch()
    
    private let gap: CGFloat = 10
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        lblDescription.font = .boldSystemFont(ofSize: 16)
        lblDescription.sizeToFit()
        addSubview(lblDescription)
        
        swPreview.isOn = MiraikanUtil.isPreview
        swPreview.addTarget(self, action: #selector(_onSwitch(_:)), for: .touchUpInside)
        swPreview.sizeToFit()
        addSubview(swPreview)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lblDescription.text = nil
    }
    
    @objc private func _onSwitch(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "OnPreview")
    }
    
    public func configure(title: String, isLocated: Bool) {
        lblDescription.text = title
        lblDescription.sizeToFit()
        swPreview.isOn = !isLocated
        swPreview.isEnabled = isLocated
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
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
                           insets.bottom].reduce(gap, { $0 + $1 })
        return CGSize(width: size.width, height: totalHeight)
    }
    
}

class NaviSettingController : BaseListController, BaseListDelegate {
    
    private let locationId = "locationCell"
    private let previewId = "previewCell"
    
    private enum CellType : CaseIterable {
        case location
        case preview
        
        var title: String {
            switch self {
            case .location:
                return NSLocalizedString("Current Location", comment: "")
            case .preview:
                return NSLocalizedString("Preview", comment: "")
            }
        }
    }
    
    override func initTable() {
        super.initTable()
        
        self.baseDelegate = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.register(CurrentLocationRow.self, forCellReuseIdentifier: locationId)
        self.tableView.register(PreviewSwitchRow.self, forCellReuseIdentifier: previewId)
        self.items = [0: CellType.allCases]
    }
    
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        
        let (sec, row) = (indexPath.section, indexPath.row)
        guard let item = items?[sec]?[row] as? CellType else { return nil }
        
        switch item {
        case .location:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: locationId,
                                                           for: indexPath)
                    as? CurrentLocationRow
            else { return nil }
            cell.configure(title: item.title,
                           isLocated: MiraikanUtil.isLocated,
                           location: MiraikanUtil.location)
            return cell
        case .preview:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: previewId,
                                                           for: indexPath)
                    as? PreviewSwitchRow
            else { return nil }
            cell.configure(title: item.title, isLocated: MiraikanUtil.isLocated)
            return cell
        }
    }
    
}
