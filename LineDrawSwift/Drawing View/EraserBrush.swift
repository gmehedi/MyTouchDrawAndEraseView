//
//  EraserBrush.swift
//  DrawView
//
//  Created by liuxiang on 2017/12/26.
//  Copyright © 2017年 liuxiang. All rights reserved.
//

import UIKit

open class EraserBrush: PenBrush {
    
    public override init() {
        super.init()
        type = .eraser
    }
    
    override func drawInContext() {
   ///  print("EraserBrush drawInContext()")
        let context = initContext(type: .pen)
        context?.setBlendMode(.clear)
        context?.addPath(path)
        context?.strokePath()
    }
    
}
