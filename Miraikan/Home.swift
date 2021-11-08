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

// Data for Event Card
fileprivate struct CardModel : Decodable {
    let imagePc: String
    let permalink: String
    let title: String
    let start: String
    let end: String
    let isOnline: String?
}

// Layout for Event Card
fileprivate class CardView : BaseView {
    private var img : UIImage!
    private var imgView: UIImageView!
    private let lblTitle = AutoWrapLabel()
    private let lblPlace = AutoWrapLabel()
    
    private let model : CardModel
    
    private let gapX = CGFloat(10)
    private let gapY: CGFloat = 5
    
    init(_ model: CardModel) {
        self.model = model
        img = UIImage(named: "card_loading")
        if let data = try? Data(contentsOf: URL(string: "\(Host.miraikan.address)\(model.imagePc)")!),
           let image = UIImage(data: data) {
            img = image
        } else {
            img = UIImage(named: "card_not_available")
        }
        imgView = UIImageView(image: img)
        
        lblTitle.text = model.title
        lblPlace.text = model.isOnline != nil ? "場所：オンライン" : "場所：xxxxxx"
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        [imgView, lblTitle, lblPlace].forEach({ addSubview($0) })
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        addGestureRecognizer(tap)
    }
    
    @objc private func tapAction() {
        if let n = nav {
            n.show(BaseController(ExhibitionView(permalink: model.permalink), title: model.title), sender: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
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
                                width: halfWidth,
                                height: lblTitle.sizeThatFits(szFit).height)
        lblPlace.frame = CGRect(x: halfWidth,
                                y: insets.top + lblTitle.frame.height + gapY,
                                width: halfWidth,
                                height: lblPlace.sizeThatFits(szFit).height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let halfWidth = CGFloat(size.width / 2)
        let scaleFactor = MiraikanUtil.calculateScaleFactor(ImageType.CARD.size,
                                                    frameWidth: halfWidth - (insets.left + gapX),
                                                    imageSize: img.size)
        let heightLeft = insets.top + img.size.height * scaleFactor
        let szFit = CGSize(width: halfWidth, height: size.height)
        let heightRight = [lblTitle.sizeThatFits(szFit).height,
                           lblPlace.sizeThatFits(szFit).height,
                           gapY].reduce(insets.top, { $0 + $1 })
        let height = max(heightLeft, heightRight)
        return CGSize(width: size.width, height: height)
    }
    
}

// Specific group for Card Layout
fileprivate class CardSection : BaseView {
    
    private var rows = [CardView]()
    
    override func setup() {
        super.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y: CGFloat = 0
        rows.forEach({ row in
            row.frame = CGRect(origin: CGPoint(x: insets.left, y: y),
                               size: row.sizeThatFits(innerSize))
            y += row.frame.height
        })
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height = rows.map({ $0.sizeThatFits(size).height })
            .reduce(0, { $0 + $1 })
        return CGSize(width: size.width, height: height)
    }
    
    func load(endpoint: String, action: (() -> ())?) {
        func filterByDate(today: Date, from: Date, to: Date) -> Bool {
            return from <= today && to >= today
        }
        
        MiraikanUtil.http(endpoint: endpoint, success: { [weak self] data in
            guard let _self = self else { return }
            if let res = MiraikanUtil.decdoeToJSON(type: [CardModel].self,
                                           data: data) {
                let filtered = res.filter({ model in
                    let start = MiraikanUtil.parseDate(model.start)!
                    let end = MiraikanUtil.parseDate(model.end)!
                    return filterByDate(today: Date(), from: start, to: end)
                })
                let models = filtered.count > 0 ? filtered : [res.first!]
                models.forEach({ model in
                    let row = CardView(model)
                    _self.rows += [row]
                    _self.addSubview(row)
                })
                
                if let f = action {
                    f()
                }
            }
        })
    }
    
}

fileprivate struct MenuItem {
    let icon: UIImage?
    let name: String
    // Default Value for Testing
    let view: BaseView.Type
    
    init(name: String, icon: UIImage? = nil, view: BaseView.Type = BaseView.self) {
        self.name = name
        self.icon = icon
        self.view = view
    }
    
    static public let login = MenuItem(name: "login")
    static public let callStaff = MenuItem(name: "スタッフを呼ぶ")
    static public let callSC = MenuItem(name: "SCを呼ぶ")
    static public let askAI = MenuItem(name: "AIに質問")
}

// Layout sections
fileprivate enum MenuSection : CaseIterable {
    case exitibition
    case reservation
    case suggestion
    case map
    case news
    case settings
    
    var items: [MenuItem] {
        switch self {
        case .exitibition:
            return [
                MenuItem(name: "今日の未来館", view: TodayView.self),
                MenuItem(name: "常設展示", view: RegularExhibitionView.self)
            ]
        case .reservation:
            return [MenuItem(name: "予約")]
        case .suggestion:
            return [MenuItem(name: "おすすめルート")]
        case .map:
            return [
                MenuItem(name: "館内マップ"),
                MenuItem(name: "最寄りのトイレ")
            ]
        case .news:
            return [MenuItem(name: "ニュース")]
        case .settings:
            return [
                MenuItem(name: "設定", view: SettingView.self),
                MenuItem(name: "日本科学未来館について", view: MiraikanAboutView.self),
                MenuItem(name: "このアプリについて", view: AppAboutView.self),
            ]
        }
    }
}

// Row for specific Menu item
fileprivate class MenuRow: BaseView {
    private let lblLink: ArrowView
    private let menu: MenuItem
    
    //MARK: init
    init(_ menu: MenuItem) {
        self.menu = menu
        lblLink = ArrowView(menu.name)
        super.init(frame: .zero)
        addSubview(lblLink)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
//
    override func setup() {
        super.setup()
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(rowTapped))
        let press = UILongPressGestureRecognizer(target: self, action: #selector(rowPressed))
        addGestureRecognizer(tap)
        addGestureRecognizer(press)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        lblLink.frame = CGRect(origin: .zero,
                               size: CGSize(width: frame.width,
                                            height: lblLink.sizeThatFits(frame.size).height))
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let btmMargin = insets.bottom
        return CGSize(width: size.width,
                      height: lblLink.sizeThatFits(size).height + btmMargin)
    }
    
    //MARK: Row tapped actions
    
    // Animations
    @objc private func rowTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.lblLink.backgroundColor = .lightGray
        }, completion: { [weak self] _ in
            guard let _self = self else { return }
            _self.lblLink.backgroundColor = .clear
            _self.openView()
        })
    }
    
    @objc private func rowPressed(_ sender: UILongPressGestureRecognizer) {
        UIView.animate(withDuration: 0.1, delay: 0.1, options: [], animations: {
            self.lblLink.backgroundColor = .lightGray
        }, completion: {[weak self] _ in
            guard let _self = self else { return }
            
            // When released
            if sender.state == .possible {
                _self.lblLink.backgroundColor = .clear
            }
        })
    }
    
    // Open the view
    private func openView() {
        if let nav = self.nav {
            let view = MiraikanUtil.createView(view: menu.view)
            nav.show(BaseController(view, title: menu.name), sender: nil)
        }
    }
    
}

// Layout for the menu
fileprivate class MenuContent: BaseView {
    
    private let loginRow = MenuRow(MenuItem(name: "ログイン", view: LoginView.self))
    private let lblSpex = UILabel()
    private let lblEvent = UILabel()
    private let sectionSpex = CardSection()
    private let sectionEvent = CardSection()
    
    private var sections = [MenuSection: [MenuRow]]()
    private var sectionList : [MenuSection]!
    
    private var newsList = [ArrowView]()
    
    private let margin = CGFloat(20)
    private let gap = CGFloat(30)
    private let sectionGap = CGFloat(10)
    
    var updated : (()->())?

    override func setup() {
        super.setup()
        
        // Show Login option in menu if it's not logged in
        if !MiraikanUtil.isLoggedIn { addSubview(loginRow) }
        
        // Special exhibition and events
        lblSpex.text = "特別展"
        lblEvent.text = "イベント"
        [lblSpex, lblEvent].forEach({
            $0.font = .boldSystemFont(ofSize: 16)
            $0.sizeToFit()
            addSubview($0)
        })
        
        // Getting the event details
        let year = MiraikanUtil.calendar().component(.year, from: Date())
        [sectionSpex: "/exhibitions/spexhibition/_assets/json/ja.json",
         sectionEvent: "/events/_assets/json/\(year)/ja.json"].forEach({
            let (section, address) = ($0.key, $0.value)
            section.load(endpoint: address, action: { [weak self] in
                guard let self = self else { return }
                // Update the content layout after generating the data
                if let f = self.updated {
                    f()
                }
            })
            addSubview(section)
         })
        
        sectionList = MenuSection.allCases
        sectionList.forEach({ sec in
            sections[sec] = sec.items.map({ MenuRow($0) })
        })
        sections.flatMap({ $0.value }).forEach({ addSubview($0) })
        ["常設展・ドームシアターはオンラインのチケット予約が必要です",
         "9月11日(土)18：00からニコニコ生放送　イグノーベル賞を科学コミュニケーターと楽しもう",
         "10月5日(火)から「ジオ・コスモス」の公開を一時休止します"].forEach({
            let row = ArrowView("・\($0)")
            newsList += [row]
            addSubview(row)
         })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = insets.top
        
        loginRow.frame = CGRect(x: insets.left,
                                y: y,
                                width: innerSize.width,
                                height: loginRow.sizeThatFits(innerSize).height)
        y += loginRow.sizeThatFits(frame.size).height
        
        lblSpex.frame.origin = CGPoint(x: insets.left, y: y)
        y += lblSpex.frame.height
        
        sectionSpex.frame = CGRect(origin: CGPoint(x: insets.left, y: y),
                                   size: sectionSpex.sizeThatFits(innerSize))
        y += sectionSpex.frame.height + sectionGap
        
        lblEvent.frame.origin = CGPoint(x: insets.left, y: y)
        y += lblEvent.frame.height + sectionGap
        
        sectionEvent.frame = CGRect(origin: CGPoint(x: insets.left, y: y),
                                    size: sectionEvent.sizeThatFits(innerSize))
        y += sectionEvent.frame.height + sectionGap
        
        func layoutRow(_ row: BaseView) {
            let sz = row.sizeThatFits(frame.size)
            row.frame = CGRect(x: insets.left,
                               y: y,
                               width: innerSize.width,
                               height: row.sizeThatFits(innerSize).height)
            y += sz.height
        }
        
        func layoutMenu(_ row: MenuRow) {
            layoutRow(row)
        }
        
        func layoutNews(_ row: ArrowView) {
            layoutRow(row)
        }
        
        sectionList.forEach({ sec in
            sections[sec]?.forEach({ layoutMenu($0) })
            
            if sec == .news {
                newsList.forEach({ layoutNews($0) })
            }
            
            y += gap
        })
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let paddingY = insets.top + gap
        let totalGap = gap * CGFloat(sectionList.count - 1)
        let totalNewsHeight = newsList.reduce(CGFloat(0),
                                              { $0 + $1.sizeThatFits(size).height })
        let loginRowHeight = loginRow.sizeThatFits(size).height
        let totalRowHeight = sections.flatMap({ $0.value })
            .reduce(CGFloat(0),
                    { $0 + $1.sizeThatFits(size).height })
        let spexHeight = [sectionSpex.sizeThatFits(innerSize),
                          lblSpex.intrinsicContentSize]
            .map({ $0.height }).reduce(sectionGap, { $0 + $1} )
        let eventHeight = [sectionEvent.sizeThatFits(innerSize),
                           lblEvent.intrinsicContentSize]
             .map({ $0.height }).reduce(sectionGap, { $0 + $1} )
        let height = [totalGap, loginRowHeight,
                      spexHeight, eventHeight,
                      totalNewsHeight, totalRowHeight]
            .reduce(paddingY, { $0 + $1 })
        
        return CGSize(width: size.width, height: height)
    }

}

class Home: BaseScrollView {
    
    override func setup() {
        let content = MenuContent()
        // Asynchronized action for http
        content.updated = { [weak self] in
            guard let self = self else { return }
            self.layoutSubviews()
        }
        super.setup(content)
    }
    
}
