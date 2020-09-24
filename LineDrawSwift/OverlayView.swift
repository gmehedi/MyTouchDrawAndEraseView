//
//  OverLayView.swift
//  LineDrawSwift
//
//  Created by MacBook Pro on 9/24/20.
//  Copyright © 2020 MacBook Pro. All rights reserved.
//

import UIKit

enum OverlayViewTypes{
    case normalLine
    case rectangle
    case ellips
    case none
}

class OverlayView: NSObject {
    
    var type: OverlayViewTypes = .normalLine
    var overlay = UIView()
    var crossButton = UIButton()
    var scaleButton = UIButton()
    var minimumSize: CGFloat = 40.0
    
    func setOverLayView(locations: CGPoint){
        switch type {
        case .normalLine:
            overlay.frame = CGRect(x: locations.x, y: locations.y, width: 40, height: 20)
            setButton()
        case .rectangle:
            overlay.frame = CGRect(x: locations.x, y: locations.y, width: 100, height: 100)
        case .ellips:
            overlay.frame = CGRect(x: locations.x, y: locations.y, width: 100, height: 100)
        default:
            overlay.frame = CGRect(x: locations.x, y: locations.y, width: 100, height: 100)
        }
        overlay.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        setButton()
    }
    func setButton(){
        crossButton.frame = CGRect(x: -20, y:-20, width: 40, height: 40)
        crossButton.image(for: .normal)
        crossButton.imageView?.image = UIImage(named: "cross")
        
        scaleButton.frame = CGRect(x: 60, y: 60, width: 40, height: 40)
        crossButton.image(for: .normal)
        crossButton.imageView?.image = UIImage(named: "resize")
        overlay.addSubview(crossButton)
        overlay.addSubview(scaleButton)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRotateGesture))
        scaleButton.addGestureRecognizer(panGesture)
    }
    
}

extension OverlayView{
    
    @objc func handleRotateGesture(_ recognizer: UIPanGestureRecognizer) {
           let touchLocation = recognizer.location(in: self.scaleButton)
        let center = self.overlay.center
        var initialBounds: CGRect!
        var initialDistance: CGFloat!
        var deltaAngle: CGFloat!
        
           switch recognizer.state {
           case .began:
            deltaAngle = CGFloat(atan2f(Float(touchLocation.y - self.overlay.center.y), Float(touchLocation.x - self.overlay.center.x))) - CGAffineTransformGetAngle(self.overlay.transform)
               initialBounds = self.overlay.bounds
               initialDistance = CGPointGetDistance(point1: center, point2: touchLocation)
//               if let delegate = self.delegate {
//                   delegate.stickerViewDidBeginRotating(self)
//               }
           case .changed:
               print("Scale Change")
               let angle = atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))
               let angleDiff = Float(deltaAngle) - angle
               self.overlay.transform = CGAffineTransform(rotationAngle: CGFloat(-angleDiff))
               
               var scale = CGPointGetDistance(point1: center, point2: touchLocation)
               let minimumScale = CGFloat(self.minimumSize) / CGFloat(min(self.overlay.bounds.size.width, self.overlay.bounds.size.height))
               scale = max(scale, minimumScale)
               let scaledBounds = CGRectScale(initialBounds, wScale: scale, hScale: scale)
               self.overlay.bounds = scaledBounds
               self.overlay.setNeedsDisplay()
               
//               if let delegate = self.delegate {
//                   delegate.stickerViewDidChangeRotating(self)
//               }
           case .ended:
            print("End")
//               if let delegate = self.delegate {
//                   delegate.stickerViewDidEndRotating(self)
//               }
           default:
               break
           }
       }
    
    func CGRectGetCenter(_ rect:CGRect) -> CGPoint {
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    func CGRectScale(_ rect:CGRect, wScale:CGFloat, hScale:CGFloat) -> CGRect {
        return CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width * wScale, height: rect.size.height * hScale)
    }

    func CGAffineTransformGetAngle(_ t:CGAffineTransform) -> CGFloat {
        return atan2(t.b, t.a)
    }

    func CGPointGetDistance(point1:CGPoint, point2:CGPoint) -> CGFloat {
        let fx = point2.x - point1.x
        let fy = point2.y - point1.y
        return sqrt(fx * fx + fy * fy)
    }
}
