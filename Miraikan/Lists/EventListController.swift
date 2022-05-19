//
//  TodayView.swift
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
 The model for schedule data
 */
fileprivate struct ScheduleRowModel {
    let schedule : ScheduleModel
    let floorMap : FloorMapModel
    let event : EventModel
}

/**
 The customized UITableViewCell for schedule item
 */
fileprivate class ScheduleRow: BaseRow {
    private let lblTime = UILabel()
    private let lblPlace = UnderlinedLabel()
    private let lblEvent = UnderlinedLabel()
    private var lblDescription = UILabel()
    
    private let gapX = CGFloat(10)
    private let gapY = CGFloat(5)
    
    // MARK: init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(lblTime)
        addSubview(lblPlace)
        addSubview(lblEvent)
        addSubview(lblDescription)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Set the data from DataSource
     */
    public func configure(_ model: ScheduleRowModel) {
        lblTime.text = model.schedule.time
        lblTime.sizeToFit()
        
        lblPlace.title = model.floorMap.title
        lblPlace.openView({ [weak self] _ in
            guard let self = self else { return }
            if let nav = self.nav {
                nav.show(FloorMapViewController(model: model.floorMap, title: model.floorMap.title), sender: nil)
            }
        })
        addSubview(lblPlace)
        
        let talkTitle: String?
        if let _talkTitle = model.event.talkTitle {
            talkTitle = "「\(_talkTitle)」"
        } else { talkTitle = nil }
        let eventTitle = talkTitle ?? model.event.title.replacingOccurrences(of: "\n", with: "")
        lblEvent.title = eventTitle
        lblEvent.sizeToFit()
        lblEvent.openView({ [weak self] _ in
            guard let self = self else { return }
            if let nav = self.nav {
                nav.show(BaseController(EventView(model.event, facilityId: model.schedule.place), title: model.event.title), sender: nil)
            }
        })
        
        if let description = model.schedule.description {
            lblDescription.text = description
            lblDescription.sizeToFit()
        }
    }
    
    // MARK: layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        
        lblTime.frame.origin.x = insets.left
        lblTime.center.y = lblPlace.center.y
        
        let leftColWidth = insets.left + lblTime.frame.width + gapX
        lblPlace.frame = CGRect(x: leftColWidth,
                                y: y,
                                width: frame.width - leftColWidth - insets.right,
                                height: lblPlace.intrinsicContentSize.height)
        y += lblPlace.frame.height + gapY
        
        let rightColWidth = innerSize.width - lblTime.frame.width - gapX
        let eventWidth = min(rightColWidth, lblEvent.intrinsicContentSize.width)
        let szFit = CGSize(width: eventWidth, height: lblEvent.intrinsicContentSize.height)
        lblEvent.frame = CGRect(x: leftColWidth,
                                y: y,
                                width: eventWidth,
                                height: lblEvent.sizeThatFits(szFit).height)
        
        let totalWidth = lblEvent.frame.width + lblDescription.frame.width + insets.right

        // Place the description label in a new line when totalWidth beyonds the column width
        if totalWidth < rightColWidth {
            lblDescription.frame.origin.x = leftColWidth + lblEvent.frame.width
            lblDescription.center.y = lblEvent.center.y
        } else {
            y += lblEvent.frame.height + CGFloat(5)
            lblDescription.frame.origin = CGPoint(x: leftColWidth, y: y)
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var heightList = [lblPlace.intrinsicContentSize.height]
        
        let innerSz = innerSizing(parentSize: size)
        let eventWidth = min(lblEvent.intrinsicContentSize.width,
                             innerSz.width - lblTime.frame.width - gapX)
        let szFit = CGSize(width: eventWidth, height: lblEvent.intrinsicContentSize.height)
        let eventHeight = lblEvent.sizeThatFits(szFit).height
        heightList += [eventHeight]
        
        let indentation = lblTime.frame.width + gapX
        let totalWidth = indentation + eventWidth + lblDescription.frame.width
        
        // In order to display the description label
        // Add the height of it when totalWidth beyonds the inner width
        if totalWidth >= innerSz.width {
            heightList += [lblDescription.intrinsicContentSize.height]
        }
        
        let height = heightList.reduce((insets.top + insets.bottom), {$0 + $1 + gapY})
        
        return CGSize(width: size.width, height: height)
    }
    
}

/**
 The header that displays today's date
 */
fileprivate class ScheduleListHeader : BaseView {
    
    private let lblDate = UILabel()
    
    private let padding: CGFloat = 20
    
    override func setup() {
        super.setup()
        
        lblDate.text = MiraikanUtil.todayText()
        lblDate.font = .boldSystemFont(ofSize: 16)
        lblDate.sizeToFit()
        addSubview(lblDate)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        lblDate.center.y = self.center.y
        lblDate.frame.origin.x = padding
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height = padding * 2 + lblDate.frame.height
        return CGSize(width: size.width, height: height)
    }
    
}

/**
 List of Today's schedule
 */
class EventListController: BaseListController, BaseListDelegate {
    
    private let cellId = "eventCell"
    
    override func initTable() {
        // init the tableView
        super.initTable()
        
        self.baseDelegate = self
        self.tableView.allowsSelection = false
        self.tableView.register(ScheduleRow.self, forCellReuseIdentifier: cellId)
        
        // load the data
        var models = [ScheduleRowModel]()
        ExhibitionDataStore.shared.schedules?.forEach({ schedule in
            if let floorMaps = MiraikanUtil.readJSONFile(filename: "floor_map",
                                         type: [FloorMapModel].self) as? [FloorMapModel],
               let floorMap = floorMaps.first(where: {$0.id == schedule.place }),
               let event = ExhibitionDataStore.shared.events?.first(where: {$0.id == schedule.event}) {
                let model = ScheduleRowModel(schedule: schedule,
                                             floorMap: floorMap,
                                             event: event)
                models += [model]
            }
        })
        items = models
    }
    
    // MARK: BaseListDelegate
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId,
                                                       for: indexPath) as? ScheduleRow
        else { return UITableViewCell() }
        
        if let model = (items as? [Any])?[indexPath.row] as? ScheduleRowModel {
            cell.configure(model)
        }
        return cell
    }
    
    // MARK: UITableView
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return ScheduleListHeader()
        }
        return nil
    }
    
}
