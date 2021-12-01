//
//
//  AIController.swift
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
 The view to show before AI Dialog starts and after it ends
 */
class AIView : BaseView {
    
    private let btnStart = StyledButton()
    
    override func setup() {
        super.setup()
        
        let dialogManager = DialogManager.sharedManager()
        let desc = dialogManager.isAvailable
            ? NSLocalizedString("ai_available", comment: "")
            : NSLocalizedString("ai_not_available", comment: "")
        btnStart.setTitle(desc, for: .normal)
        btnStart.setTitleColor(.lightText, for: .disabled)
        btnStart.isEnabled = dialogManager.isAvailable
        if !dialogManager.isAvailable {
            btnStart.backgroundColor = .lightGray
            btnStart.layer.borderColor = UIColor.lightGray.cgColor
        }
        btnStart.sizeToFit()
        btnStart.tapAction({ [weak self] _ in
            guard let self = self else { return }
            if !dialogManager.isAvailable { return }
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.aiNavi(note:)),
                                                   name: Notification.Name(rawValue:"request_start_navigation"),
                                                   object: nil)
            
            dialogManager.userMode = "user_\(MiraikanUtil.routeMode)"
            let dialogVC = DialogViewController()
            dialogVC.tts = DefaultTTS()
            dialogVC.title = self.parentVC?.title
            if let nav = self.navVC {
                nav.show(dialogVC, sender: nil)
            }
        })
        addSubview(btnStart)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        btnStart.center = self.center
    }
    
    @objc func aiNavi(note: Notification) {
        guard let toID = note.userInfo?["toID"] as? String else { return }
        guard let nav = self.navVC else { return }
        nav.openMap(nodeId: toID)
    }
    
}
