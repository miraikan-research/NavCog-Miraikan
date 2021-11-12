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
 Data model for Regular Exhibition categories
 
 - Parameters:
 - id: Category id
 - title: Category name
 - floor: The floor number; not available for multiple floors
 - intro: description of this category
 */
fileprivate struct RegularExhibitionModel : Decodable {
    let id : String
    let title : String
    let floor : Int?
    let intro : String
}

/**
 The customized UITableViewCell for Regular Exhibition categories
 */
fileprivate class RegularExhibitionRow : BaseRow {
    
    private var titleLink = UnderlinedLabel()
    private let lblDescription = AutoWrapLabel()
    
    private let gap = CGFloat(10)
    
    // MARK: init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(titleLink)
        addSubview(lblDescription)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lblDescription.text = nil
        titleLink.title = nil
    }
    
    /**
     Set data from DataSource
     */
    public func configure(_ model: RegularExhibitionModel) {
        lblDescription.text = model.intro
        let title = model.floor != nil
            ? "\(model.floor!)階 \(model.title)"
            : model.title
        titleLink.title = title
        titleLink.sizeToFit()
        titleLink.openView { [weak self] _ in
            guard let _self = self else { return }
            if let n = _self.nav {
                let vc = ExhibitionListController(id: model.id, title: model.title)
                n.show(vc, sender: nil)
            }
        }
        
        [titleLink, lblDescription].forEach({
            addSubview($0)
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLink.frame.origin = CGPoint(x: insets.left, y: insets.top)
        
        let descSize = CGSize(width: innerSize.width,
                              height: lblDescription.intrinsicContentSize.height)
        lblDescription.frame = CGRect(x: insets.left,
                                      y: insets.top + titleLink.frame.height + gap,
                                      width: innerSize.width,
                                      height: lblDescription.sizeThatFits(descSize).height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let descSize = CGSize(width: innerSizing(parentSize: size).width,
                              height: lblDescription.intrinsicContentSize.height)
        let height = [titleLink.intrinsicContentSize,
                      lblDescription.sizeThatFits(descSize)].map({ $0.height })
            .reduce((insets.top + insets.bottom), { $0 + $1 + gap})
        return CGSize(width: size.width, height: height)
    }
    
}

/**
 Categories of Regular Exhibition
 */
class RegularExhibitionController : BaseListController, BaseListDelegate {
    
    private let cellId = "regularCell"
    
    override func initTable(isSelectionAllowed: Bool) {
        // init the tableView
        super.initTable(isSelectionAllowed: isSelectionAllowed)
        
        self.baseDelegate = self
        self.tableView.register(RegularExhibitionRow.self, forCellReuseIdentifier: cellId)
        
        // Load the data
        if let models = MiraikanUtil.readJSONFile(filename: "exhibition_category",
                                                  type: [RegularExhibitionModel].self) as? [RegularExhibitionModel] {
            let sorted = models.sorted(by: { (a, b) in
                let floorA = a.floor ?? 0
                let floorB = b.floor ?? 0
                return floorA > floorB
            })
            items = [0: sorted]
        }
    }
    
    // MARK: BaseListDelegate
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId,
                                                       for: indexPath) as? RegularExhibitionRow
        else { return UITableViewCell() }
        
        let (sec, row) = (indexPath.section, indexPath.row)
        if let model = items?[sec]?[row] as? RegularExhibitionModel {
            cell.configure(model)
        }
        return cell
    }
    
}
