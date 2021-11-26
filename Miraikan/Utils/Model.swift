//
//  Enum.swift
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
 This should be accessible for TabController and its related controllers / views
 */
enum TabItem: Int, CaseIterable {
    case callStaff
    case callSC
    case home
    case login
    case askAI
    
    var title: String {
        switch self {
        case .callStaff:
            return NSLocalizedString("Call Staff", comment: "")
        case .callSC:
            return NSLocalizedString("Call SC", comment: "")
        case .home:
            return NSLocalizedString("Home", comment: "")
        case .login:
            return NSLocalizedString("Login", comment: "")
        case .askAI:
            return NSLocalizedString("Ask AI", comment: "")
        }
    }
    
    var imgName: String {
        switch self {
        case .callStaff:
            return "call_staff"
        case .callSC:
            return "call_sc"
        case .home:
            return "home"
        case .login:
            return "login"
        case .askAI:
            return "ask_ai"
        }
    }
    
    var vc : UIViewController {
        let nav = BaseNavController()
        switch self {
        case .home:
            nav.viewControllers = [MiraikanController()]
            nav.title = self.title
            return nav
        case .login:
            let baseVC = BaseController(LoginView(), title: self.title)
            nav.viewControllers = [baseVC]
        case .askAI:
            let dialogManager = DialogManager.sharedManager()
            if dialogManager.isAvailable {
                dialogManager.userMode = "user_\(MiraikanUtil.routeMode)"
                let baseVC = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewController(withIdentifier: "ai_vc")
                baseVC.title = self.title
                nav.viewControllers = [baseVC]
            } else {
                nav.viewControllers = [BaseController(BaseView(), title: self.title)]
            }
        default:
            let baseVC = BaseController(BaseView(), title: self.title)
            nav.viewControllers = [baseVC]
        }
        
        return nav
    }
    
}

/**
 Determine the image size
 */
enum ImageType : String {
    case ASIMO
    case GEO_COSMOS
    case DOME_THEATER
    case CO_STUDIO
    case FLOOR_MAP
    case CARD
    
    var size: CGSize {
        switch self {
        case .ASIMO:
            return CGSize(width: 683, height: 453)
        case .GEO_COSMOS:
            return CGSize(width: 538, height: 404)
        case .DOME_THEATER:
            return CGSize(width: 612, height: 459)
        case .CO_STUDIO:
            return CGSize(width: 600, height: 450)
        case .FLOOR_MAP:
            // 640 x 407.55 is the full size on web
            return CGSize(width: 640, height: 407.55)
        case .CARD:
            return CGSize(width: 538, height: 350)
        }
    }
}

enum Host {
    case miraikan
    case inkNavi
    
    var address: String {
        switch self {
        case .miraikan:
            return "https://www.miraikan.jst.go.jp"
        case .inkNavi:
            return ""
        }
    }
}

enum HttpMethod : String {
    case GET
    case POST
    case PUT
    case DELETE
}
