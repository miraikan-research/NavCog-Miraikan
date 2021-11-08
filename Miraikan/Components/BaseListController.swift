//
//
//  BaseListController.swift
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

protocol BaseListDelegate {
    func getCell(_ tableView: UITableView,
                 _ indexPath: IndexPath,
                 _ cellId : String) -> UITableViewCell
    func onSelect(_ tableView: UITableView, _ indexPath: IndexPath)
}

class BaseListController: UITableViewController {
    
    let items : [Int: [Any]]
    private let cellType : UITableViewCell.Type
    private let cellId : String
    
    public var baseDelegate : BaseListDelegate?
    
    init(vals: [Int: [Any]], cellType: UITableViewCell.Type = UITableViewCell.self, cellId: String, title: String?) {
        self.items = vals
        self.cellType = cellType
        self.cellId = cellId
        super.init(style: .grouped)
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(cellType.self, forCellReuseIdentifier: cellId)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count > 1
        ? items.count
        : (items.first!.value as [Any]).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = baseDelegate?.getCell(tableView, indexPath, cellId) {
            return cell
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.baseDelegate?.onSelect(tableView, indexPath)
    }
    
}
