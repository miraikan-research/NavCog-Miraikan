//
//
//  VoiceGuideController.swift
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

private protocol AudioControlDelegate {
    func play()
    func pause()
    func playNext()
    func playPrevious()
}

private protocol AudioListDelegate {
    func detectBound(rowNumber: Int)
    func setPlaying(_ isPlaying: Bool)
    func checkStatus() -> Bool
}

fileprivate class VoiceGuideRow : BaseRow {
    
    private let lblDesc = AutoWrapLabel()
    
    public var title : String? {
        didSet {
            lblDesc.text = title
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = .clear
        lblDesc.numberOfLines = 0
        lblDesc.lineBreakMode = MiraikanUtil.wrappingMode
        lblDesc.textColor = .black
        addSubview(lblDesc)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let lblSz = CGSize(width: innerSize.width, height: 0)
        lblDesc.frame = CGRect(x: insets.left,
                               y: insets.top,
                               width: innerSize.width,
                               height: lblDesc.sizeThatFits(lblSz).height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let lblSz = CGSize(width: innerSizing(parentSize: size).width,
                           height: 0)
        let height = insets.top + insets.bottom + lblDesc.sizeThatFits(lblSz).height
        return CGSize(width: size.width, height: height)
    }
    
}

fileprivate class VoiceGuideListView : BaseListView, AudioControlDelegate {
    
    private let cellId = "cellId"
    private let tts = DefaultTTS()
    
    var listDelegate: AudioListDelegate?
    
    override var items: Any? {
        didSet {
            if let items = items as? [String] {
                self.tableView.reloadData()
                let row = items.count - 1
                self.tableView.selectRow(at: IndexPath(row: row, section: 0),
                                         animated: true,
                                         scrollPosition: .bottom)
                listDelegate?.detectBound(rowNumber: row)
                play(row: row)
            }
        }
    }
    
    override func initTable(isSelectionAllowed: Bool) {
        super.initTable(isSelectionAllowed: true)
        
        self.tableView.register(VoiceGuideRow.self, forCellReuseIdentifier: cellId)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let description = (items as? [String])?[indexPath.row],
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
            as? VoiceGuideRow {
            cell.title = description
            return cell
        }
        return UITableViewCell()
    }
    
    func play() {
        let selected = self.tableView.indexPathForSelectedRow!
        play(row: selected.row)
    }
    
    func pause() {
        tts.stop(true)
    }
    
    func playNext() {
        if let isPlaying = self.listDelegate?.checkStatus() {
            tts.stop(isPlaying)
        }
        let selected = self.tableView.indexPathForSelectedRow!
        let next = IndexPath(row: selected.row + 1, section: selected.section)
        self.tableView.selectRow(at: next, animated: true, scrollPosition: .bottom)
        listDelegate?.detectBound(rowNumber: next.row)
        play(row: next.row)
    }
    
    func playPrevious() {
        if let isPlaying = self.listDelegate?.checkStatus() {
            tts.stop(isPlaying)
        }
        let selected = self.tableView.indexPathForSelectedRow!
        let prev = IndexPath(row: selected.row - 1, section: selected.section)
        self.tableView.selectRow(at: prev, animated: true, scrollPosition: .bottom)
        listDelegate?.detectBound(rowNumber: prev.row)
        play(row: prev.row)
    }
    
    private func play(row: Int) {
        guard let title = (items as? [String])?[row] else { return }
        print(title)
        self.listDelegate?.setPlaying(true)
        tts.speak(title, callback: { [weak self] in
            guard let self = self else { return }
            self.listDelegate?.setPlaying(false)
        })
    }
    
}

fileprivate class PanelView : BaseView {
    
    private enum AudioControl : Int, CaseIterable {
        case main
        case prev
        case next
        
        var imgName : String {
            switch self {
            case .main:
                return "play"
            case .prev:
                return "backward"
            case .next:
                return "forward"
            }
        }
    }
    
    private var controls = [AudioControl: BaseButton]()
    
    private(set) var isPlaying : Bool = false
    
    var delegate : AudioControlDelegate?
    
    override func setup() {
        super.setup()
        
        let config = UIImage.SymbolConfiguration(pointSize: 40)
        AudioControl.allCases.forEach({ control in
            let btn = BaseButton()
            
            let imgName = "\(control.imgName).fill"
            let img = UIImage(systemName: imgName, withConfiguration: config)
            btn.setImage(img, for: .normal)
            btn.imageView?.tintColor = btn.isEnabled ? .systemBlue : .gray
            btn.sizeToFit()
            btn.tag = control.rawValue
            btn.tapAction({ btn in
                controlAction(btn)
            })
            controls[control] = btn
            addSubview(btn)
        })
        
        func controlAction(_ btn: UIButton) {
            let control = AudioControl(rawValue: btn.tag)!
            switch control {
            case .main:
                isPlaying = !isPlaying
                isPlaying ? delegate?.play() : delegate?.pause()
            case .prev:
                delegate?.playPrevious()
                print("Previous description")
            case .next:
                delegate?.playNext()
                print("Next description")
            }
        }
        
    }
    
    override func layoutSubviews() {
        guard let btnMain = controls[.main] else { return }
        guard let btnPrev = controls[.prev] else { return }
        guard let btnNext = controls[.next] else { return }
        btnMain.center.x = self.center.x
        btnMain.frame.origin.y = self.frame.height - paddingAboveTab - btnMain.frame.height
        btnPrev.center.y = btnMain.center.y
        btnPrev.center.x = self.center.x / 2
        btnNext.center.y = btnMain.center.y
        btnNext.center.x = self.frame.width - self.center.x / 2
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let btnMain = controls[.main] else { return .zero }
        let height = insets.top + paddingAboveTab + btnMain.frame.height
        return CGSize(width: size.width, height: height)
    }
    
    public func updateControl(isTop: Bool, isBottom: Bool) {
        guard let btnPrev = controls[.prev] else { return }
        guard let btnNext = controls[.next] else { return }
        btnPrev.isEnabled = !isTop
        btnNext.isEnabled = !isBottom
    }
    
    public func setPlaying(_ isPlaying: Bool, isFinished : Bool = false) {
        self.isPlaying = isPlaying
        let config = UIImage.SymbolConfiguration(pointSize: 40)
        let imgName = isPlaying ? "stop" : "play"
        let img = UIImage(systemName: "\(imgName).fill", withConfiguration: config)
        let btnMain = controls[.main]!
        btnMain.setImage(img, for: .normal)
    }
    
}

class VoiceGuideController: BaseController {
    
    private class InnerView : BaseView, AudioListDelegate{
        
        private let listView = VoiceGuideListView()
        private let panelView = PanelView()
        
        public var items: [String]? {
            didSet {
                listView.items = items
            }
        }
        
        override func setup() {
            super.setup()
            
            listView.listDelegate = self
            panelView.delegate = listView
            addSubview(listView)
            addSubview(panelView)
        }
        
        override func layoutSubviews() {
            let szPanel = panelView.sizeThatFits(self.frame.size)
            let listHeight = self.frame.height - szPanel.height
            panelView.frame = CGRect(origin: CGPoint(x: 0, y: listHeight),
                                     size: szPanel)
            listView.frame = CGRect(x: 0, y: 0, width: frame.width, height: listHeight)
        }
        
        func detectBound(rowNumber: Int) {
            guard let count = items?.count else { return }
            panelView.updateControl(isTop: rowNumber == 0,
                                    isBottom: rowNumber == count - 1)
        }
        
        func setPlaying(_ isPlaying: Bool) {
            panelView.setPlaying(isPlaying)
        }
        
        func checkStatus() -> Bool {
            return panelView.isPlaying
        }
        
    }
    
    private let innerView = InnerView()
    
    public var items : [String]? {
        didSet {
            innerView.items = items
        }
    }
    
    @objc init(title: String?) {
        super.init(innerView, title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func setItems(_ items: [String]) {
        self.items = items
    }
    
}
