//
//
//  BaseNavController.swift
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
        mapVC.presetId = Int32(MiraikanUtil.presetId)
        NSLog("openMap(\(nodeId ?? "nil")) \(identifier), presetId: \(MiraikanUtil.presetId)")
        self.show(mapVC, sender: nil)
    }    
}
