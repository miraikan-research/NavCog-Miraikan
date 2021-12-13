//
//  Home.swift
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
 Data model for Special Exhibition and Event
 
 - Parameters
 - imagePc: URL address for the picture
 - permalink: URL address to open the WebView
 - title: The name of exhibition / event
 - start: The start date
 - end: The end date
 - isOnline: Online / inside Miraikan
 */
fileprivate struct CardModel : Decodable {
    let imagePc: String
    let permalink: String
    let title: String
    let start: String
    let end: String
    let isOnline: String?
}

/**
 Customized UITableViewCell for Special Exhibition or Event
 */
fileprivate class CardRow : BaseRow {
    // Default image
    private var img = UIImage(named: "card_loading")!
    // Prevent it from reloading every time
    private var isSet : Bool = false
    
    // Global variables
    private var isOnline : Bool! = false
    
    // Views
    private let imgView = UIImageView()
    private let lblTitle = AutoWrapLabel()
    private let lblPlace = AutoWrapLabel()
    
    // Sizing
    private let gapX = CGFloat(10)
    private let gapY: CGFloat = 5
    
    // MARK: init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(imgView)
        addSubview(lblTitle)
//        addSubview(lblPlace)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Set data from DataSource
     */
    public func configure(_ model: CardModel) {
        // Prevent it to be reloaded
        // which can cause glitch
        if isSet { return }
        
        // Set the data and flag
        if let data = try? Data(contentsOf: URL(string: "\(Host.miraikan.address)\(model.imagePc)")!),
           let image = UIImage(data: data) {
            img = image
        } else {
            img = UIImage(named: "card_not_available")!
        }
        imgView.image = img
        
        lblTitle.text = model.title
        
        if let _isOnline = model.isOnline {
            self.isOnline = !_isOnline.isEmpty
        }
        
        if self.isOnline {
            lblPlace.text = NSLocalizedString("place_online", comment: "")
        }
        
        isSet = true
    }
    
    // MARK: layout
    override func layoutSubviews() {
        let halfWidth = CGFloat(frame.width / 2)
        let scaleFactor = MiraikanUtil.calculateScaleFactor(ImageType.CARD.size,
                                                    frameWidth: halfWidth - (insets.left + gapX),
                                                    imageSize: img.size)
        imgView.frame = CGRect(x: insets.left,
                               y: insets.top,
                               width: img.size.width * scaleFactor,
                               height: img.size.height * scaleFactor)
        let szFit = CGSize(width: halfWidth, height: innerSize.height)
        lblTitle.frame = CGRect(x: halfWidth,
                                y: insets.top,
                                width: halfWidth - insets.right,
                                height: lblTitle.sizeThatFits(szFit).height)
        if isOnline {
            lblPlace.frame = CGRect(x: halfWidth,
                                    y: insets.top + lblTitle.frame.height + gapY,
                                    width: halfWidth - insets.right,
                                    height: lblPlace.sizeThatFits(szFit).height)
        }
        
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let halfWidth = CGFloat(size.width / 2)
        let scaleFactor = MiraikanUtil.calculateScaleFactor(ImageType.CARD.size,
                                                    frameWidth: halfWidth - (insets.left + gapX),
                                                    imageSize: img.size)
        let heightLeft = insets.top + img.size.height * scaleFactor
        let szFit = CGSize(width: halfWidth - insets.right, height: size.height)
        var heightList = [lblTitle.sizeThatFits(szFit).height]
        if isOnline {
            heightList += [lblPlace.sizeThatFits(szFit).height,
                           gapY]
        }
        let heightRight = heightList.reduce((insets.top + insets.bottom), { $0 + $1 })
        let height = max(heightLeft, heightRight)
        return CGSize(width: size.width, height: height)
    }
    
}

/**
 Customized UITableViewCell for menu items
 */
fileprivate class MenuRow : BaseRow {
    
    private let btnItem = ChevronButton()
    
    public var title: String? {
        didSet {
            btnItem.setTitle(title, for: .normal)
            btnItem.sizeToFit()
        }
    }
    
    public var isAvailable : Bool? {
        didSet {
            guard let isAvailable = isAvailable else {
                return
            }
            
            if isAvailable {
                self.backgroundColor = .clear
                btnItem.setTitleColor(.gray, for: .normal)
                btnItem.imageView?.tintColor = .gray
            } else {
                self.backgroundColor = .lightGray
                self.selectionStyle = .none
                btnItem.setTitleColor(.lightText, for: .normal)
                btnItem.imageView?.tintColor = .lightText
                btnItem.accessibilityLabel = NSLocalizedString("blank_description", comment: "")
            }
        }
    }
    
    // MARK: init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // To prevent the button being selected on VoiceOver
        btnItem.isEnabled = false
        // "Disabled" would not be read out
        btnItem.accessibilityTraits = .button
        btnItem.setTitleColor(.gray, for: .normal)
        btnItem.imageView?.tintColor = .gray
        addSubview(btnItem)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: layout
    override func layoutSubviews() {
        btnItem.frame = CGRect(origin: CGPoint(x: insets.bottom, y: insets.top),
                               size: btnItem.sizeThatFits(innerSize))
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let innerSz = innerSizing(parentSize: size)
        let height = insets.top + insets.bottom + btnItem.sizeThatFits(innerSz).height
        return CGSize(width: size.width, height: height)
    }
    
}

fileprivate class NewsRow : BaseRow {
    
    private let btnItem = ChevronButton()
    
    public var title: String? {
        didSet {
            btnItem.setTitle(title, for: .normal)
            btnItem.sizeToFit()
        }
    }
    
    public var isAvailable : Bool? {
        didSet {
            guard let isAvailable = isAvailable else {
                return
            }
            
            if isAvailable {
                self.backgroundColor = .clear
                btnItem.setTitleColor(.gray, for: .normal)
                btnItem.imageView?.tintColor = .gray
            } else {
                self.backgroundColor = .lightGray
                self.selectionStyle = .none
                btnItem.setTitleColor(.lightText, for: .normal)
                btnItem.imageView?.tintColor = .lightText
                btnItem.accessibilityLabel = NSLocalizedString("blank_description", comment: "")
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        btnItem.isEnabled = false
        btnItem.accessibilityTraits = .button
        btnItem.setTitleColor(.gray, for: .normal)
        btnItem.imageView?.tintColor = .gray
        addSubview(btnItem)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        btnItem.frame = CGRect(origin: CGPoint(x: insets.bottom, y: insets.top),
                               size: btnItem.sizeThatFits(innerSize))
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let innerSz = innerSizing(parentSize: size)
        let height = insets.top + insets.bottom + btnItem.sizeThatFits(innerSz).height
        return CGSize(width: size.width, height: height)
    }
    
}

/**
 The menu items for the home screen
 */
fileprivate enum MenuItem {
    case login
    case miraikanToday
    case permanentExhibition
    case currentPosition
    case reservation
    case suggestion
    case floorMap
    case nearestWashroom
    case news
    case setting
    case aboutMiraikan
    case aboutApp
    
    var isAvailable: Bool {
        let availableItems : [MenuItem] = [.login, .miraikanToday, .permanentExhibition,
                                           .currentPosition, .setting, .aboutMiraikan, .aboutApp]
        return availableItems.contains(self)
    }
    
    var name : String {
        switch self {
        case .login:
            return NSLocalizedString("Login", comment: "")
        case .miraikanToday:
            return NSLocalizedString("Miraikan Today", comment: "")
        case .permanentExhibition:
            return NSLocalizedString("Permanent Exhibitons", comment: "")
        case .reservation:
            return NSLocalizedString("Reservation", comment: "")
        case .currentPosition:
            return NSLocalizedString("Current Position", comment: "")
        case .suggestion:
            return NSLocalizedString("Suggested Routes", comment: "")
        case .floorMap:
            return NSLocalizedString("Floor Plan", comment: "")
        case .nearestWashroom:
            return NSLocalizedString("Neareast Washroom", comment: "")
        case .news:
            return NSLocalizedString("News", comment: "")
        case .setting:
            return NSLocalizedString("Settings", comment: "")
        case .aboutMiraikan:
            return NSLocalizedString("About Miraikan", comment: "")
        case .aboutApp:
            return NSLocalizedString("About This App", comment: "")
        }
    }
    
    /**
     Create the UIViewController MenuItem is tapped.
     By default it ret
     
     - Returns:
     A specific UIViewController, or BaseViewController with BaseView by default
     */
    func createVC() -> UIViewController {
        switch self {
        case .login:
            return createVC(view: LoginView())
        case .permanentExhibition:
            return PermanentExhibitionController(title: self.name)
        case .miraikanToday:
            return EventListController(title: self.name)
        case .setting:
            return createVC(view: SettingView())
        case .aboutMiraikan:
            return createVC(view: MiraikanAboutView())
        case .aboutApp:
            return createVC(view: AppAboutView())
        default:
            return createVC(view: BaseView())
        }
    }
    
    // Default method to create a UIViewController
    private func createVC(view: UIView) -> UIViewController {
        return BaseController(view, title: self.name)
    }
}

/**
 The menu secitons for the home screen
 */
fileprivate enum MenuSection : CaseIterable {
    case login
    case spex
    case event
    case exhibition
    case currentLocation
    case reservation
    case suggestion
    case map
    case news
    case newsList
    case settings
    
    var items: [MenuItem]? {
        switch self {
        case .login:
            return [.login]
        case .exhibition:
            return [.miraikanToday, .permanentExhibition]
        case .currentLocation:
            return [.currentPosition]
        case .reservation:
            return [.reservation]
        case .suggestion:
            return [.suggestion]
        case .map:
            return [.floorMap, .nearestWashroom]
        case .news:
            return [.news]
        case .settings:
            return [.setting, .aboutMiraikan, .aboutApp]
        default:
            return nil
        }
    }
    
    var endpoint: String? {
        let lang = NSLocalizedString("lang", comment: "")
        // TODO: Remove fileLang when files in all languages are available
        let fileLang = lang == "ja" ? lang : "en"
        switch self {
        case .spex:
            return "/exhibitions/spexhibition/_assets/json/\(fileLang).json"
        case .event:
            let year = MiraikanUtil.calendar().component(.year, from: Date())
            return "/events/_assets/json/\(year)/\(fileLang).json"
        default:
            return nil
        }
    }
    
    var title: String? {
        switch self {
        case .spex:
            return NSLocalizedString("spex", comment: "")
        case .event:
            return NSLocalizedString("Events", comment: "")
        default:
            return nil
        }
    }
}

/**
 The BaseListView (TableView) for the Home screen
 */
class Home : BaseListView {
    private let menuCellId = "menuCell"
    private let cardCellId = "cardCell"
    private let newsCellId = "newsCell"
    
    private var sections : [MenuSection]?
    
    override func initTable(isSelectionAllowed: Bool) {
        // init the tableView
        super.initTable(isSelectionAllowed: true)

        self.tableView.register(MenuRow.self, forCellReuseIdentifier: menuCellId)
        self.tableView.register(CardRow.self, forCellReuseIdentifier: cardCellId)
        self.tableView.register(NewsRow.self, forCellReuseIdentifier: newsCellId)

        // load the data
        sections = MenuSection.allCases
        if MiraikanUtil.isLoggedIn {
            sections?.removeAll(where: { $0 == .login })
        }
        
        guard let _sections = sections?.enumerated() else { return }
        
        var menuItems = [Int : [Any]]()
        for (idx, sec) in _sections {
            if let _items = sec.items {
                menuItems[idx] = _items
            } else if let _endpoint = sec.endpoint {
                menuItems[idx] = []
                MiraikanUtil.http(endpoint: _endpoint, success: { [weak self] data in
                    guard let self = self else { return }
                    
                    guard let res = MiraikanUtil.decdoeToJSON(type: [CardModel].self, data: data)
                    else { return }
                    let filtered = res.filter({ model in
                        let now = Date()
                        let start = MiraikanUtil.parseDate(model.start)!
                        let end = MiraikanUtil.parseDate(model.end)!
                        let endOfDay = MiraikanUtil.calendar().date(byAdding: .day, value: 1, to: end)!
                        return start <= now && endOfDay >= now
                    })
                    menuItems[idx] = filtered
                    self.items = menuItems
                    
                })
            } else if sec == .newsList {
                menuItems[idx] = ["常設展・ドームシアターはオンラインのチケット予約が必要です",
                                  "9月11日(土)18：00からニコニコ生放送　イグノーベル賞を科学コミュニケーターと楽しもう",
                                  "10月5日(火)から「ジオ・コスモス」の公開を一時休止します"]
            } else {
                menuItems[idx] = []
            }
        }
        items = menuItems
    }
    
    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (sec, row) = (indexPath.section, indexPath.row)
        
        if let items = (items as? [Int: [Any]])?[sec], items.isEmpty {
            let cell = UITableViewCell()
            cell.textLabel?.textColor = .lightGray
            cell.selectionStyle = .none
            switch sections?[sec] {
            case .spex:
                cell.textLabel?.text = NSLocalizedString("no_spex", comment: "")
            case .event:
                cell.textLabel?.text = NSLocalizedString("no_event", comment: "")
            default:
                print("Empty Section")
            }
            return cell
        } else {
            let rowItem = (items as? [Int: [Any]])?[sec]?[row]
            if let menuItem = rowItem as? MenuItem,
               let menuRow = tableView.dequeueReusableCell(withIdentifier: menuCellId, for: indexPath) as? MenuRow {
                // Normal Menu Row
                menuRow.title = menuItem.name
                menuRow.isAvailable = menuItem.isAvailable
                return menuRow
            } else if let cardModel = rowItem as? CardModel,
                      let cardRow = tableView.dequeueReusableCell(withIdentifier: cardCellId,
                                                                  for: indexPath) as? CardRow {
                // When HTTP request is finished,
                // display the data on the row for Special Exhibition or Event
                cardRow.configure(cardModel)
                return cardRow
            } else if let news = rowItem as? String,
                      let newsRow = tableView.dequeueReusableCell(withIdentifier: newsCellId,
                                                                  for: indexPath) as? NewsRow {
                newsRow.title = "・\(news)"
                newsRow.isAvailable = false
                return newsRow
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections?[section].title
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sections?[section] == .spex
                    || sections?[section] == .event,
            let items = (items as? [Int : [Any]])?[section] {
                return items.count > 0 ? items.count : 1
        } else if let rows = (items as? [Int: [Any]])?[section] {
            return rows.count
        }
        
        return 0
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let nav = navVC else { return }
        let (sec, row) = (indexPath.section, indexPath.row)
        let rowItem = (items as? [Int: [Any]])?[sec]?[row]
        
        if let menuItem = rowItem as? MenuItem,
            menuItem.isAvailable {
            if menuItem == .currentPosition {
                guard let nav = self.navVC else { return }
                nav.openMap(nodeId: nil)
            } else {
                let vc = menuItem.createVC()
                nav.show(vc, sender: nil)
            }
        } else if let cardModel = rowItem as? CardModel {
            let view = ExhibitionView(permalink: cardModel.permalink)
            nav.show(BaseController(view, title: cardModel.title), sender: nil)
        }
        super.tableView(tableView, didSelectRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if sections?[section] == .news {
            return 0
        } else if section < (items as! [Int : Any]).count - 1 {
            return 35
        }
        return 20
    }
    
}
