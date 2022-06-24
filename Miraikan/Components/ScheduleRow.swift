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
import UIKit

/**
 The customized UITableViewCell for schedule item
 */
class ScheduleRow: BaseRow {
    private let lblTime = UILabel()
    private let lblPlace = UnderlinedLabel()
    private let lblEvent = UnderlinedLabel()
    private var lblDescription = UILabel()
    
    private let gapX: CGFloat = 20
    private let gapY: CGFloat = 10
    private let gapLine: CGFloat = 5
    
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
        
        lblTime.font = .preferredFont(forTextStyle: .callout)
        lblDescription.font = .preferredFont(forTextStyle: .callout)
        
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
                nav.show(EventDetailViewController(model: model, title: model.event.title), sender: nil)
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
        
        var y = insets.top + gapY

        lblTime.frame.origin.x = insets.left + gapX
        
        let leftColWidth = lblTime.frame.origin.x + lblTime.frame.width + gapX
        lblPlace.frame = CGRect(x: leftColWidth,
                                y: y,
                                width: frame.width - leftColWidth - insets.right,
                                height: lblPlace.intrinsicContentSize.height)
        y += lblPlace.frame.height + gapLine

        lblTime.center.y = lblPlace.center.y

        let rightColWidth = innerSize.width - leftColWidth - gapX
        let eventWidth = min(rightColWidth, lblEvent.intrinsicContentSize.width)
        let szFit = CGSize(width: eventWidth, height: lblEvent.intrinsicContentSize.height)
        lblEvent.frame = CGRect(x: leftColWidth,
                                y: y,
                                width: eventWidth,
                                height: lblEvent.sizeThatFits(szFit).height)

        y += lblEvent.frame.height + gapLine
        lblDescription.frame.origin = CGPoint(x: leftColWidth, y: y)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var y = insets.top + gapY
        let x = insets.left + gapX

        let leftColWidth = x + lblTime.frame.width + gapX
        var szFit = CGSize(width: frame.width - leftColWidth - insets.right,
                           height: lblPlace.intrinsicContentSize.height)
        y += lblPlace.sizeThatFits(szFit).height + gapLine

        let rightColWidth = innerSize.width - leftColWidth - gapX
        let eventWidth = min(rightColWidth, lblEvent.intrinsicContentSize.width)
        szFit = CGSize(width: eventWidth,
                       height: lblEvent.intrinsicContentSize.height)
        y += lblEvent.sizeThatFits(szFit).height + gapLine

        if lblDescription.frame.width > 0 {
            szFit = CGSize(width: frame.width - leftColWidth - insets.right,
                           height: lblDescription.intrinsicContentSize.height)
            y += lblDescription.sizeThatFits(szFit).height + gapLine
        }
        y += gapY

        return CGSize(width: size.width, height: y)
    }
}
