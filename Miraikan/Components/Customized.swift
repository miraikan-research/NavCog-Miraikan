//
//  Customized.swift
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

// Temporarily used for rows, make them look like menu items
// The arrow is set inaccessibly from VoiceOver, temporarily like an icon
class ArrowView: BaseView {
    private let lblMain = UILabel()
    private let lblArrow = UILabel()
    
    init(_ text: String) {
        super.init(frame: .zero)
        setup(text)
    }
    
    private func setup(_ text: String) {
        lblMain.text = text
        lblMain.numberOfLines = 0
        lblMain.lineBreakMode = .byCharWrapping
        lblArrow.text = " >"
        lblArrow.isAccessibilityElement = false
        lblArrow.sizeToFit()
        
        [lblMain, lblArrow].forEach({
            $0.font = .boldSystemFont(ofSize: 16)
            addSubview($0)
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let point: CGPoint = .zero
        let szMain = lblMain.intrinsicContentSize
        let wMain = min(szMain.width, frame.width - lblArrow.frame.width)
        let szMainFit = CGSize(width: wMain, height: szMain.height)
        lblMain.frame = CGRect(origin: point,
                               size: CGSize(width: wMain,
                                            height: lblMain.sizeThatFits(szMainFit).height))
        lblArrow.frame.origin = CGPoint(x: lblMain.frame.width, y: point.y)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let sz = innerSizing(parentSize: size)
        let szMainFit = CGSize(width: sz.width - lblArrow.frame.width,
                               height: lblMain.intrinsicContentSize.height)
        let szMain = CGSize(width: sz.width - lblArrow.frame.width,
                            height: lblMain.sizeThatFits(szMainFit).height)
        let height = [szMain.height, lblArrow.frame.height].max()!
        return CGSize(width: sz.width, height: height)
    }
    
}

// A label that automatically wrap its text to fit the size
// TODO: byWordWrapping for English version
class AutoWrapLabel: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.numberOfLines = 0
        self.lineBreakMode = .byCharWrapping
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// A AutoWrapLabel underlined which looks like a link
class UnderlinedLabel: AutoWrapLabel {
    
    private var action: ((UnderlinedLabel) -> ())?
    
    public var title: String? {
        didSet {
            if let title = title {
                setText(title)
            }
        }
    }
    
    init(_ text: String? = nil) {
        super.init(frame: .zero)
        if let text = text {
            setText(text)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setText(_ text: String) {
        let attr: [NSAttributedString.Key : Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        let str = NSMutableAttributedString(string: text,
                                            attributes: attr)
        self.attributedText = str
    }
    
    public func openView(_ action: @escaping ((UnderlinedLabel) -> ())) {
        self.action = action
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tap)
    }
    
    @objc private func tapAction() {
        if let f = action {
            f(self)
        }
    }
    
}

// A button with tap action implemented for easier use
class BaseButton: UIButton {
    
    private var action: ((UIButton)->())?

    public func tapInside(_ action: @escaping ((UIButton)->())) {
        self.action = action
        self.addTarget(self, action: #selector(tapAction(_:)), for: .touchUpInside)
    }

    @objc private func tapAction(_ sender: UIButton) {
        if let _f = action {
            _f(self)
        }
    }
    
}

// A BaseButton with the style for Navigation
class NaviButton: BaseButton {
    
    var paddingX: CGFloat {
        return self.titleEdgeInsets.left + self.titleEdgeInsets.right
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.setTitleColor(.blue, for: .normal)
        self.layer.cornerRadius = 5
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.blue.cgColor
        self.layer.backgroundColor = UIColor.white.cgColor
        self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
    }
    
}

// A button for HTML style RadioGroup
class RadioButton: BaseButton {
    
    var isChecked : Bool {
        didSet {
            setImage()
            layoutSubviews()
        }
    }
    
    private let radioSize = CGSize(width: 24, height: 24)
    
    override init(frame: CGRect) {
        isChecked = false
        super.init(frame: frame)
        setImage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setImage() {
        let imgName = isChecked ? "radio_checked" : "radio_unchecked"
        let img = UIImage(named: imgName)
        self.titleLabel?.sizeToFit()
        self.setImage(img, for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let imgSize = CGSize(width: 46, height: 46)
        let scaleFactor = MiraikanUtil.calculateScaleFactor(radioSize,
                                                    frameWidth: radioSize.width,
                                                    imageSize: imgSize)
    
        self.imageView?.frame = CGRect(x: 0,
                                       y: 0,
                                       width: imgSize.width * scaleFactor,
                                       height: imgSize.height * scaleFactor)
        self.titleLabel?.frame.size = CGSize(width: self.frame.width - radioSize.width,
                                             height: self.titleLabel!.intrinsicContentSize.height)
        self.titleLabel?.frame.origin.x = radioSize.width + CGFloat(10)
        self.titleLabel?.center.y = self.imageView!.center.y
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height = min(radioSize.height, self.titleLabel!.intrinsicContentSize.height)
        return CGSize(width: size.width, height: height)
    }
    
}
