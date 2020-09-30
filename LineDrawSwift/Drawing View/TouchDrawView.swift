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
    
    var lineWidth: CGFloat = 10
    var lineColor = UIColor.red
    var lineAlpha: CGFloat = 1  
    var brushType: BrushType = .none
    var deltaAngle: CGFloat!
    var isHaveOverlay: Bool = false
    
    fileprivate var brush: BaseBrush?
    fileprivate var brushStack = [BaseBrush]()
    fileprivate var drawUndoManager = UndoManager()
    fileprivate var drawingView = DrawingView()
    
    fileprivate var prevImage: UIImage?
    fileprivate var image: UIImage?
    
    private lazy var scaleGesture = {
        return UIPanGestureRecognizer(target: self, action: #selector(handleScaleGesture(_:)))
    }()
    private lazy var tapGesture = { () -> UITapGestureRecognizer in
        print("Tapped On Overlay")
        return UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
    }()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSubview(drawingView)
        drawingView.backgroundColor = UIColor.clear
        self.addGestureRecognizer(tapGesture)
        self.addGestureRecognizer(scaleGesture)
    }
    
    // Sets the frames of the subviews
    override open func draw(_ rect: CGRect) {
        print("TouchDrawView Draw Override")
        image?.draw(in: bounds)
        drawingView.frame = self.bounds
    }
    
    // MARK: - Public
    open func setBrushType(_ type: BrushType) {
        print("setBrushType(_ type: BrushType)    ", type)
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
        print("setImage(_ image: UIImage")
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
        print("TouchView Clear draw")
        clearDraw()
    }
    
    // Export drawn image
    open func exportImage() -> UIImage? {
        print("exportImage()")
        beginImageContext()
        self.image?.draw(in: self.bounds)
        drawingView.image?.draw(in: self.bounds)
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

extension TouchDrawView{
    
//    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        print("Hit Test")
//        if self.point(inside: point, with: event) {
//            return super.hitTest(point, with: event)
//        }
//        guard isUserInteractionEnabled, !isHidden, alpha > 0 else {
//            return nil
//        }
//        
//        for subview in subviews.reversed() {
//            let convertedPoint = subview.convert(point, from: self)
//            if let hitView = subview.hitTest(convertedPoint, with: event) {
//                return hitView
//            }
//        }
//        return nil
//    }
    
    @objc fileprivate func popBrushStack() {
        print("popBrushStack")
        if brushStack.count > 0 {
            drawUndoManager.registerUndo(withTarget: self, selector: #selector(pushBrushStack(_:)), object: brushStack.popLast())
            redrawInContext()
        }
    }
    
    @objc fileprivate func pushBrushStack(_ brush: BaseBrush) {
        print("pushBrushStack")
        drawUndoManager.registerUndo(withTarget: self, selector: #selector(popBrushStack), object: nil)
        brushStack.append(brush)
        redrawWithBrush(brush)
    }
    
    func distance( a: CGPoint, b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
}

extension TouchDrawView {
    
    // MARK: - Draw
    fileprivate func finishDrawing() {
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        prevImage?.draw(in: self.bounds)
        brush?.drawInContext()
        prevImage = UIGraphicsGetImageFromCurrentImageContext()
        drawingView.image = prevImage
        UIGraphicsEndImageContext()
        brush = nil
        drawingView.brush = nil
    }
    
    /// Begins the image context
    fileprivate func beginImageContext() {
        print("beginImageContext() ")
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
    }
    
    /// Ends image context and sets UIImage to what was on the context
    fileprivate func endImageContext() {
        print("endImageContext()")
        drawingView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    // Redraw image for undo action
    func redrawInContext() {
        print("RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRedrawInContext()", brushStack.count)
        beginImageContext()
        for brush in brushStack {
            brush.drawInContext()
        }
        endImageContext()
        drawingView.setNeedsDisplay()
        prevImage = drawingView.image
    }
    
    // Redraw last line for redo action
    fileprivate func redrawWithBrush(_ brush: BaseBrush) {
        print("RTTTTTTTTTTTTTTTRedrawWithBrush")
        beginImageContext()
        drawingView.image?.draw(in: bounds)
        if brush != nil {
            brush.drawInContext()
        }
        endImageContext()
        drawingView.setNeedsDisplay()
        prevImage = drawingView.image
    }
    
    fileprivate func clearDraw() {
        print("clearDraw()")
        brushStack.removeAll()
        beginImageContext()
        endImageContext()
        prevImage = nil
        drawingView.setNeedsDisplay()
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

//MARK: Drawing View
class DrawingView: UIView {
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


extension TouchDrawView{
    
    @objc func handleScaleGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
    
        let center = self.center
        
        switch recognizer.state {
        case .began:
            print("Begin      ", brush)
//            guard let allTouches = event?.allTouches else { return }
//            if allTouches.count > 1 { return }
            brush = initBrushType()
            drawingView.brush = brush
            drawingView.type = brush!.type//self.brushType
            
            brush?.beginPoint = touchLocation//touches.first?.location(in: self)
            brush?.currentPoint = touchLocation//touches.first?.location(in: self)
            brush?.previousPoint1 =  touchLocation//touches.first?.previousLocation(in: self)
            brush?.lineColor = lineColor
            brush?.lineAlpha = lineAlpha
            brush?.lineWidth = lineWidth
            brush?.points.append(touchLocation)
            if brush!.type == .line {
               // self.drawingView.isUserInteractionEnabled = false
            }
        case .changed:
            
              print("Move    ", brushType)
//            guard let allTouches = event?.allTouches else { return }
//            if allTouches.count > 1 { return }
            
            if let brush = self.brush {
                brush.previousPoint2 = brush.previousPoint1
                brush.previousPoint1 = brush.currentPoint
                brush.currentPoint = touchLocation
                brush.points.append(touchLocation)
                
                if let penBrush = brush as? PenBrush {
                    var drawBox = penBrush.addPathInBound()
                    drawBox.origin.x -= lineWidth * 2
                    drawBox.origin.y -= lineWidth * 2
                    drawBox.size.width += lineWidth * 4
                    drawBox.size.height += lineWidth * 4
                    self.drawingView.setNeedsDisplay(drawBox)
                    self.drawingView.setNeedsDisplay()
                    print("HAHAHAHAHAH")
                } else {
                    print("HIHIHIHIHIHIHI")
                    self.drawingView.setNeedsDisplay()
                }
            }
        case .ended:
            print("End")
            print("Touch End")
            if let brush = self.brush, brush.points.count >= 2 {
                brushStack.append(brush)
//                drawUndoManager.registerUndo(withTarget: self, selector: #selector(popBrushStack), object: nil)
//                delegate?.undoEnable(drawUndoManager.canUndo)
//                delegate?.redoEnable(drawUndoManager.canRedo)
                let len = brushStack.count
                if  len > 0 &&  (brushStack[len - 1].type == .line){
                    print("B11  ", brushStack.count)
                    let top = brushStack[len - 1]
                  //  brushStack.remove(at: len - 1)
                    let dist = distance(a: top.beginPoint!, b: top.currentPoint!)
                    
                    let angleR = atan2((top.currentPoint!.y - top.beginPoint!.y),(top.currentPoint!.x - top.beginPoint!.x))
                    
                    //var angleD = CGFloat((angleR * 180.0) / .pi)
                    //print("Angle First   ", angleR, "   ", angleD)
                    //if top.beginPoint!.x > top.currentPoint!.x {
                    //angleD += CGFloat(180.0)
                    //}
                    //angleD = CGFloat(angleD * .pi / 180.0)
                    
                    //let lineView = UIView(frame: CGRect(x: top.beginPoint!.x, y: top.beginPoint!.y, width: dist  + CGFloat(10.0), height: top.lineWidth  + CGFloat(10.0)))
                    //lineView.backgroundColor = UIColor.black
                    let frame = CGRect(x: top.beginPoint!.x, y: top.beginPoint!.y, width: dist  + CGFloat(10.0), height: top.lineWidth  + CGFloat(40.0))
                    if dist > 20{
                        //MARK: add Line OverView
        
                       // self.delegate?.addLine(frame: frame, angle: angleR)
                    }
                    //setAnchorPoint(point: CGPoint(x: 0, y: 0.5), lineView: lineView)
                    //lineView.transform = CGAffineTransform(rotationAngle: angleR)
                }
                //touchesMoved(touches, with: event)
                print("...........")
                finishDrawing()
            }
        default:
            break
        }
    }
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        print("Tapped Found on TouchDrawView")
    }
    
}
