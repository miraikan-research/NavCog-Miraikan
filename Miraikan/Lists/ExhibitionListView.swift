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

// Layout for each exhibition
fileprivate class ExhibitionRow : BaseView {
    
    private var titleLink : UnderlinedLabel!
    private let btnNavi = NaviButton()
    private let lblDescription = AutoWrapLabel()
    
    private let gap = CGFloat(10)
    
    init(_ model: ExhibitionModel) {
        lblDescription.text = MiraikanUtil.routeMode == .blind
        ? model.blindModeIntro
        : model.description
        super.init(frame: .zero)
        btnNavi.setTitle("この展示へナビ", for: .normal)
        btnNavi.sizeToFit()
        btnNavi.tapInside({ [weak self] _ in
            guard let _self = self else { return }
            if let n = _self.nav {
                if let nodeId = model.nodeId {
                    n.openMap(nodeId: nodeId)
                }
                if let locations = model.locations {
                    let vc = FloorSelectionController(vals: [0: locations],
                                                      cellId: "floorCell",
                                                      title: model.title)
                    n.show(vc, sender: nil)
                }
            }
        })
        let linkTitle = model.counter != ""
            ? "\(model.counter) \(model.title)"
            : model.title
        titleLink = UnderlinedLabel(linkTitle)
        titleLink.openView { [weak self] _ in
            guard let _self = self else { return }
            if let n = _self.nav {
                n.show(BaseController(ExhibitionView(category: model.category,
                                                     id: model.id,
                                                     nodeId: model.nodeId),
                                      title: model.title), sender: nil)
            }
        }
        
        [titleLink, btnNavi, lblDescription].forEach({
            addSubview($0)
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        
        let linkSize = CGSize(width: innerSize.width,
                              height: titleLink.intrinsicContentSize.height)
        titleLink.frame = CGRect(x: insets.left,
                                 y: insets.top,
                                 width: innerSize.width,
                                 height: titleLink.sizeThatFits(linkSize).height)
        y += titleLink.frame.height + gap
        
        btnNavi.frame = CGRect(x: innerSize.width - btnNavi.frame.width,
                               y: y,
                               width: btnNavi.intrinsicContentSize.width + btnNavi.paddingX,
                               height: btnNavi.intrinsicContentSize.height)
        y += btnNavi.frame.height + gap
        
        let descSize = CGSize(width: innerSize.width,
                              height: lblDescription.intrinsicContentSize.height)
        lblDescription.frame = CGRect(x: insets.left,
                                      y: y,
                                      width: innerSize.width,
                                      height: lblDescription.sizeThatFits(descSize).height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let linkSize = CGSize(width: innerSizing(parentSize: size).width,
                              height: titleLink.intrinsicContentSize.height)
        let descSize = CGSize(width: innerSizing(parentSize: size).width,
                              height: lblDescription.intrinsicContentSize.height)
        let height = [titleLink.sizeThatFits(linkSize),
                      btnNavi.intrinsicContentSize,
                      lblDescription.sizeThatFits(descSize)].map({ $0.height })
            .reduce((insets.top + insets.bottom), { $0 + $1 + gap})
        return CGSize(width: size.width, height: height)
    }
    
}

// Content for exhibitions
fileprivate class ExhibitionContent: BaseView {
    
    private var rows = [String: ExhibitionRow]()
    private var counters = [String]()
    
    private let category: String
    
    init(_ category: String) {
        self.category = category
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        if let items = MiraikanUtil.readJSONFile(filename: "exhibition",
                                         type: [ExhibitionModel].self),
           let models = (items as? [ExhibitionModel])?.filter({ $0.category == category}) {
            ExhibitionDataStore.shared.exhibitions = models
            counters = models.map({$0.counter}).sorted()
            models.forEach({ model in
                let row = ExhibitionRow(model)
                rows[model.counter] = row
                addSubview(row)
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        counters.forEach({ counter in
            let row = rows[counter]!
            row.frame = CGRect(origin: CGPoint(x: insets.left, y: y),
                               size: row.sizeThatFits(frame.size))
            y += row.frame.height
        })
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let innerSize = innerSizing(parentSize: size)
        let height = rows.map({ $0.value.sizeThatFits(innerSize).height })
            .reduce((insets.top + insets.bottom), { $0 + $1 })
        return CGSize(width: innerSize.width, height: height)
    }
    
}

// UIScrollView for exhibitions
class ExhibitionListView: BaseScrollView {
    
    private let category: String
    
    init(_ category: String) {
        self.category = category
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        let contentView = ExhibitionContent(category)
        super.setup(contentView)
    }
    
}
