//
//
//  LocationInputView.swift
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
import UIKit


enum HLPLocationItem: Int {
    case Latitude = 0
    case Longitude
    case Accuracy
    case Floor
    case Speed
    case Orientation
    case OrientationAccuracy
}

class LocationInputView: UIButton, UITextFieldDelegate {

    @IBOutlet var textField: [UITextField] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.nibInit()
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.nibInit()
        self.setup()
    }

    fileprivate func nibInit() {
        guard let view = UINib(nibName: "LocationInputView", bundle: nil).instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }

        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(view)
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }

    private func setup() {
        setupDesign()
        setupAction()
    }

    private func setupDesign() {
        
        self.backgroundColor = .systemBackground
        self.layer.cornerRadius = 30

        self.layer.borderColor = UIColor(red: 105/255, green: 0, blue: 50/255, alpha: 1).cgColor
        self.layer.borderWidth = 6.0

        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
        
        textField[HLPLocationItem.Latitude.rawValue].text = "35.61905"
        textField[HLPLocationItem.Longitude.rawValue].text = "139.776347"
        textField[HLPLocationItem.Accuracy.rawValue].text = "0"
        textField[HLPLocationItem.Floor.rawValue].text = "4"
        textField[HLPLocationItem.Speed.rawValue].text = "0"
        textField[HLPLocationItem.Orientation.rawValue].text = "0"
        textField[HLPLocationItem.OrientationAccuracy.rawValue].text = "0"
        
        self.alpha = 0

        for field in textField {
            field.delegate = self
        }
    }

    private func setupAction() {
        self.addTarget(self, action: #selector(self.viewTapped(_:)), for: .touchUpInside)
    }

    @objc func viewTapped(_ sender: UIView) {
        for field in textField {
            field.resignFirstResponder()
        }
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        
        for field in textField {
            if field.text?.isEmpty ?? false {
                return
            }
        }
        
        let data: [AnyHashable: Any] = [
            "lat": textField[HLPLocationItem.Latitude.rawValue].text as Any,
            "lng": textField[HLPLocationItem.Longitude.rawValue].text as Any,
            "accuracy": textField[HLPLocationItem.Accuracy.rawValue].text as Any,
            "floor": textField[HLPLocationItem.Floor.rawValue].text as Any,
            "speed": textField[HLPLocationItem.Speed.rawValue].text as Any,
            "orientation": textField[HLPLocationItem.Orientation.rawValue].text as Any,
            "orientationAccuracy": textField[HLPLocationItem.OrientationAccuracy.rawValue].text as Any
        ]

        let center = NotificationCenter.default
        center.post(name: NSNotification.Name(rawValue: "REQUEST_LOCATION_STOP"), object: self)
        center.post(name: NSNotification.Name(rawValue: "location_changed_notification"), object: self, userInfo: data)
        
        UserDefaults.standard.set(false, forKey: "isLocationInput")
        self.endEditing(true)
    }

    func isDisplayButton(_ isDisplay: Bool) {
        if (self.alpha == 1) == isDisplay {
            return
        }

        DispatchQueue.main.async{
            self.alpha = isDisplay ? 0 : 1
            UIView.animate(withDuration: 0.1, animations: { [weak self] in
                guard let self = self else { return }
                self.alpha = isDisplay ? 1 : 0
            })
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func didTapView(_ sender: UITapGestureRecognizer) {
        self.endEditing(true)
    }
}
