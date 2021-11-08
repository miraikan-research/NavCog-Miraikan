//
//  FloorSelectionView.swift
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

// List of floors for those exhibitions with multiple floors
class FloorSelectionController: BaseListController, BaseListDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.baseDelegate = self
    }
    
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath, _ cellId: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        if let model = items[indexPath.section]?[indexPath.row] as? ExhibitionLocation {
            cell.textLabel?.text = "\(model.floor)階"
        }
        return cell
    }
    
    func onSelect(_ tableView: UITableView, _ indexPath: IndexPath) {
        if let nav = self.navigationController as? BaseNavController,
           let model = items[indexPath.section]?[indexPath.row] as? ExhibitionLocation {
            nav.openMap(nodeId: model.nodeId)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
