//
//
//  AudioGuideManager.swift
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

// Singleton
final public class AudioGuideManager: NSObject {
    
    private var temporaryFloor: CGFloat = 0
    private var currentFloor: CGFloat = 0
    private var continueFloorCount: CGFloat = 0

    private let tts = DefaultTTS()
    private var isPlaying = false
    private var items: [LandmarkModel] = []
    private var nearestItems = [PositionModel?](repeating: nil, count: 5)

    private let nearestArea: Double = 12
    private let nearestGuide: Double = 8

    private var checkLocation: HLPLocation?

    private var locationChangedTime = Date().timeIntervalSince1970

    @objc dynamic var isDisplay = true
    private var isActive = true

    private override init() {
        super.init()
        active()
    }

    public static let shared = AudioGuideManager()


    func isDisplayButton(_ isDisplay: Bool) {
        self.isDisplay = isDisplay
    }

    func isActive(_ isActive: Bool) {
        self.isActive = isActive
//        if self.isActive {
//            self.active()
//        } else {
//            self.inactive()
//        }
    }

    func active() {
        let center = NotificationCenter.default
        center.removeObserver(self)
        center.addObserver(self,
                           selector: #selector(type(of: self).locationChanged(note:)),
                           name: NSNotification.Name("nav_location_changed_notification"),
                           object: nil)
    }

    func inactive() {
        let center = NotificationCenter.default
        center.removeObserver(self, name: NSNotification.Name("nav_location_changed_notification"), object: nil)

        checkLocation = nil
    }

    @objc private func locationChanged(note: Notification) {
        
        if !self.isDisplay { return }
        if !self.isActive { return }

        guard let userInfo = note.userInfo,
              let current = userInfo["current"] as? HLPLocation else {
          return
        }

        if (temporaryFloor == current.floor + 1) {
            continueFloorCount += 1
        } else {
            continueFloorCount = 0;
        }
        temporaryFloor = current.floor + 1

        if continueFloorCount > 20 &&
            currentFloor != temporaryFloor {
            currentFloor = temporaryFloor
            setDataForFloor(floor: Int(currentFloor))
        }

        locationChanged(current: current)
    }

    private func setDataForFloor(floor: Int) {

        guard let navDataStore = NavDataStore.shared(),
              let destinations = navDataStore.destinations() else { return }

        self.items.removeAll()
        
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
                }
            }
        }
    }

    private func locationChanged(current: HLPLocation) {
        let now = Date().timeIntervalSince1970
        if !current.lat.isNaN && !current.lng.isNaN && (locationChangedTime + 1 < now) {

            if checkLocation == nil {
                locationChangedTime = now
                checkLocation = current
                return
            }

            let distance = current.distance(to: checkLocation)
//            NSLog("locationChanged: distance: \(distance)")
            if distance < 1.5 {
                return
            }
            
            guard let checkLocation = checkLocation else { return }
            var vector = Line(from: CGPoint(x: checkLocation.lat, y: checkLocation.lng),
                              to: CGPoint(x: current.lat, y: current.lng))
            vector.scalarTimes(1.5)
            locationChangedTime = now
            self.checkLocation = current

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
                    if Line.intersection(vector, lineSegment, true) != nil {
                        if item.distance < nearestGuide,
                           self.nearestItems.first(where: {$0?.id == item.id }) == nil,
                           positionModels.first(where: {$0.id == item.id }) == nil {
                            let positionModel = PositionModel(id: item.id, titlePron: item.titlePron)
                            positionModel.distance = item.distance
                            positionModel.isRightDirection = Line.isRightDirection(vector, point: destination1)
                            positionModels.append(positionModel)
                        }

                        if sortItem.distance < nearestGuide,
                           self.nearestItems.first(where: {$0?.id == sortItem.id }) == nil,
                           positionModels.first(where: {$0.id == sortItem.id }) == nil {
                            let positionModel = PositionModel(id: sortItem.id, titlePron: sortItem.titlePron)
                            positionModel.distance = sortItem.distance
                            positionModel.isRightDirection = Line.isRightDirection(vector, point: destination2)
                            positionModels.append(positionModel)
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
