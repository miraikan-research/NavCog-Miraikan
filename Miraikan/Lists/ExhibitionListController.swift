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
 Model for ExhibitionList items
 
 - Parameters:
 - id : The primary index
 - nodeId: The destination id
 - title: The name displayed as link title
 - category: The category
 - counter: The location on FloorMap
 - floor: The floor
 - locations: Used for multiple locations
 - intro: The description for general and wheelchair mode
 - blindModeIntro: The description for blind mode
 */
private struct ExhibitionModel : Decodable {
    let id : String
    let nodeId : String?
    let title : String
    let category : String
    let counter : String
    let floor : Int?
    let locations : [ExhibitionLocation]?
    let intro : String
    let blindIntro : String
    let blindOverview : String
    let blindDetail : String
}

fileprivate struct ExhibitionLinkModel : Decodable {
    let id : String
    let category : String
    let title : String
    let nodeId : String?
    let counter : String
    let locations: [ExhibitionLocation]?
    let blindDetail : String
}

fileprivate struct ExhibitionContentModel : Decodable {
    let title : String
    let nodeId : String?
    let intro : String
    let blindIntro : String
    let blindOverview : String
    let locations: [ExhibitionLocation]?
}

/**
 The customized UITableViewCell for each exhibition
 */
fileprivate class ContentRow : BaseRow {
    
    private let btnNavi = StyledButton()
    private let lblDescription = AutoWrapLabel()
    private var lblOverview : AutoWrapLabel?
    
    private let gap = CGFloat(10)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(btnNavi)
        addSubview(lblDescription)
        selectionStyle = .none
    }
    
    public func configure(_ model: ExhibitionContentModel) {
        if MiraikanUtil.routeMode != .blind {
            lblDescription.text = model.intro
        } else {
            lblDescription.text = model.blindIntro.isEmpty
            ? model.blindIntro
            : "＜概要＞\n\(model.blindIntro)\n"
            lblOverview = AutoWrapLabel()
            lblOverview?.text = model.blindOverview.isEmpty
            ? model.blindOverview
            : "＜概観＞\n\(model.blindOverview)"
            addSubview(lblOverview!)
        }
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
                    vc.items = locations
                    n.show(vc, sender: nil)
                }
            }
        })
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        btnNavi.setTitle(nil, for: .normal)
        lblDescription.text = nil
        if let lblOverview = lblOverview {
            lblOverview.text = nil
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        
        btnNavi.frame = CGRect(x: innerSize.width - btnNavi.frame.width,
                               y: y,
                               width: btnNavi.intrinsicContentSize.width + btnNavi.paddingX,
                               height: btnNavi.intrinsicContentSize.height)
        y += btnNavi.frame.height + gap
        
        lblDescription.frame = CGRect(x: insets.left,
                                      y: y,
                                      width: innerSize.width,
                                      height: lblDescription.sizeThatFits(innerSize).height)
        
        if let lblOverview = lblOverview {
            y += lblDescription.frame.height
            lblOverview.frame = CGRect(x: insets.left,
                                       y: y,
                                       width: innerSize.width,
                                       height: lblOverview.sizeThatFits(innerSize).height)
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let innerSz = innerSizing(parentSize: size)
        var szList = [btnNavi.intrinsicContentSize,
                        lblDescription.sizeThatFits(innerSz)]
        if let lblOverview = lblOverview {
            szList += [lblOverview.sizeThatFits(innerSz)]
        }
        let height = szList.map({ $0.height })
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
    private let linkId = "linkCell"
    private let contentId = "descCell"
    
    // MARK: init
    init(id: String, title: String) {
        self.category = id
        super.init(title: title)
        self.baseDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initTable() {
        // init the tableView
        super.initTable()
        
        self.tableView.register(LinkRow.self, forCellReuseIdentifier: linkId)
        self.tableView.register(ContentRow.self, forCellReuseIdentifier: contentId)
        
        // Load the data
        guard let models = MiraikanUtil.readJSONFile(filename: "exhibition",
                                                  type: [ExhibitionModel].self)
            as? [ExhibitionModel]
        else { return }
        let sorted = models
            .filter({ $0.category == category || $0.category == "calendar" })
            .sorted(by: { $0.counter < $1.counter })
        var dividedItems = [Any]()
        sorted.forEach({ model in
            let title = model.counter != ""
                ? "\(model.counter) \(model.title)"
                : model.title
            let linkModel = ExhibitionLinkModel(id: model.id,
                                                category: category,
                                                title: title,
                                                nodeId: model.nodeId,
                                                counter: model.counter,
                                                locations: model.locations,
                                                blindDetail: model.blindDetail)
            dividedItems += [linkModel]
            let contentModel = ExhibitionContentModel(title: model.title,
                                                      nodeId: model.nodeId,
                                                      intro: model.intro,
                                                      blindIntro: model.blindIntro,
                                                      blindOverview: model.blindOverview,
                                                      locations: model.locations)
            dividedItems += [contentModel]
        })
        items = dividedItems
    }
    
    // MARK: BaseListDelegate
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        let item = (items as? [Any])?[indexPath.row]
        if let title = (item as? ExhibitionLinkModel)?.title,
           let cell = tableView.dequeueReusableCell(withIdentifier: linkId, for: indexPath)
            as? LinkRow {
            cell.configure(title: title)
            return cell
        } else if let model = item as? ExhibitionContentModel,
                  let cell = tableView.dequeueReusableCell(withIdentifier: contentId, for: indexPath)
                   as? ContentRow {
            cell.configure(model)
            return cell
        }
        return nil
    }
    
    override func onSelect(_ tableView: UITableView, _ indexPath: IndexPath) {
        // Only the link is clickable
        if let model = (items as? [Any])?[indexPath.row] as? ExhibitionLinkModel {
            guard let nav = self.navigationController as? BaseNavController else { return }
            let detail = MiraikanUtil.routeMode == .blind ? model.blindDetail : nil
            nav.show(BaseController(ExhibitionView(category: category,
                                                   id: model.id,
                                                   nodeId: model.nodeId,
                                                   detail: detail,
                                                   locations: model.locations),
                                    title: model.title), sender: nil)
        }
    }
    
}
