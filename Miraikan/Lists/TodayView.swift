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

// Data for each row
fileprivate struct RowModel {
    let schedule : ScheduleModel
    let floorMap : FloorMapModel
    let event : EventModel
}

// Layout for each row
fileprivate class ContentRow: BaseView {
    
    private let lblTime = UILabel()
    private var lblPlace: UnderlinedLabel!
    private var lblEvent: UnderlinedLabel!
    private var lblDescription: UILabel?
    
    private let model: RowModel
    
    private let gapX = CGFloat(10)
    private let gapY = CGFloat(5)
    
    private enum Sender: Int {
        case map
        case detail
    }
    
    init(_ model: RowModel) {
        self.model = model
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        lblTime.text = model.schedule.time
        
        let talkTitle: String?
        if let _talkTitle = model.event.talkTitle {
            talkTitle = "「\(_talkTitle)」"
        } else { talkTitle = nil }
        let eventTitle = talkTitle ?? model.event.title.replacingOccurrences(of: "\n", with: "")
        
        func createLink(text: String, tag: Sender) -> UnderlinedLabel {
            let lbl = UnderlinedLabel(text)
            lbl.tag = tag.rawValue
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
            lbl.isUserInteractionEnabled = true
            lbl.addGestureRecognizer(tap)
            return lbl
        }
        
        lblPlace = createLink(text: model.floorMap.title, tag: .map)
        lblEvent = createLink(text: eventTitle, tag: .detail)
        
        [lblTime, lblPlace].forEach({
            $0!.sizeToFit()
            addSubview($0!)
        })
        addSubview(lblEvent!)
        
        if let description = model.schedule.description {
            lblDescription = UILabel()
            lblDescription?.text = description
            lblDescription?.sizeToFit()
            addSubview(lblDescription!)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        
        let indentation = lblTime.frame.width + gapX
        lblPlace.frame.origin = CGPoint(x: indentation, y: y)
        lblTime.center.y = lblPlace.center.y
        y += lblPlace.frame.height + gapY
        
        let eventWidth = min(lblEvent.intrinsicContentSize.width,
                             innerSize.width - indentation)
        let szFit = CGSize(width: eventWidth, height: lblEvent.intrinsicContentSize.height)
        lblEvent.frame = CGRect(x: indentation,
                                  y: y,
                                  width: eventWidth,
                                  height: lblEvent.sizeThatFits(szFit).height)
        
        if let _d = lblDescription {
            let totalWidth = lblEvent.frame.origin.x
                + lblEvent.frame.width + _d.frame.width

            if totalWidth < frame.width {
                _d.frame.origin.x = indentation + lblEvent.frame.width
                _d.center.y = lblEvent.center.y
            } else {
                y += lblEvent.frame.height + CGFloat(5)
                _d.frame.origin = CGPoint(x: indentation, y: y)
            }
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height: CGFloat
        var heightList = [lblPlace.intrinsicContentSize.height]
        
        let eventWidth = min(lblEvent.intrinsicContentSize.width,
                             innerSizing(parentSize: size).width
                                - lblTime.intrinsicContentSize.width - gapX)
        let szFit = CGSize(width: eventWidth, height: lblEvent.intrinsicContentSize.height)
        let eventHeight = lblEvent.sizeThatFits(szFit).height
        heightList += [eventHeight]
        
        // 2 or 3 rows depending on the width of the second row
        if let _d = lblDescription {
            
            let totalWidth = lblTime.frame.width + gapX
                + lblEvent.intrinsicContentSize.width
                + _d.frame.width
            
            if totalWidth >= size.width {
                heightList += [_d.intrinsicContentSize.height]
            }
        }
        
        height = heightList.reduce(insets.top, {$0 + $1 + gapY})
        
        return CGSize(width: size.width, height: height)
    }
    
    @objc private func tapAction(_ sender: UITapGestureRecognizer) {
        
        if let nav = self.nav {
            switch Sender(rawValue: sender.view!.tag) {
            case .map:
                nav.show(BaseController(FloorMapView(model.floorMap), title: model.floorMap.title), sender: nil)
            case .detail:
                nav.show(BaseController(EventView(model.event), title: model.event.title), sender: nil)
            case .none:
                fatalError("Unknown sender")
            }
        }
        
    }
    
}

// Content layout for today's schedule
fileprivate class TodayContent: BaseView {
    
    private var rows = [ContentRow]()
    private let lblDate = UILabel()
    
    private let sectionGap = CGFloat(10)
    
    override func setup() {
        super.setup()
        
        lblDate.text = MiraikanUtil.todayText()
        lblDate.font = .boldSystemFont(ofSize: 16)
        lblDate.sizeToFit()
        addSubview(lblDate)
        
        ExhibitionDataStore.shared.schedules?.forEach({ schedule in
            if let floorMaps = MiraikanUtil.readJSONFile(filename: "floor_map",
                                         type: [FloorMapModel].self) as? [FloorMapModel],
               let floorMap = floorMaps.first(where: {$0.id == schedule.place}),
               let event = ExhibitionDataStore.shared.events?.first(where: {$0.id == schedule.event}) {
                let model = RowModel(schedule: schedule,
                                     floorMap: floorMap,
                                     event: event)
                let row = ContentRow(model)
                rows += [row]
                addSubview(row)
            }
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        lblDate.frame.origin.y = y
        lblDate.center.x = center.x
        y += lblDate.frame.height + sectionGap
        
        rows.forEach({
            $0.frame = CGRect(x: 0,
                              y: y,
                              width: frame.width,
                              height: $0.sizeThatFits(frame.size).height)
            y += $0.frame.height
        })
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let innerSize = innerSizing(parentSize: size)
        let rowsHeight = rows.reduce(CGFloat(0),
                                     {$0 + $1.sizeThatFits(innerSize).height})
        let height = insets.top + rowsHeight
        return CGSize(width: size.width,
                      height: height)
    }
    
}

// 今日の未来館
class TodayView: BaseScrollView {
    
    override func setup() {
        contentView = TodayContent()
        super.setup(contentView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}
