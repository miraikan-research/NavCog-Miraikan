//
//
//  NaviSettingController.swift
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
import simd

fileprivate class CurrentLocationRow : BaseRow {
    
    private let lblDescription = UILabel()
    private let lblLocation = UILabel()
    
    private let gap: CGFloat = 10
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        lblDescription.text = NSLocalizedString("Current Location", comment: "")
        lblDescription.font = .boldSystemFont(ofSize: 16)
        lblDescription.sizeToFit()
        if MiraikanUtil.isLocated {
            guard let loc = MiraikanUtil.location else { return }
            lblLocation.text = "\(loc.lat), \(loc.lng), \(loc.floor)F"
        } else {
            lblLocation.text = NSLocalizedString("not_located", comment: "")
        }
        lblLocation.adjustsFontSizeToFitWidth = true
        lblLocation.numberOfLines = 1
        lblLocation.lineBreakMode = .byClipping
        lblLocation.sizeToFit()
        addSubview(lblDescription)
        addSubview(lblLocation)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        lblDescription.frame.origin = CGPoint(x: insets.left, y: insets.top)
        lblLocation.frame.origin = CGPoint(x: insets.left, y: insets.top + lblDescription.frame.height + gap)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let totalHeight = [insets.top,
                           lblDescription.intrinsicContentSize.height,
                           lblLocation.intrinsicContentSize.height,
                           insets.bottom].reduce(gap, { $0 + $1 })
        return CGSize(width: size.width, height: totalHeight)
    }
    
}

fileprivate struct SwitchModel {
    let desc: String
    let key: String
    let isOn : Bool
    let isEnabled : Bool?
}

fileprivate class SwitchRow : BaseRow {
    
    private let lblDescription = UILabel()
    private let sw = BaseSwitch()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        lblDescription.font = .boldSystemFont(ofSize: 16)
        addSubview(lblDescription)
        sw.sizeToFit()
        addSubview(sw)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(_ model : SwitchModel) {
        lblDescription.text = model.desc
        lblDescription.sizeToFit()
        
        sw.isOn = model.isOn
        if let isEnabled = model.isEnabled {
            sw.isEnabled = isEnabled
        }
        sw.onSwitch({ sw in
            UserDefaults.standard.set(sw.isOn, forKey: model.key)
        })
    }
    
    override func layoutSubviews() {
//        let maxHeight = max(lblDescription.intrinsicContentSize.height,
//                            sw.intrinsicContentSize.height)
        let midY = max(lblDescription.intrinsicContentSize.height,
                       sw.intrinsicContentSize.height) / 2 + insets.top
        lblDescription.frame.origin.x = insets.left
        lblDescription.center.y = midY
        sw.frame.origin.x = frame.width - insets.right - sw.frame.width
        sw.center.y = midY
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let totalHeight = [insets.top,
                           max(lblDescription.intrinsicContentSize.height,
                               sw.intrinsicContentSize.height),
                           insets.bottom].reduce(0, { $0 + $1 })
        return CGSize(width: size.width, height: totalHeight)
    }
    
}

fileprivate struct SliderModel {
    let min : Float
    let max : Float
    let defaultValue : Float
    let step: Float
    let format: String
    let title: String
    let name: String
    let desc: String
}

fileprivate class SliderRow : BaseRow {
    
    private let lblDescription = UILabel()
    private let lblValue = UILabel()
    private let slider = UISlider()
    
    private var model : SliderModel?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        lblDescription.font = .boldSystemFont(ofSize: 16)
        addSubview(lblDescription)
        lblValue.textAlignment = .left
        addSubview(lblValue)
        slider.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        addSubview(slider)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(_ model: SliderModel) {
        lblDescription.text = model.title
        lblDescription.sizeToFit()
        let val = model.defaultValue
        lblValue.text = String(format: model.format,
                               round(val) == val ? Int(val) : val)
        let txtVal = "\(model.desc) \(lblValue.text!)"
        lblValue.accessibilityLabel = "label: \(txtVal)"
        self.model = model
        slider.minimumValue = model.min
        slider.maximumValue = model.max
        slider.value = model.defaultValue
        slider.accessibilityValue = txtVal
    }
    
    @objc private func valueChanged(_ sender: UISlider) {
        if let step = model?.step,
            let fmt = model?.format,
            let name = model?.name,
            let desc = model?.desc {
            let val = round(sender.value / step) * step
            print("\(sender.value), \(val)")
            sender.value = val
            let updated = String(format: fmt, round(step) == step ? Int(val) : val)
            let current = lblValue.text
            if updated != current {
                lblValue.text = updated
                let txtVal = "\(desc) \(updated)"
                lblValue.accessibilityLabel = "label: \(txtVal)"
                UserDefaults.standard.set(val, forKey: name)
                if name == NSLocalizedString("Speech Speed", comment: "") {
                    slider.accessibilityValue = ""
                    let tts = DefaultTTS()
                    tts.speak(txtVal, callback: { [weak self] in
                        guard let self = self else { return }
                        self.slider.accessibilityValue = txtVal
                    })
                } else {
                    self.slider.accessibilityValue = txtVal
                }
            }
        }
        
    }
    
    override func layoutSubviews() {
        var y = insets.top
        lblDescription.frame.origin = CGPoint(x: insets.left, y: insets.top)
        y += lblDescription.frame.height
        
        let colLeftWidth: CGFloat = innerSize.width / 5
        let colRightWidth: CGFloat = colLeftWidth * 4
        
        lblValue.frame = CGRect(x: insets.left,
                                y: y,
                                width: colLeftWidth,
                                height: lblValue.intrinsicContentSize.height)
        slider.center.y = lblValue.center.y
        slider.frame.origin.x = insets.left + colLeftWidth
        slider.frame.size.width = colRightWidth
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height = [lblValue, lblDescription]
            .map({ $0.intrinsicContentSize.height })
            .reduce((insets.top + insets.bottom), { $0 + $1 })
        return CGSize(width: size.width, height: height)
    }
    
}

class NaviSettingController : BaseListController, BaseListDelegate {
    
    private let locationId = "locationCell"
    private let switchId = "switchCell"
    private let sliderId = "sliderCell"
    
    private struct CellModel {
        let cellId : String
        let model : Any?
    }
    
    override func initTable() {
        super.initTable()
        
        self.baseDelegate = self
        self.tableView.register(CurrentLocationRow.self, forCellReuseIdentifier: locationId)
        self.tableView.register(SwitchRow.self, forCellReuseIdentifier: switchId)
        self.tableView.register(SliderRow.self, forCellReuseIdentifier: sliderId)
        
        self.items = [CellModel(cellId: locationId, model: nil),
                      CellModel(cellId: switchId,
                                model: SwitchModel(desc: NSLocalizedString("Preview", comment: ""),
                                                   key: "OnPreview",
                                                   isOn: MiraikanUtil.isPreview,
                                                   isEnabled: MiraikanUtil.isLocated)),
                      CellModel(cellId: sliderId,
                                model: SliderModel(min: 1,
                                                   max: 10,
                                                   defaultValue: MiraikanUtil.previewSpeed,
                                                   step: 1,
                                                   format: "%d",
                                                   title: NSLocalizedString("Preview Speed", comment: "Name of the label"),
                                                   name: "preview_speed",
                                                   desc: NSLocalizedString("Preview Speed Description",
                                                                           comment: "Description for VoiceOver"))),
                      CellModel(cellId: switchId,
                                model: SwitchModel(desc: NSLocalizedString("Voice Guide", comment: ""),
                                                   key: "isVoiceGuideOn",
                                                   isOn: UserDefaults.standard.bool(forKey: "isVoiceGuideOn"),
                                                   isEnabled: nil)),
                      CellModel(cellId: sliderId,
                                model: SliderModel(min: 0.1,
                                                   max: 1,
                                                   defaultValue: MiraikanUtil.speechSpeed,
                                                   step: 0.05,
                                                   format: "%.2f",
                                                   title: NSLocalizedString("Speech Speed", comment: "Name of the label"),
                                                   name: "speech_speed",
                                                   desc: NSLocalizedString("Speech Speed Description",
                                                                           comment: "Description for VoiceOver")))]
    }
    
    func getCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        let item = (items as? [CellModel])?[indexPath.row]
        guard let cellId = item?.cellId else { return nil }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        if let locationCell = cell as? CurrentLocationRow {
            return locationCell
        } else if let swCell = cell as? SwitchRow, let model = item?.model as? SwitchModel {
            swCell.configure(model)
            return swCell
        } else if let sliderCell = cell as? SliderRow,
                    let model = item?.model as? SliderModel {
            sliderCell.configure(model)
            return sliderCell
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
    }
    
}
