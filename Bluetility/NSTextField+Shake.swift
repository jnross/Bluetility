//
//  NSTextField+Shake.swift
//  Bluetility
//
//  Created by Joseph Ross on 9/28/19.
//  Copyright © 2019 Joseph Ross. All rights reserved.
//

import AppKit

extension NSTextField {
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.05
        animation.repeatCount = 5
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: self.frame.origin.x - 4.0, y: self.frame.origin.y)
        animation.toValue = CGPoint(x: self.frame.origin.x + 4.0, y: self.frame.origin.y)
        layer?.add(animation, forKey: "position")
    }
}
