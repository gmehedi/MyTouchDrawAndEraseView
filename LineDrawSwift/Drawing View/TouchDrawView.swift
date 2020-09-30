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
    fileprivate var allBrushStack = [BaseBrush]()
    fileprivate var stackIndex = 0
    fileprivate var drawUndoManager = UndoManager()
    fileprivate var drawingView = DrawingView()
    fileprivate var prevImage: UIImage?
    fileprivate var image: UIImage?
    var activeOverlayView: OverlayViewInfo!
    
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
    
    @objc fileprivate func popBrushStack() {
        print("popBrushStack  ", brushStack.count)
        if stackIndex > 0 {
            stackIndex -= 1
        }
        
        if brushStack.count > 0 {
            drawUndoManager.registerUndo(withTarget: self, selector: #selector(pushBrushStack(_:)), object: brushStack.popLast())
            redrawInContext()
        }
    }
    
    @objc fileprivate func pushBrushStack(_ brush: BaseBrush) {
        print("pushBrushStack")
        stackIndex += 1
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

//MARK: Drawing View
class DrawingView: UIView {
    
    var image: UIImage?
    var brush: BaseBrush?
    var type: BrushType!
    
    override func draw(_ rect: CGRect) {
        print("draw(_ rect: CGRect) DrawImageView")
        if self.type == .line{
            image?.draw(in: bounds) // export drawing
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
        
        switch recognizer.state {
        case .began:
            print("Begin      ")
            brush = initBrushType()
            drawingView.brush = brush
            
            brush?.beginPoint = touchLocation//touches.first?.location(in: self)
            brush?.currentPoint = touchLocation//touches.first?.location(in: self)
            brush?.previousPoint1 =  touchLocation//touches.first?.previousLocation(in: self)
            brush?.lineColor = lineColor
            brush?.lineAlpha = lineAlpha
            brush?.lineWidth = lineWidth
            brush?.points.append(touchLocation)
        case .changed:
            // print("Move    ", brushType)
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
                } else {
                    self.drawingView.setNeedsDisplay()
                }
            }
        case .ended:
            print("Touch End")
            if let brush = self.brush, brush.points.count >= 2 {
                if brush.type != .line{
                    brushStack.append(brush)
                }
                allBrushStack.append(brush)
                stackIndex += 1
                drawUndoManager.registerUndo(withTarget: self, selector: #selector(popBrushStack), object: nil)
                delegate?.undoEnable(drawUndoManager.canUndo)
                delegate?.redoEnable(drawUndoManager.canRedo)
                
                if brush.type == .line{
                    print("B11  ", brushStack.count)
                    let top = brush
                    let dist = distance(a: top.beginPoint!, b: top.currentPoint!)
                    
                    let angleR = atan2((top.currentPoint!.y - top.beginPoint!.y),(top.currentPoint!.x - top.beginPoint!.x))
                    
                    var x: CGFloat = 0.0
                    var y: CGFloat = 0.0
                    
                    if  (abs(top.beginPoint!.x - top.currentPoint!.x) > abs(top.beginPoint!.y - top.currentPoint!.y)) {
                        if top.beginPoint!.x < top.currentPoint!.x{
                            x = -44 // 44 is the button width which should be increase
                        }else{
                            x = 44
                        }
                    }else{
                        if top.beginPoint!.y < top.currentPoint!.y{
                            y = -64 
                        }else{
                            y = 20 // height 40 and minus 20 bcos rotating
                        }
                    }
                    
                    let frame = CGRect(x: top.beginPoint!.x + CGFloat(x), y: top.beginPoint!.y + CGFloat(y), width: dist  + CGFloat(88.0), height: top.lineWidth  + CGFloat(40.0))
                    if dist > 20{
                        //MARK: add Line OverView
                        self.addOverLayLineView(frame: frame, angle: angleR)
                    }
                    //Hide line from backgound of overlay
                    drawingView.brush = nil
                    self.drawingView.setNeedsDisplay()
                }else{
                    finishDrawing()
                }
                print("...........")
            }
        default:
            break
        }
    }
    
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        print("Tapped Found on TouchDrawView")
    }
    
    func addOverLayLineView(frame: CGRect, angle: CGFloat){
        let lineView = UIView(frame: frame) //CGRect(x: 0, y: 0, width: 100, height: 60)
        lineView.backgroundColor = UIColor.clear
        let overlayView = OverlayLineView.init(contentView: lineView, origin: frame.origin)
        overlayView.showEditingHandlers = true
        overlayView.delegate = self
        overlayView.setImage(UIImage.init(named: "Close")!, forHandler: StickerViewHandler.close)
        overlayView.setImage(UIImage.init(named: "Rotate")!, forHandler: StickerViewHandler.rotate)
        //  stickerView.setImage(UIImage.init(named: "Flip")!, forHandler: StickerViewHandler.flip)
        overlayView.showEditingHandlers = true
        overlayView.tag = 999
        overlayView.setAnchorPoint(point: CGPoint(x: 0, y: 0.5))
        overlayView.transform = CGAffineTransform(rotationAngle: angle)
        overlayView.brush?.drawInContext()
        self.addSubview(overlayView)
        //Assaign activerOverlay
        let activeOverlay = OverlayViewInfo(view: overlayView, width: overlayView.frame.size.width, height: overlayView.frame.size.height, angle: angle, position: overlayView.frame.origin)
        self.activeOverlayView = activeOverlay
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
        print("redrawInContext() ", brushStack.count)
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
        print("redrawWithBrush(_ brush: BaseBrush)")
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

extension TouchDrawView: OverlayViewViewDelegate {
    
    public func overlayViewDidBeginMoving(_ stickerView: OverlayLineView) {
        print("")
    }
    
    public func overlayViewDidChangeMoving(_ stickerView: OverlayLineView) {
        print("")
    }
    
    public func overlayViewDidEndMoving(_ stickerView: OverlayLineView) {
        print("")
    }
    
    public func overlayViewDidBeginRotating(_ stickerView: OverlayLineView) {
        print("")
    }
    
    public func overlayViewDidChangeRotating(_ stickerView: OverlayLineView) {
        print("")
    }
    
    public func overlayViewDidEndRotating(_ stickerView: OverlayLineView) {
        print("")
    }
    
    public func overlayViewDidClose(_ stickerView: OverlayLineView) {
        print("")
    }
    
    public func overlayViewDidTap(_ stickerView: OverlayLineView) {
        print("")
    }
    
    public func overlayViewDidUpdatedInfo(frame: CGRect, angle: CGFloat) {
        print("")
    }
}
