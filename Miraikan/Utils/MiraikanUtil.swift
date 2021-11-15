//
//  Util.swift
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

class MiraikanUtil : NSObject {
    
    // Login status
    static public var isLoggedIn : Bool {
        return UserDefaults.standard.bool(forKey: "LoggedIn")
    }
    
    // Selected RouteMode
    static public var routeMode : RouteMode {
        let val = UserDefaults.standard.string(forKey: "RouteMode") ?? "unknown"
        let mode = RouteMode(rawValue: val) ?? .general
        return mode
    }
    
    // MARK: JSON
    static private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    static public func readJSONFile<T: Decodable>(filename: String, type: T.Type) -> Any? {
        
        if let path = Bundle.main.path(forResource: filename, ofType: "json"),
           let data = getDataFrom(path: URL(fileURLWithPath: path)),
           let res = decdoeToJSON(type: type, data: data) {
            return res
        }
        return nil
    }
    
    static public func readJSONFile(filename: String) -> Any? {
        if let path = Bundle.main.path(forResource: filename, ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let json = try? JSONSerialization.jsonObject(with: data,
                                                        options: .mutableLeaves) {
            return json
        }
        return nil
    }
    
    // Middle function for getting data from local file
    static private func getDataFrom(path: URL) -> Data? {
        do {
            let data = try Data(contentsOf: path)
            return data
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    // Middle function to decode JSON to specific model
    static public func decdoeToJSON<T: Decodable>(type: T.Type, data: Data) -> T? {
        do {
            let res = try MiraikanUtil.jsonDecoder.decode(type, from: data)
            return res
        } catch let DecodingError.dataCorrupted(context) {
            print(context)
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch {
            print("error: ", error)
        }
        return nil
    }
    
    // Use this only for JSON with unclear structure
    private func deserializeJSON(data: Data) -> Any? {
        do {
            let json = try JSONSerialization.jsonObject(with: data,
                                                        options: .mutableLeaves)
            return json
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    // MARK: UI Usage
    static public func calculateScaleFactor(_ size: CGSize, frameWidth: CGFloat, imageSize: CGSize) -> CGFloat {
        let targetSize = CGSize(width: frameWidth,
                                height: frameWidth * (size.height / size.width))
        
        let widthScaleRatio = targetSize.width / imageSize.width
        let heightScaleRatio = targetSize.height / imageSize.height
        return min(widthScaleRatio, heightScaleRatio)
    }
    
    // MARK: HTTP
    static public func http(host: String = Host.miraikan.address,
                            endpoint: String,
                            params: [URLQueryItem]? = nil,
                            method: String = HttpMethod.GET.rawValue,
                            headers: [String: String]? = nil,
                            body: Data? = nil,
                            success: ((Data)->())?,
                            fail: (()->())? = nil) {
        var url = URLComponents(string: "\(host)\(endpoint)")!
        var req = URLRequest(url: url.url!)
        
        if let items = params {
            url.queryItems = items
        }
          
        req.httpMethod = method
          
        if let b = body {
            req.httpBody = b
        }
          
        if let h = headers {
            req.allHTTPHeaderFields = h
        }
          
        URLSession.shared.dataTask(with: req) { (data, res, err) in
            if let _err = err,
               let _f = fail {
                print(_err.localizedDescription)
                DispatchQueue.main.async { _f() }
            }
            
            if let _data = data,
               let _f = success {
                DispatchQueue.main.async { _f(_data) }
            }
        }.resume()
    }
    
    
    // MARK: Date and Calendar
    static public func calendar() -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }
    
    static public func todayText() ->String {
        return todayText(df: "yyyy年MM月dd日 EEE")
    }
    
    static public func todayText(df: String) -> String {
        let format = DateFormatter()
        format.dateFormat = df
        format.locale = Locale(identifier: "jp_JP")
        return format.string(from: Date())
    }
    
    static public func parseDate(_ str: String, df: String = "yyyy-MM-dd") -> Date? {
        let format = DateFormatter()
        format.dateFormat = df
        format.locale = Locale(identifier: "ja_JP")
        let date = format.date(from: str)
        return date
    }
    
    static public func parseDateTime(_ str: String) -> Date? {
        return parseDate(str, df: "yyyy-MM-dd HH:mm")
    }
    
    static public var isWeekend : Bool {
        let calendar = Calendar(identifier: .japanese)
        let weekday = calendar.component(.weekday, from: Date())
        print("Day of week: \(weekday)")
        return weekday == 1 || weekday == 7
    }
    
    //MARK: Objc utils for NavCog3
    // Open the page for Scientist Communicator Talk
    @objc static public func openTalk(eventId: String) {
        if let window = UIApplication.shared.windows.first,
           let tab = window.rootViewController as? TabController,
           let nav = tab.viewControllers?[tab.selectedIndex] as? BaseNavController {
            
            // At this moment, there is no detail for each specific topic
            // Thus, this action is temporarily opening the overview page
            if let event = ExhibitionDataStore.shared.events?.first(where: { $0.id == eventId}) {
                nav.show(BaseController(EventView(event), title: event.title), sender: nil)
            }
            
        }
    }
    
    // Print the nodeIds and place names that is easy to copy
    @objc static public func printNode(nodeId: String, place: String) {
        print("\(nodeId), \(place)")
    }
    
}
