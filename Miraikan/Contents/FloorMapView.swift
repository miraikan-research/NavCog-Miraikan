//
//  MapView.swift
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
 The data model for FloorMap
 
 - Parameters:
 - id: The primary index
 - floor: The floor number
 - counter: The marker on the FloorMap
 - title: The place name
 */
struct FloorMapModel : Decodable {
    let id: String
    let floor: Int
    let counter: String?
    let title: String
}

/**
 The BaseView for the FloorMap
 */
class FloorMapView: BaseView {
    
    private var map: UIImageView!
    private var image: UIImage!
    
    private let lblTitle = UILabel()
    private let lblPlace = UILabel()
    private let btnNav = BaseButton()
    
    // MARK: init
    init(_ model: FloorMapModel) {
        super.init(frame: .zero)
        setup(model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let gap = CGFloat(10)
        var y = safeAreaInsets.top
        lblTitle.frame.origin = CGPoint(x: 0, y: y)
        y += lblTitle.frame.height + gap
        
        lblPlace.frame.origin = CGPoint(x: 0, y: y)
        y += lblPlace.frame.height + gap
        
        let imgAdaptor = ImageAdaptor(img: image)
        let scaledSize = imgAdaptor.scaleImage(viewSize: ImageType.FLOOR_MAP.size,
                                               frameWidth: frame.width)
        map.frame = CGRect(x: 0,
                           y: y,
                           width: scaledSize.width,
                           height: scaledSize.height)
        y += map.frame.height + gap
        
        btnNav.center.x = center.x
        btnNav.frame.origin.y = y
        btnNav.frame.size.width += 30
    }
    
    // MARK: Private Functions
    private func setup(_ model: FloorMapModel) {
        lblTitle.text = model.title
        let floor = model.floor
        var floorText = String(format: NSLocalizedString("FloorD", tableName: "BlindView", comment: "floor"), floor)

        if let counter = model.counter {
            // If the map exists, use it.
            floorText += counter.uppercased()
            image = UIImage(named: "f\(floor)_\(counter)")
            map = UIImageView(image: image)
        } else {
            // Otherwise, use the placeholder
            image = UIImage(named: "no_map")
            map = UIImageView(image: image)
        }
        
        lblPlace.text = floorText
        [lblTitle, lblPlace].forEach({
            $0.textColor = .black
            $0.sizeToFit()
            addSubview($0)
        })
        
        addSubview(map)
        
        btnNav.setTitle("\(model.title)へナビ", for: .normal)
        btnNav.setTitleColor(.black, for: .normal)
        btnNav.backgroundColor = .cyan
        btnNav.layer.cornerRadius = 5
        btnNav.layer.borderWidth = 1
        btnNav.layer.borderColor = UIColor.black.cgColor
        btnNav.titleEdgeInsets.left = 15
        btnNav.titleEdgeInsets.right = 15
        btnNav.sizeToFit()
        btnNav.tapAction { _ in
            print("Navigation Started")
        }
        addSubview(btnNav)
    }
    
}
