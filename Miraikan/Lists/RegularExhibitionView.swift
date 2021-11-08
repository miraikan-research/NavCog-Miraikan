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

// Data for regular exhibition
fileprivate struct RegularExhibitionModel : Decodable {
    let id : String
    let title : String
    let floor : Int?
    let description : String
}

// Layout for each regular exhibition
fileprivate class RegularExhibitionRow : BaseView {
    
    private var titleLink: UnderlinedLabel!
    private let lblDescription = AutoWrapLabel()
    
    private let gap = CGFloat(10)
    
    init(_ model: RegularExhibitionModel) {
        
        lblDescription.text = model.description
        let title = model.floor != nil
            ? "\(model.floor!)階 \(model.title)"
            : model.title
        super.init(frame: .zero)
        titleLink = UnderlinedLabel(title)
        titleLink.sizeToFit()
        titleLink.openView { [weak self] _ in
            guard let _self = self else { return }
            if let n = _self.nav {
                n.show(BaseController(ExhibitionListView(model.id), title: model.title), sender: nil)
            }
        }
        
        [titleLink, lblDescription].forEach({
            addSubview($0)
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

// Content for regular exhibitions
fileprivate class RegualrExhibitionContent: BaseView {
    
    private let ids = ["world", "future", "tsunagari"]
    private var rows = [String: RegularExhibitionRow]()
    
    override func setup() {
        super.setup()
        
        if let models = MiraikanUtil.readJSONFile(filename: "exhibition_category",
                                      type: [RegularExhibitionModel].self) as? [RegularExhibitionModel] {
            models.forEach({ model in
                let row = RegularExhibitionRow(model)
                rows[model.id] = row
                addSubview(row)
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        ids.forEach({ id in
            let row = rows[id]!
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

// 常設展示
class RegularExhibitionView: BaseScrollView {
    
    override func setup() {
        let contentView = RegualrExhibitionContent()
        super.setup(contentView)
    }
    
}
