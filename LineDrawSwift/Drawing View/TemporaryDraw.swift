//
//  TemporaryDraw.swift
//  LineDrawSwift
//
//  Created by MacBook Pro on 9/28/20.
//  Copyright © 2020 MacBook Pro. All rights reserved.
//

import UIKit

class TemporaryDraw: NSObject {
    func eraseDrawing(path: CGMutablePath){
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(20)
        context?.setBlendMode(.clear)
        context?.addPath(path)
        context?.strokePath()
        print("lalal")
    }
}
