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
    let blindIntro : String
    let blindOverview : String
    let blindDetail : String
}

fileprivate struct ExhibitionLinkModel {
    let title : String
    let nodeId : String?
    let counter : String
    let locations: [ExhibitionLocation]?
    let blindDetail : String
}

fileprivate struct NavButtonModel {
    let nodeId : String?
    let locations: [ExhibitionLocation]?
    let title : String?
}

fileprivate struct ExhibitionContentModel {
    let title : String
    let blindIntro : String
    let blindOverview : String
}

fileprivate class NavButtonRow : BaseRow {
    
    private let btnNavi = StyledButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        btnNavi.setTitle(NSLocalizedString("Guide to this exhibition", tableName: "Miraikan", comment: ""), for: .normal)
        btnNavi.sizeToFit()
        addSubview(btnNavi)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(nodeId : String) {
        btnNavi.tapAction({ [weak self] _ in
            guard let self = self else { return }
            guard let nav = self.nav else { return }
            nav.openMap(nodeId: nodeId)
        })
    }
    
    public func configure(locations : [ExhibitionLocation], title : String) {
        btnNavi.tapAction({ [weak self] _ in
            guard let self = self else { return }
            guard let nav = self.nav else { return }
            let vc = FloorSelectionController(title: title)
            vc.items = locations
            nav.show(vc, sender: nil)
        })
    }
    
    override func layoutSubviews() {
        btnNavi.frame = CGRect(x: innerSize.width - btnNavi.frame.width,
                               y: insets.top,
                               width: btnNavi.intrinsicContentSize.width + btnNavi.paddingX,
                               height: btnNavi.intrinsicContentSize.height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height = insets.top + insets.bottom + btnNavi.intrinsicContentSize.height
        return CGSize(width: size.width, height: height)
    }
    
}

fileprivate class LinkingHeader : BaseView {
    
    private let titleLink = UnderlinedLabel()
    
    var model : ExhibitionLinkModel? {
        didSet {
            guard let model = model else { return }
            titleLink.title = model.title
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
            self.isUserInteractionEnabled = true
            self.addGestureRecognizer(tap)
        }
    }
    
    var isFirst : Bool = false
    
    override func setup() {
        super.setup()
        
        titleLink.accessibilityTraits = .header
        addSubview(titleLink)
    }
    
    @objc private func tapAction(_ sender: UIView) {
        guard let model = model else { return }
        guard let nav = self.navVC else { return }
        nav.show(BaseController(ExhibitionView(nodeId: model.nodeId,
                                               detail: model.blindDetail,
                                               locations: model.locations),
                                title: model.title), sender: nil)
    }
    
    override func layoutSubviews() {
        let topMargin = isFirst ? (insets.top + 20) : insets.top
        let linkSz = CGSize(width: innerSize.width, height: 0)
        titleLink.frame = CGRect(x: insets.left,
                                 y: topMargin,
                                 width: innerSize.width,
                                 height: titleLink.sizeThatFits(linkSz).height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let linkSz = CGSize(width: innerSizing(parentSize: size).width, height: 0)
        let topMargin = isFirst ? (insets.top + 20) : insets.top
        let height = topMargin + insets.bottom + titleLink.sizeThatFits(linkSz).height
        return CGSize(width: size.width, height: height)
    }
    
}

/**
 The customized UITableViewCell for each exhibition
 */
fileprivate class ContentRow : BaseRow {
    
    private let lblDescription = AutoWrapLabel()
    private var lblOverview = AutoWrapLabel()
    
    private let gap = CGFloat(10)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        [lblDescription, lblOverview].forEach({
            $0.isAccessibilityElement = true
            addSubview($0)
        })
    }
    
    public func configure(_ model: ExhibitionContentModel) {
        lblDescription.text = model.blindIntro.isEmpty
        ? model.blindIntro
        : NSLocalizedString("Description", tableName: "Miraikan", comment: "") + "\n\n\(model.blindIntro)\n"

        lblOverview.text = model.blindOverview.isEmpty
        ? model.blindOverview
        : NSLocalizedString("Overview", tableName: "Miraikan", comment: "") + "\n\n\(model.blindOverview)"

        addSubview(lblOverview)

        lblDescription.isHidden = lblDescription.text?.isEmpty ?? true
        lblOverview.isHidden = lblOverview.text?.isEmpty ?? true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lblDescription.text = nil
        lblOverview.text = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        lblDescription.frame = CGRect(x: insets.left,
                                      y: y,
                                      width: innerSize.width,
                                      height: lblDescription.sizeThatFits(innerSize).height)
        
        y += lblDescription.frame.height
        lblOverview.frame = CGRect(x: insets.left,
                                   y: y,
                                   width: innerSize.width,
                                   height: lblOverview.sizeThatFits(innerSize).height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let innerSz = innerSizing(parentSize: size)
        let height = [lblDescription, lblOverview]
            .map({ $0.sizeThatFits(innerSz).height })
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
class BlindExhibitionController : BaseListController, BaseListDelegate {
    
    private let category: String
    
    private let navId = "navCell"
    private let contentId = "descCell"
    
    private let cells : [String]!
    private var headers = [ExhibitionLinkModel]()
    
    // MARK: init
    init(id: String, title: String) {
        self.category = id
        self.cells = [navId, contentId]
        super.init(title: title)
        self.baseDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initTable() {
        // init the tableView
        super.initTable()
        
        self.tableView.register(NavButtonRow.self, forCellReuseIdentifier: navId)
        self.tableView.register(ContentRow.self, forCellReuseIdentifier: contentId)
        
        // Load the data
        guard let models = MiraikanUtil.readJSONFile(filename: "exhibition",
                                                  type: [ExhibitionModel].self)
            as? [ExhibitionModel]
        else { return }
        let sorted = models
            .filter({ model in
                if category == "world" {
                    return model.category == category || model.category == "calendar"
                }
                return model.category == category
            })
            .sorted(by: { $0.counter < $1.counter })
        var sections = [(NavButtonModel, ExhibitionContentModel)]()
        sorted.forEach({ model in
            let title = model.counter != ""
                ? "\(model.counter) \(model.title)"
                : model.title
            let linkModel = ExhibitionLinkModel(title: title,
                                                nodeId: model.nodeId,
                                                counter: model.counter,
                                                locations: model.locations,
                                                blindDetail: model.blindDetail)
            headers += [linkModel]
            let navModel = NavButtonModel(nodeId: model.nodeId,
                                          locations: model.locations,
                                          title: model.title)
            let contentModel = ExhibitionContentModel(title: model.title,
                                                      blindIntro: model.blindIntro,
                                                      blindOverview: model.blindOverview)
            sections += [(navModel, contentModel)]
        })
        items = sections
    }
    
    // MARK: BaseListDelegate
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        let item = (items as? [(NavButtonModel, ExhibitionContentModel)])?[indexPath.section]
        let cellId = cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        if let model = item?.0, let cell = cell as? NavButtonRow {
            if let nodeId = model.nodeId {
                cell.configure(nodeId: nodeId)
            } else if let locations = model.locations, let title = model.title {
                cell.configure(locations: locations, title: title)
            }
            return cell
        } else if let model = item?.1,
                  let cell = cell as? ContentRow {
            cell.configure(model)
            return cell
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = LinkingHeader()
        header.model = headers[section]
        header.isFirst = section == 0
        return header
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = items as? [Any] else { return 0 }
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = items as? [(Any, Any)] else { return 0 }
        return Mirror(reflecting: items[section]).children.count
    }
    
}
