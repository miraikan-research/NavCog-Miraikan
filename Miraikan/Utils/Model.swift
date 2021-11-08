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

enum TabItem: Int, CaseIterable {
    case callStaff
    case callSC
    case home
    case login
    case askAI
    
    var title: String {
        switch self {
        case .callStaff:
            return "スタッフを呼ぶ"
        case .callSC:
            return "SCを呼ぶ"
        case .home:
            return "ホーム"
        case .login:
            return "ログイン "
        case .askAI:
            return "AIに質問"
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
        default:
            let baseVC = BaseController(BaseView(), title: self.title)
            nav.viewControllers = [baseVC]
        }
        
        return nav
    }
    
}

enum Place: String, CaseIterable {
    case GEO_COSMOS
    case CO_STUDIO
    case DOME_THEATER
    
    var filename: String {
        return self.rawValue.lowercased()
    }
}

enum Event: String, CaseIterable {
    // Geo-Cosmos
    case ASIMO
    case DIGGING_THE_FUTURE
    case COVID_19
    case APOLLO_11
    // Dome Theater
    case BIRTHDAY
    case NINE_DIMENSIONS
    // Scientist Communicator Talk
    case CO_STUDIO
    
    var filename: String {
        return self.rawValue.lowercased()
    }
    
    var title: String {
        switch self {
        // Geo-Cosmos
        case .ASIMO:
            return "ASIMO（アシモ）実演"
        case .DIGGING_THE_FUTURE:
            return "未来の地層\nDigging the Future"
        case .COVID_19:
            return "COVID-19 Daily Cases\n日々の感染者数"
        case .APOLLO_11:
            return "Apollo11“イーグルは着陸した”"
        // Dome Theater
        case .BIRTHDAY:
            return "バースデイ"
        case .NINE_DIMENSIONS:
            return "9次元からきた男"
        default:
            return "科学コミュニケーター・トーク"
        }
    }
}

// Determine the category and image size
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
