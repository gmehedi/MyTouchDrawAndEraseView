//
//  DrawView.swift
//  DrawView
//
//  Created by liuxiang on 2017/12/25.
//  Copyright © 2018年 liuxiang. All rights reserved.
//

import UIKit

public protocol TouchDrawViewDelegate: class {
    
    func undoEnable(_ isEnable: Bool)
    func redoEnable(_ isEnable: Bool)
    func addLine(frame: CGRect, angle: CGFloat)
}

public extension TouchDrawViewDelegate {
    
    func undoEnable(_ isEnable: Bool) { }
    func redoEnable(_ isEnable: Bool) { }
}

open class TouchDrawView: UIView {
    
    open weak var delegate: TouchDrawViewDelegate?
    
    var lineWidth: CGFloat = 5
    var lineColor = UIColor.red
    var lineAlpha: CGFloat = 1  
    var brushType: BrushType = .none
    var deltaAngle: CGFloat!
    
    fileprivate var brush: BaseBrush?
    fileprivate var brushStack = [BaseBrush]()
    fileprivate var drawUndoManager = UndoManager()
    fileprivate var drawImageView = DrawImageView()
    
    fileprivate var prevImage: UIImage?
    fileprivate var image: UIImage?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSubview(drawImageView)
        drawImageView.backgroundColor = UIColor.clear
    }
  
    // Sets the frames of the subviews
    override open func draw(_ rect: CGRect) {
        print("Draw")
        image?.draw(in: bounds)
        drawImageView.frame = self.bounds
    }
    
    // MARK: - Public
    open func setBrushType(_ type: BrushType) {
        print("T1 .................................................................  ", type)
        brushType = type
    }
    
    open func setDrawLineColor(_ color: UIColor) {
        lineColor = color
    }
    
    open func setDrawLineWidth(_ width: CGFloat) {
        lineWidth = width
    }
    
    open func setDrawLineAlpha(_ alpha: CGFloat) {
        lineAlpha = alpha
    }
    
    open func setImage(_ image: UIImage) {
        self.image = image
        self.setNeedsDisplay()
    }
    
    open func undo() {
        print("Undo  ")
        if drawUndoManager.canUndo {
            drawUndoManager.undo()
            delegate?.redoEnable(drawUndoManager.canRedo)
            delegate?.undoEnable(drawUndoManager.canUndo)
        }
    }
    
    open func redo() {
         print("Redo  ")
        if drawUndoManager.canRedo {
            drawUndoManager.redo()
            delegate?.undoEnable(drawUndoManager.canUndo)
            delegate?.redoEnable(drawUndoManager.canRedo)
        }
    }
    
    open func clear() {
        print("Clear")
        clearDraw()
    }
    
    // Export drawn image
    open func exportImage() -> UIImage? {
        print("Wxport Image")
        beginImageContext()
        self.image?.draw(in: self.bounds)
        drawImageView.image?.draw(in: self.bounds)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    // MARK: - Private
    fileprivate func initBrushType() -> BaseBrush? {
        print("initBrush()")
        switch brushType {
        case .pen:
            return PenBrush()
        case .eraser:
            return EraserBrush()
        case .rect:
            return RectBrush()
        case .line:
            return LineBrush()
        case .ellipse:
            return EllipseBrush()
        case .none:
            return nil
        }
    }
}

extension TouchDrawView {
    
    // MARK: - UITouches
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
        guard let allTouches = event?.allTouches else { return }
        if allTouches.count > 1 { return }
        brush = initBrushType()
        drawImageView.brush = brush
        drawImageView.type = self.brushType
   
        brush?.beginPoint = touches.first?.location(in: self)
        brush?.currentPoint = touches.first?.location(in: self)
        brush?.previousPoint1 =  touches.first?.previousLocation(in: self)
        brush?.lineColor = lineColor
        brush?.lineAlpha = lineAlpha
        brush?.lineWidth = lineWidth
        brush?.points.append(touches.first!.location(in: self))
        
//        if self.brushType == .line {
//            self.deltaAngle = CGFloat(atan2f(Float(touches.y - center.y), Float(touchLocation.x - center.x))) - CGAffineTransformGetAngle(self.transform)
//        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
      //  print("touches  54 454545   Moved")
        guard let allTouches = event?.allTouches else { return }
        if allTouches.count > 1 { return }
        
        if let brush = self.brush {
            brush.previousPoint2 = brush.previousPoint1
            brush.previousPoint1 = touches.first?.previousLocation(in: self)
            brush.currentPoint = touches.first?.location(in: self)
            brush.points.append(touches.first!.location(in: self))
            
            if let penBrush = brush as? PenBrush {
                var drawBox = penBrush.addPathInBound()
                drawBox.origin.x -= lineWidth * 1
                drawBox.origin.y -= lineWidth * 1
                drawBox.size.width += lineWidth * 2
                drawBox.size.height += lineWidth * 2
                self.drawImageView.setNeedsDisplay(drawBox)
                
            } else {
                self.drawImageView.setNeedsDisplay()
            }
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touch End")
        if let brush = self.brush, brush.points.count >= 2 {
            brushStack.append(brush)
            drawUndoManager.registerUndo(withTarget: self, selector: #selector(popBrushStack), object: nil)
            delegate?.undoEnable(drawUndoManager.canUndo)
            delegate?.redoEnable(drawUndoManager.canRedo)
            let len = brushStack.count
            if self.brushType == .line && len > 0 {
                print("B11  ", brushStack.count)
                let top = brushStack[len - 1]
                let dist = distance(a: top.beginPoint!, b: top.currentPoint!)

                let angleR = atan2((top.currentPoint!.y - top.beginPoint!.y),(top.currentPoint!.x - top.beginPoint!.x))

//                var angleD = CGFloat((angleR * 180.0) / .pi)
//                print("Angle First   ", angleR, "   ", angleD)
//                if top.beginPoint!.x > top.currentPoint!.x {
//                    angleD += CGFloat(180.0)
//                }
//                angleD = CGFloat(angleD * .pi / 180.0)

//                let lineView = UIView(frame: CGRect(x: top.beginPoint!.x, y: top.beginPoint!.y, width: dist  + CGFloat(10.0), height: top.lineWidth  + CGFloat(10.0)))
//                lineView.backgroundColor = UIColor.black
                let frame = CGRect(x: top.beginPoint!.x, y: top.beginPoint!.y, width: dist  + CGFloat(10.0), height: top.lineWidth  + CGFloat(40.0))
                brushStack.popLast()
                self.delegate?.addLine(frame: frame, angle: angleR)
//                setAnchorPoint(point: CGPoint(x: 0, y: 0.5), lineView: lineView)
//                lineView.transform = CGAffineTransform(rotationAngle: angleR)
            }else{
                print(".....................")
                
            }
            touchesMoved(touches, with: event)
            finishDrawing()
        }
    }
    func distance( a: CGPoint, b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesCancelled")
        touchesEnded(touches, with: event)
    }
    
    @objc fileprivate func popBrushStack() {
        print("popBrushStack")
        drawUndoManager.registerUndo(withTarget: self, selector: #selector(pushBrushStack(_:)), object: brushStack.popLast())
        redrawInContext()
    }
    
    @objc fileprivate func pushBrushStack(_ brush: BaseBrush) {
        print("pushBrushStack")
        drawUndoManager.registerUndo(withTarget: self, selector: #selector(popBrushStack), object: nil)
        brushStack.append(brush)
        redrawWithBrush(brush)
    }
}

extension TouchDrawView {
    
    // MARK: - Draw
    fileprivate func finishDrawing() {
        print("finishDrawing()")
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        prevImage?.draw(in: self.bounds)
        brush?.drawInContext()
        prevImage = UIGraphicsGetImageFromCurrentImageContext()
        drawImageView.image = prevImage
        UIGraphicsEndImageContext()
        brush = nil
        drawImageView.brush = nil
    }
    
    
    /// Begins the image context
    fileprivate func beginImageContext() {
        print("beginImageContext() ")
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
    }
    
    /// Ends image context and sets UIImage to what was on the context
    fileprivate func endImageContext() {
        print("endImageContext()")
        drawImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

    // Redraw image for undo action
    func redrawInContext() {
        print("redrawInContext()")
        beginImageContext()
        for brush in brushStack {
            brush.drawInContext()
        }
        endImageContext()
        drawImageView.setNeedsDisplay()
        prevImage = drawImageView.image
    }
    
    // Redraw last line for redo action
    fileprivate func redrawWithBrush(_ brush: BaseBrush) {
        print("redrawWithBrush")
        beginImageContext()
        drawImageView.image?.draw(in: bounds)
        brush.drawInContext()
        endImageContext()
        drawImageView.setNeedsDisplay()
        prevImage = drawImageView.image
    }
    
    fileprivate func clearDraw() {
        print("clearDraw()")
        brushStack.removeAll()
        beginImageContext()
        endImageContext()
        prevImage = nil
        drawImageView.setNeedsDisplay()
        drawUndoManager.removeAllActions()
        delegate?.undoEnable(false)
        delegate?.redoEnable(false)
    }
    
    //MARK: Set Anchor Point
    public func setAnchorPoint( point: CGPoint, lineView: UIView) {
        var newPoint = CGPoint(x: lineView.bounds.size.width * point.x, y: lineView.bounds.size.height * point.y)
        var oldPoint = CGPoint(x: lineView.bounds.size.width * lineView.layer.anchorPoint.x, y: lineView.bounds.size.height * lineView.layer.anchorPoint.y);

             newPoint = newPoint.applying(transform)
             oldPoint = oldPoint.applying(transform)

             var position = lineView.layer.position

             position.x -= oldPoint.x
             position.x += newPoint.x

             position.y -= oldPoint.y
             position.y += newPoint.y

             lineView.layer.position = position
             lineView.layer.anchorPoint = point
         }
}

class DrawImageView: UIView {
    
    var image: UIImage?
    var brush: BaseBrush?
    var type: BrushType!
    
    override func draw(_ rect: CGRect) {
        print("draw(_ rect: CGRect) DrawImageView")
        if self.type == .line{
            //image?.draw(in: bounds) // export drawing
            brush?.drawInContext() // preview drawing
        }else{
            image?.draw(in: bounds) // export drawing
            brush?.drawInContext() // preview drawing
        }
    }
}


//@inline(__always) func CGRectGetCenter(_ rect:CGRect) -> CGPoint {
//    return CGPoint(x: rect.midX, y: rect.midY)
//}
//
//@inline(__always) func CGRectScale(_ rect:CGRect, wScale:CGFloat, hScale:CGFloat) -> CGRect {
//    return CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width * wScale, height: rect.size.height * hScale)
//}
//
//@inline(__always) func CGAffineTransformGetAngle(_ t:CGAffineTransform) -> CGFloat {
//    return atan2(t.b, t.a)
//}
//
//@inline(__always) func CGPointGetDistance(point1:CGPoint, point2:CGPoint) -> CGFloat {
//    let fx = point2.x - point1.x
//    let fy = point2.y - point1.y
//    return sqrt(fx * fx + fy * fy)
//}
