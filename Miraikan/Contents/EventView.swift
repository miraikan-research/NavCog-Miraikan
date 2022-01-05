//
//  DetailView.swift
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
 The content of the  UIScrollView of EventView
 */
fileprivate class EventContent: BaseView {
    
    private var lblTitle: UILabel!
    private var lblSubtitle: UILabel?
    private var scheduleLabels = [UILabel]()
    private var descLabels = [UILabel]()
    private var lblContent: UILabel!
    
    private let image: UIImage!
    private let imgView: UIImageView!
    
    private let type: ImageType
    private let gap = CGFloat(15)
    
    // MARK: init
    init(_ model: EventModel) {
        self.type = ImageType(rawValue: model.imageType.uppercased())!
        let imageCoStudio = "co_studio"
        let imageName = model.id.contains(imageCoStudio)
            ? imageCoStudio
            : model.id
        self.image = UIImage(named: imageName)
        self.imgView = UIImageView(image: self.image)
        
        super.init(frame: .zero)
        setup(model)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let safeSize = CGSize(width: innerSize.width, height: frame.height)
        
        var y = insets.top
        lblTitle.frame = CGRect(x: insets.left,
                                y: y,
                                width: innerSize.width,
                                height: lblTitle.sizeThatFits(safeSize).height)
        y += lblTitle.frame.height + gap
        
        let imgAdaptor = ImageAdaptor(img: image)
        let scaledSize = imgAdaptor.scaleImage(viewSize: type.size,
                                               frameWidth: frame.width)
        imgView.frame = CGRect(x: insets.left,
                               y: y,
                               width: scaledSize.width - insets.left * 2,
                               height: scaledSize.height)
        y += imgView.frame.height + gap
        
        scheduleLabels.forEach({
            $0.frame = CGRect(x: insets.left,
                              y: y,
                              width: innerSize.width,
                              height: $0.sizeThatFits(safeSize).height)
            y += $0.frame.height + CGFloat(5)
        })
        y += gap
        
        lblContent.frame = CGRect(x: insets.left,
                                  y: y,
                                  width: innerSize.width,
                                  height: lblContent.sizeThatFits(safeSize).height)
        y += lblContent.frame.height + gap
        
        descLabels.forEach({
            $0.frame = CGRect(x: insets.left,
                              y: y,
                              width: innerSize.width,
                              height: $0.sizeThatFits(safeSize).height)
            y += $0.frame.height + CGFloat(5)
        })
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let safeSize = innerSizing(parentSize: size)
        var height = insets.top
        
        height += lblTitle.sizeThatFits(safeSize).height + gap
        
        height += imgView.frame.height + gap
        
        if scheduleLabels.count > 0 {
            scheduleLabels.forEach({ height += $0.sizeThatFits(safeSize).height })
            height += gap
        }
        
        height += lblContent.sizeThatFits(safeSize).height + gap
        
        if descLabels.count > 0 {
            descLabels.forEach({ height += $0.sizeThatFits(safeSize).height })
            height += gap
        }
        
        return CGSize(width: size.width, height: height)
    }
    
    // MARK: Private functions
    private func setup(_ model: EventModel) {
        
        func createLabel(_ txt: String) -> UILabel {
            let lbl = UILabel()
            lbl.text = txt
            lbl.numberOfLines = 0
            lbl.lineBreakMode = .byCharWrapping
            return lbl
        }
        
        lblTitle = createLabel(model.title)
        lblTitle.font = .preferredFont(forTextStyle: .largeTitle)
        addSubview(lblTitle)
        
        addSubview(imgView)
        
        if let schedules = model.schedule {
            schedules.forEach({
                let lbl = createLabel($0)
                lbl.font = .boldSystemFont(ofSize: 16)
                scheduleLabels += [lbl]
                addSubview(lbl)
            })
        }
        
        lblContent = createLabel(model.content)
        addSubview(lblContent)
        
        if let descList = model.description {
            descList.forEach({
                let lbl = createLabel("※\($0)")
                lbl.font = .preferredFont(forTextStyle: .footnote)
                lbl.textColor = .darkGray
                descLabels += [lbl]
                addSubview(lbl)
            })
        }
    }
    
}

/**
 The UIScrollView of event details
 */
class EventView: BaseScrollView {
    init(_ model: EventModel) {
        super.init(frame: .zero)

        contentView = EventContent(model)
        scrollView.addSubview(contentView)
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
