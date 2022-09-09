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
    private var nearestItems = [PositionModel?](repeating: nil, count: 7)
    private var speakTexts: [String] = []
    private var guidePositions: [GuidePositionModel] = []
    private var checkPointPositions: [GuidePositionModel] = []
    private var toiletPositions: [ToiletPositionModel] = []
    private var additionalLocations: [AdditionalLocationModel] = []

    private var checkLocation: HLPLocation?
    private var locationChangedTime = Date().timeIntervalSince1970

    @objc dynamic var isDisplay = true
    private var isActive = true

    private let checkTime: Double = 1
    private let checkDistance: Double = 1.2
    
    private let nearestFront: Double = 8
    private let nearestSide: Double = 7
    private let nearestRear: Double = 4

    private let angleFront: Double = 15
    private let angleSide: Double = 90
    private let angleRear: Double = 110

    private var filePath: URL?

    private override init() {
        super.init()
        active()
        initGuidePosition()
        initCheckPointPosition()
        initAdditionalLocation()
    }

    public static let shared = AudioGuideManager()


    func isDisplayButton(_ isDisplay: Bool) {
        self.isDisplay = isDisplay
    }

    func isActive(_ isActive: Bool) {
        self.speakTexts.removeAll()
        self.isActive = isActive
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

        initToiletData()

        if (temporaryFloor == current.floor + 1) {
            continueFloorCount += 1
        } else {
            continueFloorCount = 0;
        }
        temporaryFloor = current.floor + 1

        if continueFloorCount > 20 &&
            currentFloor != temporaryFloor {
            currentFloor = temporaryFloor
            let floor = Int(currentFloor)
            
            self.items.removeAll()
            setDataForFloor(floor: floor)
            setCheckPointForFloor(floor: floor)
            setAdditionalLocationForFloor(floor: floor)
        }

        locationChanged(current: current)
    }

    private func setDataForFloor(floor: Int) {

        guard let navDataStore = NavDataStore.shared(),
              let destinations = navDataStore.destinations() else { return }

        for landmark in destinations {
            if let landmark = landmark as? HLPLandmark,
               Int(landmark.nodeHeight) + 1 == floor,
               var name = landmark.name,
               var namePron = landmark.namePron,
               let id = landmark.properties[PROPKEY_FACILITY_ID] as? String,
                let nodeID = landmark.nodeID {

                var lat: Double?
                var lon: Double?
                if !name.isEmpty,
                    let guidePosition = getGuidePosition(title: name, floor: floor) {
                    lat = Double(guidePosition.latitude)
                    lon = Double(guidePosition.longitude)
                } else if let coordinates = landmark.geometry.coordinates,
                    let latitudeGeometry = coordinates[1] as? Double,
                    let longitudeGeometry = coordinates[0] as? Double {
                    lat = latitudeGeometry
                    lon = longitudeGeometry
                }
                
                if name.isEmpty {
                    for toiletPosition in toiletPositions {
                        if nodeID == toiletPosition.nodeId,
                           let title = toiletPosition.title,
                           let titlePron = toiletPosition.titlePron {
                            name = title
                            namePron = titlePron
                            break
                        }
                    }
                }

                if !name.isEmpty,
                   let latitude = lat,
                   let longitude = lon {
                    let linkModel = LandmarkModel(id: id,
                                                  nodeId: nodeID,
                                                  title: name,
                                                  titlePron: namePron,
                                                  nodeLocation: landmark.nodeLocation,
                                                  spotLocation: HLPLocation(lat: latitude, lng: longitude))
                    self.appendItem(model: linkModel)

                    if self.items.first(where: {$0.nodeId == id }) == nil {
                        let linkModel = LandmarkModel(id: id,
                                                      nodeId: id,
                                                      title: name,
                                                      titlePron: namePron,
                                                      nodeLocation: HLPLocation(lat: latitude, lng: longitude),
                                                      spotLocation: HLPLocation(lat: latitude, lng: longitude))
                        self.appendItem(model: linkModel)
                    }
                }
            }
        }
    }

    // TODO: Provisional processing
    private func setCheckPointForFloor(floor: Int) {

        guard let navDataStore = NavDataStore.shared(),
              let destinations = navDataStore.destinations() else { return }
        
        for checkPointPosition in self.checkPointPositions {
            if Int(checkPointPosition.floor) + 1 == floor,
               let latitudeNode = Double(checkPointPosition.latitude),
               let longitudeNode = Double(checkPointPosition.longitude) {
                for landmark in destinations {
                    if let landmark = landmark as? HLPLandmark,
                       Int(landmark.nodeHeight) + 1 == floor,
                       landmark.name == checkPointPosition.title,
                       let id = landmark.properties[PROPKEY_FACILITY_ID] as? String {
                     
                        
                        var lat: Double?
                        var lon: Double?
                        if let guidePosition = getGuidePosition(title: landmark.name, floor: floor) {
                            lat = Double(guidePosition.latitude)
                            lon = Double(guidePosition.longitude)
                        } else if let coordinates = landmark.geometry.coordinates,
                            let latitudeGeometry = coordinates[1] as? Double,
                            let longitudeGeometry = coordinates[0] as? Double {
                            lat = latitudeGeometry
                            lon = longitudeGeometry
                        }
                        
                        if let latitude = lat,
                           let longitude = lon {
                            let linkModel = LandmarkModel(id: id,
                                                          nodeId: landmark.nodeID,
                                                          title: landmark.name,
                                                          titlePron: landmark.namePron,
                                                          nodeLocation: HLPLocation(lat: latitudeNode,
                                                                                    lng: longitudeNode),
                                                          spotLocation: HLPLocation(lat: latitude, lng: longitude))
                            self.appendItem(model: linkModel)
                        }
                        break
                    }
                }
                
                for additionalLocation in additionalLocations {
                    if additionalLocation.floor + 1 == floor,
                       additionalLocation.title == checkPointPosition.title,
                       let latitude = Double(additionalLocation.latitude),
                       let longitude = Double(additionalLocation.longitude) {
                        let linkModel = LandmarkModel(id: additionalLocation.id,
                                                      nodeId: additionalLocation.nodeId,
                                                      title: additionalLocation.title,
                                                      titlePron: additionalLocation.titlePron,
                                                      nodeLocation: HLPLocation(lat: latitudeNode, lng: longitudeNode),
                                                      spotLocation: HLPLocation(lat: latitude, lng: longitude))
                        self.appendItem(model: linkModel)
                    }
                }
            }
        }
    }

    private func setAdditionalLocationForFloor(floor: Int) {
        for additionalLocation in additionalLocations {
            if additionalLocation.floor + 1 == floor,
               let latitude = Double(additionalLocation.latitude),
               let longitude = Double(additionalLocation.longitude) {
                let linkModel = LandmarkModel(id: additionalLocation.id,
                                              nodeId: additionalLocation.nodeId,
                                              title: additionalLocation.title,
                                              titlePron: additionalLocation.titlePron,
                                              nodeLocation: HLPLocation(lat: latitude, lng: longitude),
                                              spotLocation: HLPLocation(lat: latitude, lng: longitude))
                self.appendItem(model: linkModel)
            }
        }
    }

    private func appendItem(model: LandmarkModel) {
        if !model.title.contains("ASIMO") {
            self.items.append(model)
        }
    }

    private func initToiletData() {
        guard toiletPositions.isEmpty,
              let navDataStore = NavDataStore.shared(),
              let directory = navDataStore.directory(),
              let destinations = navDataStore.destinations() else { return }

        initHLPDirectorySection(sections: directory.sections)

        for toiletPosition in toiletPositions {
            for landmark in destinations {
                if let landmark = landmark as? HLPLandmark,
                   landmark.nodeID == toiletPosition.nodeId {
                 
                    toiletPosition.floor = Int(landmark.nodeHeight)
                    
                    if let coordinates = landmark.geometry.coordinates,
                        let latitudeGeometry = coordinates[1] as? Double,
                        let longitudeGeometry = coordinates[0] as? Double {
                        toiletPosition.longitude  = longitudeGeometry
                        toiletPosition.latitude = latitudeGeometry
                    }
                    break
                }
            }
        }
    }
    
    private func initHLPDirectorySection(sections: [HLPDirectorySection]) {
        for section in sections {
            for item in section.items {
                if let content = item.content {
                    initHLPDirectorySection(sections: content.sections)
                } else {
                    let toilet = item.toilet.rawValue
                    if toilet != HLPToiletTypeNone.rawValue {
                        let toiletPosition = ToiletPositionModel(nodeId: item.nodeID,
                                                                 title: item.title,
                                                                 titlePron: item.titlePron,
                                                                 subtitle: item.subtitle,
                                                                 subtitlePron: item.subtitlePron,
                                                                 toilet: Int(toilet))
                        self.toiletPositions.append(toiletPosition)
                    }
                }
            }
        }
    }

    private func locationChanged(current: HLPLocation) {
        let now = Date().timeIntervalSince1970
        if !current.lat.isNaN && !current.lng.isNaN && (locationChangedTime + checkTime < now) {

            if checkLocation == nil {
                locationChangedTime = now
                checkLocation = current
                return
            }

            let distance = current.distance(to: checkLocation)
            if distance < checkDistance {
                return
            }
            
            guard let checkLocation = checkLocation else { return }
            let checkPoint = CGPoint(x: checkLocation.lat, y: checkLocation.lng)
            let currentPoint = CGPoint(x: current.lat, y: current.lng)
            let vector = Line(from: checkPoint, to: currentPoint)
            locationChangedTime = now
            self.checkLocation = current

            for item in self.items {
                item.distance = current.distance(to: item.nodeLocation)
            }
            
            var sortItems = self.items.filter({ $0.distance <= nearestFront })
            sortItems.sort(by: { $0.distance < $1.distance})
            
            var positionModels: [PositionModel] = []

            for item in sortItems {
                if self.nearestItems.first(where: {$0?.id == item.id }) == nil,
                   positionModels.first(where: {$0.id == item.id }) == nil {
                    let destination = CGPoint(x: item.spotLocation.lat, y: item.spotLocation.lng)
                    let lineSegment = Line(from: currentPoint, to: destination)
                    
                    let sita = Line.angle(vector, lineSegment)
                    let sitaPi = sita * 180.0 / Double.pi
                    
                    if sitaPi < angleFront ||
                        sitaPi < angleSide && item.distance < nearestSide ||
                        sitaPi < angleRear && item.distance < nearestRear {

                        let positionModel = PositionModel(id: item.id, titlePron: item.titlePron)
                        positionModel.distance = item.distance
                        let isRightDirection = Line.isRightDirection(vector, point: destination)
                        positionModel.angle = sitaPi * (isRightDirection ? -1 : 1)
                        
                        positionModel.longitude = item.spotLocation.lng
                        positionModel.latitude = item.spotLocation.lat
                        positionModels.append(positionModel)
                    }
                }
            }
            
            for item in positionModels {
                self.nearestItems.removeFirst()
                self.nearestItems.append(item)
                
                var localizeKey = ""
                if fabs(item.angle) < angleFront {
                    localizeKey = "InTheFront"
                } else if fabs(item.angle) < angleRear {
                    localizeKey = item.angle < 0 ? "OnTheLeftSide" : "OnTheRightSide"
                }

                if !localizeKey.isEmpty {
                    let speakText = String(format: NSLocalizedString(localizeKey, tableName: "BlindView", comment: ""), item.titlePron.trimmingCharacters(in: .newlines))
                    self.speakTexts.append(speakText)

                    let dateFormatter = DateFormatter()
                    dateFormatter.calendar = Calendar(identifier: .gregorian)
                    dateFormatter.locale = Locale(identifier: "ja_JP")
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                    let dateString = dateFormatter.string(from: Date())
                    self.writeData("\(dateString), \(current.lng), \(current.lat), , , , , ,\(speakText), \(item.distance), \(item.angle), \(item.longitude), \(item.latitude)\n")
                }
            }
            
            if positionModels.count > 0 {
                self.dequeueSpeak()
            }
        }
    }

    
    func nearLocation(current: HLPLocation) {
        if !current.lat.isNaN && !current.lng.isNaN {

            for item in self.items {
                item.distance = current.distance(to: item.nodeLocation)
            }
            
            var sortItems = self.items.filter({ $0.distance <= nearestFront })
            sortItems.sort(by: { $0.distance < $1.distance})
            
            if let sortItem = sortItems.first {
                self.speakTexts.append(String(format: NSLocalizedString("Near", tableName: "BlindView", comment: ""), sortItem.titlePron))
                self.dequeueSpeak()
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
            self.dequeueSpeak()
        })
    }

    private func dequeueSpeak() {
        if self.isPlaying { return }
        if let text = speakTexts.first {
            self.play(text: text)
            self.speakTexts.removeFirst()
        }
    }
}

extension AudioGuideManager {

    func initGuidePosition() {
        if let guidePosition = MiraikanUtil.readJSONFile(filename: "GuidePosition",
                                                         type: [GuidePositionModel].self) as? [GuidePositionModel] {
            self.guidePositions = guidePosition
        }
    }

    func getGuidePosition(title: String, floor: Int) -> GuidePositionModel? {
        for guidePosition in self.guidePositions {
            if title == guidePosition.title,
               floor == guidePosition.floor + 1 {
                return guidePosition
            }
        }
        return nil
    }

    func initCheckPointPosition() {
        if let checkPointPositions = MiraikanUtil.readJSONFile(filename: "CheckPointPosition",
                                                         type: [GuidePositionModel].self) as? [GuidePositionModel] {
            self.checkPointPositions = checkPointPositions
        }
    }

    func initAdditionalLocation() {
        if let additionalLocations = MiraikanUtil.readJSONFile(filename: "AdditionalLocation",
                                                         type: [AdditionalLocationModel].self) as? [AdditionalLocationModel] {
            self.additionalLocations = additionalLocations
        }
    }
}

extension AudioGuideManager {

    func setFilePath(_ writeLine: String) {
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
            filePath = dir.appendingPathComponent("audioGuide\(dateString).csv")
            guard let filePath = filePath else { return }
            if FileManager.default.createFile(
                            atPath: filePath.path,
                            contents: nil,
                            attributes: nil
                            )
            {
                if let file = FileHandle(forWritingAtPath: filePath.path),
                   let data = writeLine.data(using: .utf8) {
                    file.seekToEndOfFile()
                    file.write(data)
                }
            }
        }
    }
    
    func writeData(_ writeLine: String) {
        if !UserDefaults.standard.bool(forKey: "DebugMode") {
            return
        }

        if let filePath = filePath {
            if let file = FileHandle(forWritingAtPath: filePath.path),
               let data = writeLine.data(using: .utf8) {
                file.seekToEndOfFile()
                file.write(data)
            }
        } else {
            setFilePath(writeLine)
        }
    }
}
