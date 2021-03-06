//
//
//  LandmarkModel.swift
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

class LandmarkModel {
    
    let id: String
    let nodeId: String
    let title: String
    let titlePron: String
    let nodeLocation: HLPLocation
    let spotLocation: HLPLocation
    var distance: Double = 0

    init(id: String,
         nodeId: String,
         title: String,
         titlePron: String,
         nodeLocation: HLPLocation,
         spotLocation: HLPLocation) {
        self.id = id
        self.nodeId = nodeId
        self.title = title
        self.titlePron = titlePron
        self.nodeLocation = nodeLocation
        self.spotLocation = spotLocation
    }
}

class PositionModel {
    let id: String
    let titlePron: String
    var distance: Double = 0
    var angle: Double = 0

    init(id: String,  titlePron: String) {
        self.id = id
        self.titlePron = titlePron
    }
}
