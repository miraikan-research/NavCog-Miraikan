//
//  ExhibitionListController.swift
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
 The list for Regular Exhibitions
 
 - Parameters:
 - id: category id
 - title: The title for NavigationBar
 */
class ExhibitionListController: BaseListController, BaseListDelegate {
    
    private let category: String
    
    private let linkId = "linkCell"
    private let navId = "navCell"
    private let contentId = "descCell"
    
    private var cells = [String]()
    
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
        var dividedItems = [Any]()
        sorted.forEach({ model in
            let title = model.counter != ""
                ? "\(model.counter) \(model.title)" : model.title

            var hlpLocation: HLPLocation?
            if let latitudeStr = model.latitude,
               let longitudeStr = model.longitude,
               let latitude = Double(latitudeStr),
               let longitude = Double(longitudeStr) {
                hlpLocation = HLPLocation(lat: latitude, lng: longitude)
            }

            let linkModel = ExhibitionLinkModel(id: model.id,
                                                title: title,
                                                titlePron: model.titlePron,
                                                hlpLocation: hlpLocation,
                                                category: model.category,
                                                nodeId: model.nodeId,
                                                counter: model.counter,
                                                locations: model.locations,
                                                blindDetail: model.blindDetail)
            dividedItems += [linkModel]
            cells += [linkId]
            let navModel = NavButtonModel(nodeId: model.nodeId,
                                          locations: model.locations,
                                          title: model.title)
            dividedItems += [navModel]
            cells += [navId]
            let contentModel = ExhibitionContentModel(title: model.title,
                                                      intro: model.intro,
                                                      blindIntro: model.blindIntro,
                                                      blindOverview: model.blindOverview)
            dividedItems += [contentModel]
            cells += [contentId]
        })
        items = dividedItems
    }

    // MARK: BaseListDelegate
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        let cellId = cells[indexPath.row]
        let item = (items as? [Any])?[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        if let title = (item as? ExhibitionLinkModel)?.title,
           let cell = cell as? LinkRow {
            cell.configure(title: title)
            return cell
        } else if let model = item as? NavButtonModel, let cell = cell as? NavButtonRow {
            if let nodeId = model.nodeId {
                cell.configure(nodeId: nodeId)
            } else if let locations = model.locations, let title = model.title {
                cell.configure(locations: locations, title: title)
            }
            return cell
        } else if let model = item as? ExhibitionContentModel,
                  let cell = cell as? ContentRow {
            cell.configure(model)
            return cell
        }
        return nil
    }

    override func onSelect(_ tableView: UITableView, _ indexPath: IndexPath) {
        // Only the link is clickable
        if let model = (items as? [Any])?[indexPath.row] as? ExhibitionLinkModel {
            guard let nav = self.navigationController as? BaseNavController else { return }
            nav.show(BaseController(ExhibitionView(category: model.category,
                                                   id: model.id,
                                                   nodeId: model.nodeId,
                                                   locations: model.locations),
                                    title: model.title), sender: nil)
        }
    }
}
