//
//  LineBrush.swift
//  DrawView
//
//  Created by liuxiang on 2018/1/4.
//  Copyright © 2018年 liuxiang. All rights reserved.
//

import UIKit

open class LineBrush: BaseBrush {
    
    public override init() {
        super.init()
        type = .line
    }

    internal override func drawInContext() {
        ///  print("LineBrush drawInContext()")
        let context = initContext(type: .line)
        context?.addLines(between: [beginPoint!, currentPoint!])
        /// print("Begin  point   ", beginPoint!, currentPoint!)
        context?.strokePath()
    }
    
}
