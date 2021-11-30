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
 The customized UITableViewCell for category description
 */
fileprivate class DescriptionRow : BaseRow {
    
    private let lblDescription = AutoWrapLabel()
    
    // MARK: init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(lblDescription)
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lblDescription.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let descSize = CGSize(width: innerSize.width,
                              height: lblDescription.intrinsicContentSize.height)
        lblDescription.frame = CGRect(x: insets.left,
                                      y: insets.top,
                                      width: innerSize.width,
                                      height: lblDescription.sizeThatFits(descSize).height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let descSize = CGSize(width: innerSizing(parentSize: size).width,
                              height: lblDescription.intrinsicContentSize.height)
        let totalHeight = insets.top
        + lblDescription.sizeThatFits(descSize).height
        + insets.bottom
        return CGSize(width: size.width, height: totalHeight)
    }
    
    /**
     Set data from DataSource
     */
    public func configure(title: String) {
        lblDescription.text = title
        lblDescription.sizeToFit()
    }
    
}

/**
 Categories of Regular Exhibition
 */
class PermanentExhibitionController : BaseListController, BaseListDelegate {
    
    private let linkId = "linkCell"
    private let descId = "descCell"
    
    override func initTable() {
        // init the tableView
        super.initTable()
        
        self.baseDelegate = self
        self.tableView.register(LinkRow.self, forCellReuseIdentifier: linkId)
        self.tableView.register(DescriptionRow.self, forCellReuseIdentifier: descId)
        
        // Load the data
        guard let models = MiraikanUtil.readJSONFile(filename: "exhibition_category",
                                                  type: [RegularExhibitionModel].self)
            as? [RegularExhibitionModel]
        else { return }
        
        let sorted = models.sorted(by: { (a, b) in
            let floorA = a.floor ?? 0
            let floorB = b.floor ?? 0
            return floorA > floorB
        })
        var dividedItems = [Any]()
        sorted.forEach({ model in
            dividedItems += [model]
            dividedItems += [model.intro]
        })
        items = [0: dividedItems]
        
    }
    
    // MARK: BaseListDelegate
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        let (sec, row) = (indexPath.section, indexPath.row)
        let item = items?[sec]?[row]
        if let model = item as? RegularExhibitionModel,
           let cell = tableView.dequeueReusableCell(withIdentifier: linkId,
                                                          for: indexPath)
            as? LinkRow {
            let title = model.floor != nil
                ? "\(model.floor!)階 \(model.title)"
                : model.title
            cell.configure(title: title)
            return cell
        } else if let title = item as? String,
                  let cell = tableView.dequeueReusableCell(withIdentifier: descId,
                                                                 for: indexPath)
                    as? DescriptionRow {
            cell.configure(title: title)
            return cell
        }
        return nil
    }
    
    override func onSelect(_ tableView: UITableView, _ indexPath: IndexPath) {
        // Only the link is clickable
        if let model = items?[indexPath.section]?[indexPath.row] as? RegularExhibitionModel {
            guard let nav = self.navigationController as? BaseNavController else { return }
            let vc = ExhibitionListController(id: model.id, title: model.title)
            nav.show(vc, sender: nil)
        }
    }
    
}
