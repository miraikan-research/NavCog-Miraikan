//
//
//  ScheduleRow.swift
//  NavCogMiraikan
//
/*******************************************************************************
 * Copyright (c) 2022 © Miraikan - The National Museum of Emerging Science and Innovation  
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

/**
 The customized UITableViewCell for schedule item
 */
class ScheduleRow: BaseRow {
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
        
        y += lblEvent.frame.height + CGFloat(5)
        lblDescription.frame.origin = CGPoint(x: leftColWidth, y: y)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var heightList = [lblPlace.intrinsicContentSize.height]
        
        let innerSz = innerSizing(parentSize: size)
        let eventWidth = min(lblEvent.intrinsicContentSize.width,
                             innerSz.width - lblTime.frame.width - gapX)
        let szFit = CGSize(width: eventWidth, height: lblEvent.intrinsicContentSize.height)
        let eventHeight = lblEvent.sizeThatFits(szFit).height
        heightList += [eventHeight]
        
        // In order to display the description label
        // Add the height of it when totalWidth beyonds the inner width
        if lblDescription.frame.width > 0 {
            heightList += [lblDescription.intrinsicContentSize.height]
        }
        
        let height = heightList.reduce((insets.top + insets.bottom), {$0 + $1 + gapY})
        
        return CGSize(width: size.width, height: height)
    }
}
