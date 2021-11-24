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

/**
 The customized UITableViewCell for each exhibition
 */
fileprivate class ExhibitionRow : BaseRow {
    
    private let titleLink = UnderlinedLabel()
    private let btnNavi = NaviButton()
    private let lblDescription = AutoWrapLabel()
    
    private let gap = CGFloat(10)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(titleLink)
        addSubview(btnNavi)
        addSubview(lblDescription)
    }
    
    public func configure(_ model: ExhibitionModel) {
        lblDescription.text = MiraikanUtil.routeMode == .blind
        ? model.blindModeIntro
        : model.intro
        btnNavi.setTitle("この展示へナビ", for: .normal)
        btnNavi.sizeToFit()
        btnNavi.tapAction({ [weak self] _ in
            guard let _self = self else { return }
            if let n = _self.nav {
                if let nodeId = model.nodeId {
                    n.openMap(nodeId: nodeId)
                }
                if let locations = model.locations {
                    let vc = FloorSelectionController(title: model.title)
                    vc.items = [0: locations]
                    n.show(vc, sender: nil)
                }
            }
        })
        let linkTitle = model.counter != ""
            ? "\(model.counter) \(model.title)"
            : model.title
        titleLink.title = linkTitle
        titleLink.openView { [weak self] _ in
            guard let _self = self else { return }
            if let n = _self.nav {
                n.show(BaseController(ExhibitionView(category: model.category,
                                                     id: model.id,
                                                     nodeId: model.nodeId),
                                      title: model.title), sender: nil)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLink.title = nil
        btnNavi.setTitle(nil, for: .normal)
        lblDescription.text = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        
        let linkSize = CGSize(width: innerSize.width,
                              height: titleLink.intrinsicContentSize.height)
        titleLink.frame = CGRect(x: insets.left,
                                 y: insets.top,
                                 width: innerSize.width,
                                 height: titleLink.sizeThatFits(linkSize).height)
        y += titleLink.frame.height + gap
        
        btnNavi.frame = CGRect(x: innerSize.width - btnNavi.frame.width,
                               y: y,
                               width: btnNavi.intrinsicContentSize.width + btnNavi.paddingX,
                               height: btnNavi.intrinsicContentSize.height)
        y += btnNavi.frame.height + gap
        
        let descSize = CGSize(width: innerSize.width,
                              height: lblDescription.intrinsicContentSize.height)
        lblDescription.frame = CGRect(x: insets.left,
                                      y: y,
                                      width: innerSize.width,
                                      height: lblDescription.sizeThatFits(descSize).height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let linkSize = CGSize(width: innerSizing(parentSize: size).width,
                              height: titleLink.intrinsicContentSize.height)
        let descSize = CGSize(width: innerSizing(parentSize: size).width,
                              height: lblDescription.intrinsicContentSize.height)
        let height = [titleLink.sizeThatFits(linkSize),
                      btnNavi.intrinsicContentSize,
                      lblDescription.sizeThatFits(descSize)].map({ $0.height })
            .reduce((insets.top + insets.bottom), { $0 + $1 + gap})
        return CGSize(width: size.width, height: height)
    }
    
}

/**
 The list for Regular Exhibitions
 
 - Parameters:
 - id: category id
 - title: The title for NavigationBar
 */
class ExhibitionListController : BaseListController, BaseListDelegate {
    
    private let category: String
    
    private let cellId = "exhibitionCell"
    
    // MARK: init
    init(id: String, title: String) {
        self.category = id
        super.init(title: title)
        self.baseDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initTable(isSelectionAllowed: Bool) {
        // init the tableView
        super.initTable(isSelectionAllowed: isSelectionAllowed)
        
        self.tableView.register(ExhibitionRow.self, forCellReuseIdentifier: cellId)
        
        // Load the data
        if let models = MiraikanUtil.readJSONFile(filename: "exhibition",
                                                  type: [ExhibitionModel].self) as? [ExhibitionModel] {
            let sorted = models
                .filter({ $0.category == category})
                .sorted(by: { $0.counter < $1.counter })
            ExhibitionDataStore.shared.exhibitions = sorted
            items = [0: sorted]
        }
    }
    
    // MARK: BaseListDelegate
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId,
                                                       for: indexPath) as? ExhibitionRow
        else { return UITableViewCell() }
        
        let (sec, row) = (indexPath.section, indexPath.row)
        if let model = items?[sec]?[row] as? ExhibitionModel {
            cell.configure(model)
        }
        return cell
    }
    
}
