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

/**
 This should be accessible for TabController and its related controllers / views
 
 - References:
 
 [Icon by](https://icons8.com),
 [Staff](https://icons8.com/icon/61242/management),
 [Inquiry](https://icons8.com/icon/20150/inquiry),
 [Home](https://icons8.com/icon/59809/home),
 [Login](https://icons8.com/icon/26218/login),
 [Ask Question](https://icons8.com/icon/7857/ask-question)
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
    
    var accessibilityTitle: String {
        switch self {
        case .callStaff:
            return NSLocalizedString("Call Staff pron", comment: "")
        case .callSC:
            return NSLocalizedString("Call SC pron", comment: "")
        case .home:
            return NSLocalizedString("Home pron", comment: "")
        case .login:
            return NSLocalizedString("Login pron", comment: "")
        case .askAI:
            return NSLocalizedString("Ask AI pron", comment: "")
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
        switch self {
        case .callStaff:
            return StaffTabController()
        case .callSC:
            return SCTabController()
        case .home:
            return HomeTabController()
        case .login:
            return LoginTabController()
        case .askAI:
            return AITabController()
        }
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
