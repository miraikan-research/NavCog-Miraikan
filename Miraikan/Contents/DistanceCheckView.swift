//
//
//  DistanceCheckView.swift
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
 The content of the  UIScrollView of EventView
 */
fileprivate class DistanceCheckContent: BaseView {
    private var items: [ExhibitionLinkModel] = []

    private var lblTitleArray: [UILabel] = []
    private var lblLatitude = UILabel()
    private var lbllongitude = UILabel()
    private var lblFloor = UILabel()
    private var lblSpeed = UILabel()
    private var lblAccuracy = UILabel()
    private var lblOrientation = UILabel()
    private var lblOrientationAccuracy = UILabel()

    private var lblLocationTitleArray: [UILabel] = []
    private var lblLocationDistanceArray: [UILabel] = []

    private let gap = CGFloat(5)
    private let space = CGFloat(10)

    // MARK: init
    init() {
        super.init(frame: .zero)

        setupLocationList()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let safeSize = CGSize(width: innerSize.width, height: frame.height)
        
        var y = insets.top
        
        for (index, lblTitle) in lblTitleArray.enumerated() {
            lblTitle.frame = CGRect(x: insets.left,
                                    y: y,
                                    width: innerSize.width / 2,
                                    height: lblTitle.sizeThatFits(safeSize).height)
            if let label = getLabel(index: index) {
                label.frame = CGRect(x: insets.left + innerSize.width / 2 + gap,
                                     y: y,
                                     width: innerSize.width / 2,
                                     height: lblTitle.sizeThatFits(safeSize).height)
            }
            y += lblTitle.frame.height + gap
        }
        
        y += space
        
        for (index, lblLocationTitle) in lblLocationTitleArray.enumerated() {
            lblLocationTitle.frame = CGRect(x: insets.left,
                                    y: y,
                                    width: innerSize.width / 2,
                                    height: lblLocationTitle.sizeThatFits(safeSize).height)
            
            let label = lblLocationDistanceArray[index]
            label.frame = CGRect(x: insets.left + innerSize.width / 2 + gap,
                                 y: y,
                                 width: innerSize.width / 2,
                                 height: lblLocationTitle.sizeThatFits(safeSize).height)

            y += lblLocationTitle.frame.height + gap
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let safeSize = innerSizing(parentSize: size)
        var height = insets.top
        
        for lblTitle in lblTitleArray {
            height += lblTitle.sizeThatFits(safeSize).height + gap
        }

        height += space

        for lblLocationTitle in lblLocationTitleArray {
            height += lblLocationTitle.sizeThatFits(safeSize).height + gap
        }

        return CGSize(width: size.width, height: height)
    }

    private func createLabel(_ txt: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = txt
        lbl.numberOfLines = 1
        lbl.lineBreakMode = .byCharWrapping
        return lbl
    }
    
    // MARK: Private functions
    private func setupLocationList() {
        let locationInfoes = [
            "latitude",
            "longitude",
            "floor",
            "speed",
            "accuracy",
            "orientation",
            "orientationAccuracy"
        ]

        for locationInfo in locationInfoes {
            let label = createLabel(locationInfo)
            lblTitleArray.append(label)
            addSubview(label)
        }

        addSubview(lblLatitude)
        addSubview(lbllongitude)
        addSubview(lblFloor)
        addSubview(lblSpeed)
        addSubview(lblAccuracy)
        addSubview(lblOrientation)
        addSubview(lblOrientationAccuracy)
    }
        
    private func setupFloorList() {
        for item in items {
            let label = createLabel(item.title)
            lblLocationTitleArray.append(label)
            addSubview(label)

            let distanceLabel = UILabel()
            lblLocationDistanceArray.append(distanceLabel)
            addSubview(distanceLabel)
        }
    }

    private func getLabel(index: Int) -> UILabel? {
        switch index {
        case 0:
            return lblLatitude
        case 1:
            return lbllongitude
        case 2:
            return lblFloor
        case 3:
            return lblSpeed
        case 4:
            return lblAccuracy
        case 5:
            return lblOrientation
        case 6:
            return lblOrientationAccuracy
        default:
            return nil
        }
    }

    func setDataForFloor(floor: Int) {
        // Load the data
        guard let models = MiraikanUtil.readJSONFile(filename: "exhibition",
                                                  type: [ExhibitionModel].self) as? [ExhibitionModel]
        else { return }
        
        DispatchQueue.main.async{
            self.items.removeAll()
            
            for label in self.lblLocationTitleArray {
                label.removeFromSuperview()
            }
            self.lblLocationTitleArray = []

            for label in self.lblLocationDistanceArray {
                label.removeFromSuperview()
            }
            self.lblLocationDistanceArray = []

            let sorted = models
                .filter({ model in
                    return model.floor == floor
                })
                .sorted(by: { $0.counter < $1.counter })
            sorted.forEach({ model in
                
                let title = model.counter != ""
                    ? "\(model.counter) \(model.title)" : model.title

                var hlpLocation: HLPLocation?
                if let latitudeStr = model.latitude,
                   let longitudeStr = model.longitude,
                   let latitude = Double(latitudeStr),
                   let longitude = Double(longitudeStr) {
                    hlpLocation = HLPLocation(lat: latitude, lng: longitude)
                }

                let linkModel = ExhibitionLinkModel(id: model.id,
                                                    title: title,
                                                    titlePron: model.titlePron,
                                                    hlpLocation: hlpLocation,
                                                    category: model.category,
                                                    nodeId: model.nodeId,
                                                    counter: model.counter,
                                                    locations: model.locations,
                                                    blindDetail: model.blindDetail)
                self.items.append(linkModel)
            })
            
            self.setupFloorList()
        }
    }

    func locationChanged(current: HLPLocation) {

        DispatchQueue.main.async{
            self.lblLatitude.text = String(current.lat)
            self.lbllongitude.text = String(current.lng)
            self.lblFloor.text = String(current.floor + 1)
            self.lblSpeed.text = String(current.speed)
            self.lblAccuracy.text = String(current.accuracy)
            self.lblOrientation.text = String(current.orientation)
            self.lblOrientationAccuracy.text = String(current.orientationAccuracy)
            
            for (index, item) in self.items.enumerated() {
                let dist = current.distance(to: item.hlpLocation)
                self.lblLocationDistanceArray[index].text = String(dist)
            }
        }
    }
}

/**
 The UIScrollView of event details
 */
class DistanceCheckView: BaseScrollView {
    init() {
        super.init(frame: .zero)
        
        contentView = DistanceCheckContent()
        scrollView.addSubview(contentView)
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func locationChanged(current: HLPLocation) {
        if let contentView = contentView as? DistanceCheckContent {
            contentView.locationChanged(current: current)
        }
    }

    func floorChanged(floor: Int) {
        if let contentView = contentView as? DistanceCheckContent {
            contentView.setDataForFloor(floor: floor)
        }
    }
}
