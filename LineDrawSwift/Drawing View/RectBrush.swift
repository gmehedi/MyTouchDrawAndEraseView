//
//  RectBrush.swift
//  DrawView
//
//  Created by liuxiang on 2017/12/26.
//  Copyright © 2017年 liuxiang. All rights reserved.
//

import UIKit

open class RectBrush: BaseBrush {
    
    public override init() {
        super.init()
        type = .rect
    }
    
    internal override func drawInContext() {
        print("RectBrush rawInContext() ")
        let context = initContext(type: .rect)
        context?.addRect(CGRect(origin: CGPoint(x: min(beginPoint!.x, currentPoint!.x), y: min(beginPoint!.y, currentPoint!.y)),
                                size: CGSize(width: abs(currentPoint!.x - beginPoint!.x), height: abs(currentPoint!.y - beginPoint!.y))))
        context?.strokePath()
    }
    
}
