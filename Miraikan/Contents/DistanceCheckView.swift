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
    private let tts = DefaultTTS()
    private var isPlaying = false
    private var items: [LandmarkModel] = []
    private var nearestItems = [PositionModel?](repeating: nil, count: 5)

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

    private let gap: CGFloat = 5
    private let space: CGFloat = 10

    private let nearestArea: Double = 12
    private let nearestGuide: Double = 8

    private var checkLocation: HLPLocation?

    private var locationChangedTime = Date().timeIntervalSince1970
    
    private var filePath: URL?

    // MARK: init
    init() {
        super.init(frame: .zero)

        setupLocationList()
        
        setFilePath()
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
            lblTitle.frame = CGRect(x: insets.left + gap,
                                    y: y,
                                    width: (innerSize.width - gap) / 2 ,
                                    height: lblTitle.sizeThatFits(safeSize).height)
            if let label = getLabel(index: index) {
                label.frame = CGRect(x: insets.left + innerSize.width / 2 + gap,
                                     y: y,
                                     width: (innerSize.width - gap) / 2 ,
                                     height: lblTitle.sizeThatFits(safeSize).height)
            }
            y += lblTitle.frame.height + gap
        }
        
        y += space
        
        for (index, lblLocationTitle) in lblLocationTitleArray.enumerated() {
            lblLocationTitle.frame = CGRect(x: insets.left + gap,
                                    y: y,
                                    width:(innerSize.width - gap) / 2 ,
                                    height: lblLocationTitle.sizeThatFits(safeSize).height)
            
            let label = lblLocationDistanceArray[index]
            label.frame = CGRect(x: insets.left + innerSize.width / 2 + gap,
                                 y: y,
                                 width: (innerSize.width - gap) / 2 ,
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
        lbl.lineBreakMode = .byWordWrapping
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
        guard let navDataStore = NavDataStore.shared(),
              let destinations = navDataStore.destinations() else { return }

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

            for landmark in destinations {
                if let landmark = landmark as? HLPLandmark,
                   Int(landmark.nodeHeight) + 1 == floor,
                   !landmark.name.isEmpty,
                   let id = landmark.properties[PROPKEY_FACILITY_ID] as? String {
                    let linkModel = LandmarkModel(id: id,
                                                  nodeId: landmark.nodeID,
                                                  title: landmark.name,
                                                  titlePron: landmark.namePron,
                                                  hlpLocation: landmark.nodeLocation)
                    self.items.append(linkModel)
                    NSLog("\(linkModel.id)")

                    if self.items.first(where: {$0.nodeId == id }) == nil,
                       let coordinates = landmark.geometry.coordinates,
                       let latitude = coordinates[1] as? Double,
                       let longitude = coordinates[0] as? Double {
                        let linkModel = LandmarkModel(id: id,
                                                      nodeId: id,
                                                      title: landmark.name,
                                                      titlePron: landmark.namePron,
                                                      hlpLocation: HLPLocation(lat: latitude, lng: longitude))
                        self.items.append(linkModel)
                        NSLog("\(linkModel.id)")
                    }
                }
            }
            self.setupFloorList()
        }
    }

    func locationChanged(current: HLPLocation) {

        var updateDistance = false
        let now = Date().timeIntervalSince1970
        if !current.lat.isNaN && !current.lng.isNaN && (locationChangedTime + 1 < now) {

            if checkLocation == nil {
                locationChangedTime = now
                checkLocation = current
                return
            }

            let distance = current.distance(to: checkLocation)
//            NSLog("distance = \(distance), \(current), \(checkLocation) ")
            if distance < 1.5 {
                return
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.locale = Locale(identifier: "ja_JP")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            let dateString = dateFormatter.string(from: Date())

            guard let checkLocation = checkLocation else { return }
            var vector = Line(from: CGPoint(x: checkLocation.lat, y: checkLocation.lng),
                              to: CGPoint(x: current.lat, y: current.lng))
            self.writeData("\(dateString), \(current.lat), \(current.lng), \(checkLocation.lat), \(checkLocation.lng)\n")
            vector.scalarTimes(1.5)
            locationChangedTime = now
            self.checkLocation = current

            updateDistance = true

            for item in self.items {
                item.distance = current.distance(to: item.hlpLocation)
            }
            
            var sortItems = self.items.filter({ $0.distance <= nearestArea })
            sortItems.sort(by: { $0.distance < $1.distance})
            
            var positionModels: [PositionModel] = []

            for (index, item) in sortItems.enumerated() {
                for cnt in (index + 1) ..< sortItems.count {
                    let sortItem = sortItems[cnt]
                    if item.id == sortItem.id {
                        break
                    }

                    let destination1 = CGPoint(x: item.hlpLocation.lat, y: item.hlpLocation.lng)
                    let destination2 = CGPoint(x: sortItem.hlpLocation.lat, y: sortItem.hlpLocation.lng)

                    let lineSegment = Line(from: destination1, to: destination2)
                    if let cross = Line.intersection(vector, lineSegment, true) {
//                        NSLog("cross[\(index)][\(cnt)]  = \(cross), \(item.id), \(sortItem.id) ")
                        
                        if item.distance < nearestGuide,
                           self.nearestItems.first(where: {$0?.id == item.id }) == nil,
                           positionModels.first(where: {$0.id == item.id }) == nil {
                            let positionModel = PositionModel(id: item.id, titlePron: item.titlePron)
                            positionModel.distance = item.distance
                            positionModel.isRightDirection = Line.isRightDirection(vector, point: destination1)
                            positionModels.append(positionModel)

                            self.writeData("\(dateString), \(current.lat), \(current.lng), \(checkLocation.lat), \(checkLocation.lng), \(cross.x),\(cross.y), [\(positionModel.id)],\(positionModel.isRightDirection ? "左" : "右") \(positionModel.distance)m \(positionModel.titlePron), \(item.title), \(destination1.x), \(destination1.y), \(sortItem.title), \(destination2.x), \(destination2.y)\n")
                        }
                        
                        if sortItem.distance < nearestGuide,
                           self.nearestItems.first(where: {$0?.id == sortItem.id }) == nil,
                           positionModels.first(where: {$0.id == sortItem.id }) == nil {
                            let positionModel = PositionModel(id: sortItem.id, titlePron: sortItem.titlePron)
                            positionModel.distance = sortItem.distance
                            positionModel.isRightDirection = Line.isRightDirection(vector, point: destination2)
                            positionModels.append(positionModel)

                            self.writeData("\(dateString), \(current.lat), \(current.lng), \(checkLocation.lat), \(checkLocation.lng), \(cross.x),\(cross.y), [\(positionModel.id)],\(positionModel.isRightDirection ? "左" : "右") \(positionModel.distance)m \(positionModel.titlePron), \(item.title), \(destination1.x), \(destination1.y), \(sortItem.title), \(destination2.x), \(destination2.y)\n")
                        }
                    }
                }
            }

            var text = ""
            for item in positionModels {
                self.nearestItems.removeFirst()
                self.nearestItems.append(item)
                text += String(format: NSLocalizedString(item.isRightDirection ? "TheLeftSide" : "TheRightSide", tableName: "BlindView", comment: ""), item.titlePron)
            }
            
            if !text.isEmpty {
                self.play(text: text)
            }
        }

        DispatchQueue.main.async{ [self] in
            self.lblLatitude.text = String(current.lat)
            self.lbllongitude.text = String(current.lng)
            self.lblFloor.text = String(current.floor + 1)
            self.lblSpeed.text = String(current.speed)
            self.lblAccuracy.text = String(current.accuracy)
            self.lblOrientation.text = String(current.orientation)
            self.lblOrientationAccuracy.text = String(current.orientationAccuracy)
            
            if updateDistance {
                for (index, item) in self.items.enumerated() {
                    self.lblLocationDistanceArray[index].text = String(item.distance )
                }
            }
        }
    }

    private func pause() {
        tts.stop(true)
        self.isPlaying = false
    }

    private func play(text: String) {
        if self.isPlaying { return }

        self.isPlaying = true
        tts.speak(text, callback: { [weak self] in
            guard let self = self else { return }
            self.isPlaying = false
        })
    }
}

extension DistanceCheckContent {

    func setFilePath() {
        if !UserDefaults.standard.bool(forKey: "DebugMode") {
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        let dateString = dateFormatter.string(from: Date())
        if let dir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first {
            filePath = dir.appendingPathComponent("institution\(dateString).csv")
            guard let filePath = filePath else { return }
            if FileManager.default.createFile(
                            atPath: filePath.path,
                            contents: nil,
                            attributes: nil
                            )
            {
            }
        }
    }
    
    func writeData(_ writeLine: String) {
        if !UserDefaults.standard.bool(forKey: "DebugMode") {
            return
        }
        guard let filePath = filePath else {
            return
        }
        if let file = FileHandle(forWritingAtPath: filePath.path),
           let data = writeLine.data(using: .utf8) {
            file.seekToEndOfFile()
            file.write(data)
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
        
        DispatchQueue.main.async{
            self.scrollView.contentSize = CGSize(width: self.contentView.frame.width, height: 1500)
        }
    }
}
