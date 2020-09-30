//
//  Extension.swift
//  GestureWithSingleFinger
//
//  Created by MacBook Pro on 9/27/20.
//  Copyright © 2020 MacBook Pro. All rights reserved.
//

import UIKit

//MARK: Overlay View Information Structure
struct OverlayViewInfo {
    var view: OverlayLineView!
    var height: CGFloat!
    var width: CGFloat!
    var angle: CGFloat!
    var position: CGPoint!
    init(view: OverlayLineView, width: CGFloat, height: CGFloat, angle: CGFloat, position: CGPoint) {
        self.view = view
        self.height = height
        self.width = width
        self.angle = angle
        self.position = position
    }
}

//MARK: Views AnchorPoint Set

extension UIView {
    
    func setAnchorPoint(_ point: CGPoint) {
        var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
        var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y);

        newPoint = newPoint.applying(transform)
        oldPoint = oldPoint.applying(transform)

        var position = layer.position
        
        position.x -= oldPoint.x
        position.x += newPoint.x
        position.y -= oldPoint.y
        position.y += newPoint.y

        layer.position = position
        layer.anchorPoint = point
    }
    
}
