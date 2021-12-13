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
class MiraikanController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Accessibility
        UIAccessibility.post(notification: .screenChanged, argument: self.navigationItem.titleView)
        
        // NavBar
        let btnSetting = BaseBarButton(image: UIImage(systemName: "gearshape"))
        btnSetting.tapAction { [weak self] in
            guard let self = self else { return }
            let vc = NaviSettingController(title: NSLocalizedString("Navi Settings", comment: ""))
            self.navigationController?.show(vc, sender: nil)
        }
        self.navigationItem.rightBarButtonItem = btnSetting
        
        // Layout and title
        view = Home()
        title = TabItem.home.title
        
        // Request local notification permission
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge],
                                  completionHandler: { (granted, error) in
                print("Authorization granted: \(granted)")
                if let _err = error {
                    print(_err.localizedDescription)
                }
            })
        
        // Load the data
        if let events = MiraikanUtil.readJSONFile(filename: "event",
                                     type: [EventModel].self) as? [EventModel] {
            ExhibitionDataStore.shared.events = events
        }
        
        if var schedules = MiraikanUtil.readJSONFile(filename: "schedule",
                                     type: [ScheduleModel].self) as? [ScheduleModel] {
            if !MiraikanUtil.isWeekend { schedules.removeAll(where: { $0.onHoliday == false }) }
            ExhibitionDataStore.shared.schedules = schedules
            
            // Add local notifications
            schedules.forEach({ schedule in
                if schedule.place == "co_studio" {
                    let scheduledTime = schedule.time.split(separator: ":")
                    var components = DateComponents()
                    components.calendar = .current
                    // Show notification 5 minutes before the event
                    let PREV_MINS = 5
                    let ONE_HOUR = 60
                    let minute = Int(scheduledTime[1])! - PREV_MINS
                    components.minute = minute >= 0 ? minute : ONE_HOUR + minute
                    let hour = Int(scheduledTime[0])!
                    components.hour = minute >= 0 ? hour : hour - 1
                    
                    let content = UNMutableNotificationContent()
                    content.title = "コ・スタジオトークに参加します"
                    guard let talkTitle = ExhibitionDataStore.shared.events?
                        .first(where: { $0.id == schedule.event })?.talkTitle
                    else { return }
                    content.body = "\(talkTitle)"
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components,
                                                                repeats: false)
                    let request = UNNotificationRequest(identifier: schedule.event,
                                                        content: content,
                                                        trigger: trigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
                        if let _err = error {
                            print(_err.localizedDescription)
                        }
                    })
                }
            })
        }
    }

}

/**
 Tabs for Home, Login and others
 */
class TabController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        
        let tabs = TabItem.allCases.filter({ item in
            if MiraikanUtil.isLoggedIn {
                return item != .login
            }
            return true
        })
        
        self.viewControllers = tabs.map({ $0.vc })
        self.selectedIndex = tabs.firstIndex(where: { $0 == .home })!
        if let items = self.tabBar.items {
            for (i, t) in tabs.enumerated() {
                items[i].title = t.title
                items[i].image = UIImage(named: t.imgName)
            }
        }
        
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        (viewController as? BaseNavController)?.popToRootViewController(animated: true)
        return true
    }
    
}

/**
 Base UINavigationController for UI navigation purpose
 */
class BaseNavController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.blue]
    }
    
    /**
     Open the map and start navigation
     
     - Parameters:
     - nodeId: destination id
     */
    public func openMap(nodeId: String?) {
        
        // Select mode
        let mode = MiraikanUtil.routeMode
        UserDefaults.standard.setValue("user_\(mode.rawValue)", forKey: "user_mode")
        ConfigManager.loadConfig("presets/\(mode.rawValue).plist")
        
        // Open the map for Blind or General/Wheelchair mode
        let identifier = MiraikanUtil.routeMode == .blind ? "blind_ui" : "general_ui"
        let mapVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: identifier) as! MiraikanMapController
        mapVC.destId = nodeId
        self.show(mapVC, sender: nil)
    }
    
}
