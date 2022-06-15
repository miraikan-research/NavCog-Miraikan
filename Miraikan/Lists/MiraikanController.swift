//
//  MiraikanController.swift
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
import HLPDialog

/**
 Home and initial settings
 */
class MiraikanController: BaseController {

    private let home = Home()

    init(title: String) {
        super.init(home, title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.getDestinations(note:)),
                                               name: Notification.Name(rawValue:"location_changed_notification"),
                                               object: nil)

        // Accessibility
        UIAccessibility.post(notification: .screenChanged, argument: self.navigationItem.titleView)
        
        // NavBar
        let btnSetting = BaseBarButton(image: UIImage(systemName: "gearshape"))
        btnSetting.accessibilityLabel = NSLocalizedString("Navi Settings", comment: "")
        btnSetting.tapAction { [weak self] in
            guard let self = self else { return }
            let vc = NaviSettingController(title: NSLocalizedString("Navi Settings", comment: ""))
            self.navigationController?.show(vc, sender: nil)
        }
        self.navigationItem.rightBarButtonItem = btnSetting
        
        // Request local notification permission
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge],
                                  completionHandler: { (granted, error) in
                print("Authorization granted: \(granted)")
                if let _err = error {
                    print(_err.localizedDescription)
                }
            })
        
        // TODO: Initialization processing position needs to be changed
        // Load the data
        if let events = MiraikanUtil.readJSONFile(filename: "event",
                                                  type: [EventModel].self) as? [EventModel] {
            ExhibitionDataStore.shared.events = events
        }
        
        if var schedules = MiraikanUtil.readJSONFile(filename: "schedule",
                                                     type: [ScheduleModel].self) as? [ScheduleModel] {
            if !MiraikanUtil.isWeekend { schedules.removeAll(where: { $0.onHoliday == false }) }
            ExhibitionDataStore.shared.schedules = schedules

//            // Add local notifications
//            schedules.forEach({ schedule in
//                if schedule.place == "co_studio" {
//                    let scheduledTime = schedule.time.split(separator: ":")
//                    var components = DateComponents()
//                    components.calendar = .current
//                    // Show notification 5 minutes before the event
//                    let PREV_MINS = 5
//                    let ONE_HOUR = 60
//                    let minute = Int(scheduledTime[1])! - PREV_MINS
//                    components.minute = minute >= 0 ? minute : ONE_HOUR + minute
//                    let hour = Int(scheduledTime[0])!
//                    components.hour = minute >= 0 ? hour : hour - 1
//
//                    let content = UNMutableNotificationContent()
//                    content.title = "コ・スタジオトークに参加します"
//                    guard let talkTitle = ExhibitionDataStore.shared.events?
//                        .first(where: { $0.id == schedule.event })?.talkTitle
//                    else { return }
//                    content.body = "\(talkTitle)"
//
//                    let calendar = Calendar(identifier: .gregorian)
//                    let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
//                    var title: String?
//                    var nodeId: String?
//                    if let floorMaps = MiraikanUtil.readJSONFile(filename: "floor_map",
//                                                                 type: [FloorMapModel].self) as? [FloorMapModel],
//                       let floorMap = floorMaps.first(where: {$0.id == schedule.place }) {
//                        title = floorMap.title
//                        nodeId = floorMap.nodeId
//                    }
//                    content.userInfo = [
//                        "year": date ?? Date(),
//                        "eventId": schedule.event,
//                        "nodeId": nodeId ?? "",
//                        "facilityId": schedule.place,
//                        "title": title ?? ""
//                    ]
//
//                    let trigger = UNCalendarNotificationTrigger(dateMatching: components,
//                                                                repeats: false)
//                    let request = UNNotificationRequest(identifier: schedule.event,
//                                                        content: content,
//                                                        trigger: trigger)
//                    UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
//                        if let _err = error {
//                            print(_err.localizedDescription)
//                        }
//                    })
//                }
//            })
        }
    }

    @objc func getDestinations(note: Notification) {

        guard let navDataStore = NavDataStore.shared(),
            let currentLocation = navDataStore.currentLocation() else { return }

        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue:"location_changed_notification"), object: nil)
        navDataStore.reloadDestinations(atLat: currentLocation.lat,
                                        lng: currentLocation.lng,
                                        forUser: navDataStore.userID,
                                        withUserLang: navDataStore.userLanguage())
    }

    func reload() {
        home.setSection()
        home.tableView.reloadData()
    }
}
