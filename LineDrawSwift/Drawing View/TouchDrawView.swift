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

open class TouchDrawView: UIView {
    
    open weak var delegate: TouchDrawViewDelegate?
    var lineWidth: CGFloat = 10
    var lineColor = UIColor.red
    var lineAlpha: CGFloat = 1  
    var brushType: BrushType = .none
    var deltaAngle: CGFloat!
    var isHaveOverlay: Bool = false
    
    fileprivate var brush: BaseBrush?
    var undoBrushStack = [BaseBrush]()
    var redoBrushStack = [BaseBrush]()
    fileprivate var stackIndex = 0
    fileprivate var drawingView = DrawingView()
    fileprivate var prevImage: UIImage?
    fileprivate var image: UIImage?
    fileprivate var newOverlayView: OverlayLineView!
    fileprivate var allOverlayViews = [OverlayLineView]()
    
    var activeOverlayView: OverlayLineView!
    
    private lazy var scaleGesture = {
        return UIPanGestureRecognizer(target: self, action: #selector(handleScaleGesture(_:)))
    }()
    
    private lazy var tapGesture = { () -> UITapGestureRecognizer in
        ///   print("Tapped On Overlay")
        return UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
    }()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSubview(drawingView)
        drawingView.backgroundColor = UIColor.clear
        self.addGestureRecognizer(tapGesture)
        self.addGestureRecognizer(scaleGesture)
    }
    
    /// Sets the frames of the subviews
    override open func draw(_ rect: CGRect) {
        ///   print("TouchDrawView Draw Override")
        image?.draw(in: bounds)
        drawingView.frame = self.bounds
    }
    
    /// MARK: - Public
    
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
    
    open func clear() {
        print("TouchView Clear draw")
        clearDraw()
    }
    
    /// Export drawn image
    open func exportImage() -> UIImage? {
        print("exportImage()")
        beginImageContext()
        self.image?.draw(in: self.bounds)
        drawingView.image?.draw(in: self.bounds)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// MARK: - Private
    
    fileprivate func initBrushType() -> BaseBrush? {
        //  print("initBrush()")
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
    
    @objc func handleScaleGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        
        switch recognizer.state {
        case .began:
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
            //MARK: Select Brush for Draw On Overlay
            if let brush = self.brush, brush.points.count >= 2 {
                switch brush.type {
                case .line:
                    print("Line Draw End")
                    self.lineDrawOnOverlay()
                case .ellipse:
                    print("Line Draw Ellips")
                    self.ellipsDrawOnOverlay()
                case .rect:
                    print("Line Draw Rect")
                    self.rectDrawOnOverlay()
                case .pen:
                    print("Line Draw Pen")
                    self.finishDrawing()
                case .eraser:
                    self.finishDrawing()
                default:
                    print("Does not match any type")
                }
            }
        default:
            break
        }
    }
    
    //MARK: Line draw From Overlay
    
    func lineDrawOnOverlay(){
        guard brush != nil else{
            return
        }
        let top = brush
        let dist = distance(a: top!.beginPoint!, b: top!.currentPoint!)
        let angleR = atan2(((top?.currentPoint!.y)! - top!.beginPoint!.y),(top!.currentPoint!.x - top!.beginPoint!.x))
        let frame = CGRect(x: top!.beginPoint!.x, y: top!.beginPoint!.y, width: dist  + CGFloat(88.0), height: top!.lineWidth  + CGFloat(40.0))
        if dist > 20{
            //MARK: add Line OverView
            self.addOverLayLineView(frame: frame, angle: angleR)
            stackIndex += 1
        }
        ///Hide line from backgound of overlay
        drawingView.brush = nil
        self.drawingView.setNeedsDisplay()
    }
    
    //MARK: Add OverLay Line View
    
    func addOverLayLineView(frame: CGRect, angle: CGFloat) {
        let lineView = UIView(frame: frame)
        lineView.center.y = brush!.beginPoint!.y
        let newPoint = self.newEndPoint(to: self.brush!.currentPoint!, from: lineView.frame.origin, d: -44) // 44 is the button size
        lineView.frame.origin = newPoint
        lineView.backgroundColor = UIColor.clear
        
        newOverlayView = OverlayLineView.init(contentView: lineView, origin: frame.origin)
        newOverlayView.showEditingHandlers = true
        newOverlayView.delegate = self
        newOverlayView.setImage(UIImage.init(named: "Close")!, forHandler: StickerViewHandler.close)
        newOverlayView.setImage(UIImage.init(named: "Rotate")!, forHandler: StickerViewHandler.rotate)
        newOverlayView.type = .line
        newOverlayView.showEditingHandlers = true
        newOverlayView.tag = stackIndex
        newOverlayView.setAnchorPoint(point: CGPoint(x: 0, y: 0.5))
        newOverlayView.transform = CGAffineTransform(rotationAngle: angle)
        newOverlayView.brush = self.brush
        newOverlayView.brush!.beginPoint = CGPoint(x: 0, y: newOverlayView.bounds.size.height * 0.5)
        newOverlayView.brush!.currentPoint = CGPoint(x: newOverlayView.bounds.size.width, y: newOverlayView.bounds.size.height * 0.5)
        newOverlayView.brush?.drawInContext()
        self.addSubview(newOverlayView)
        ///Assaign activerOverlay
        self.activeOverlayView = newOverlayView
    }
    
    func distance( a: CGPoint, b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
    
    //MARK: Ellips draw on Overlay
    
    func ellipsDrawOnOverlay(){
        guard self.brush != nil else{
             return
         }
         let tView = UIView()
         tView.frame = CGRect(origin: CGPoint(x: min(self.brush!.beginPoint!.x, self.brush!.currentPoint!.x) - 44, y: min(self.brush!.beginPoint!.y, self.brush!.currentPoint!.y) - 44),
         size: CGSize(width: abs(self.brush!.currentPoint!.x - self.brush!.beginPoint!.x) + 88, height: abs(self.brush!.currentPoint!.y - self.brush!.beginPoint!.y) + 88))
         
         newOverlayView = OverlayLineView.init(contentView: tView, origin: tView.frame.origin)
         
         newOverlayView.showEditingHandlers = true
         newOverlayView.delegate = self
         newOverlayView.setImage(UIImage.init(named: "Close")!, forHandler: StickerViewHandler.close)
         newOverlayView.setImage(UIImage.init(named: "Rotate")!, forHandler: StickerViewHandler.rotate)
         newOverlayView.type = .ellipse
         newOverlayView.showEditingHandlers = true
         newOverlayView.tag = stackIndex
         ///newOverlayView.setAnchorPoint(point: CGPoint(x: 0, y: 1))
         newOverlayView.brush = self.brush
        // print("R Brush type   ", self.brush!.type)
         newOverlayView.brush!.beginPoint = CGPoint(x: 44, y: 44)
         newOverlayView.brush!.currentPoint = CGPoint(x: newOverlayView.bounds.size.width - 44, y: newOverlayView.bounds.size.height - 44)
         newOverlayView.brush?.drawInContext()
         self.addSubview(newOverlayView)
         ///Assaign activerOverlay
         self.activeOverlayView = newOverlayView
         
         ///Hide line from backgound of overlay
         drawingView.brush = nil
         self.drawingView.setNeedsDisplay()
    }
    
    //MARK: Rect draw ON Overlay
    
    func rectDrawOnOverlay(){
        guard self.brush != nil else{
            return
        }
        let tView = UIView()
        tView.frame = CGRect(origin: CGPoint(x: min(self.brush!.beginPoint!.x, self.brush!.currentPoint!.x) - 44, y: min(self.brush!.beginPoint!.y, self.brush!.currentPoint!.y) - 44),
        size: CGSize(width: abs(self.brush!.currentPoint!.x - self.brush!.beginPoint!.x) + 88, height: abs(self.brush!.currentPoint!.y - self.brush!.beginPoint!.y) + 88))
        
        newOverlayView = OverlayLineView.init(contentView: tView, origin: tView.frame.origin)
        
        newOverlayView.showEditingHandlers = true
        newOverlayView.delegate = self
        newOverlayView.setImage(UIImage.init(named: "Close")!, forHandler: StickerViewHandler.close)
        newOverlayView.setImage(UIImage.init(named: "Rotate")!, forHandler: StickerViewHandler.rotate)
        newOverlayView.type = .rect
        newOverlayView.showEditingHandlers = true
        newOverlayView.tag = stackIndex
        ///newOverlayView.setAnchorPoint(point: CGPoint(x: 0, y: 1))
        newOverlayView.brush = self.brush
        ///print("R Brush type   ", self.brush!.type)
        newOverlayView.brush!.beginPoint = CGPoint(x: 44, y: 44)
        newOverlayView.brush!.currentPoint = CGPoint(x: newOverlayView.bounds.size.width - 44, y: newOverlayView.bounds.size.height - 44)
        newOverlayView.brush?.drawInContext()
        self.addSubview(newOverlayView)
        ///Assaign activerOverlay
        self.activeOverlayView = newOverlayView
        
        ///Hide line from backgound of overlay
        drawingView.brush = nil
        self.drawingView.setNeedsDisplay()
    }
    
    //MARK: Handle Single Tap Handler On Drawing View Or Draw From Overlay View
    
    ///Next task Start from Here
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        ///self.activeOverlayView.isHidden = true
        let touchPoint = recognizer.location(in: self.superview)
        print("Active   ", self.activeOverlayView)
        guard  (self.activeOverlayView != nil) else {
            for overlay in self.allOverlayViews{
                if overlay.type != .line {
                    let fromX = overlay.frame.origin.x + 44
                    let fromY = overlay.frame.origin.y + 44
                    let toX = fromX + overlay.frame.size.width - 44
                    let toY = fromY + overlay.frame.size.height - 44
                    
                    if touchPoint.x >= fromX && touchPoint.x <= toX && touchPoint.y >= fromY && touchPoint.y <= toY {
                        overlay.isHidden = false
                        self.activeOverlayView = overlay
                    }
                }
                print("Overlay Type  :  ", overlay.type,"    ", overlay.frame)
            }
            return
        }
        self.drawfromOverlayView(type: self.activeOverlayView.brush!.type)
        ///Store All Overlay View
        self.allOverlayViews.append(activeOverlayView)
        self.activeOverlayView = nil
    }
    
    func drawfromOverlayView(type: BrushType){
        switch type {
        case .line:
            drawLineFromOverlay()
        case .ellipse:
            self.drawEllipsFromOverlay()
        case .rect:
            self.drawRectFromOverlay()
        default:
            print("Does not found any Brush type")
        }
    }
    
    func drawLineFromOverlay(){
        let temporaryBrush = LineBrush()
        temporaryBrush.type = .line
        /// 4 cordinate of activeOverlayView
        var (topLeft, topRight, bottomLeft, bottomRight)  = self.findCordinateOfView(theView: self.activeOverlayView)
        var from = CGPoint(x: (topLeft.x + bottomLeft.x) * 0.5, y: (topLeft.y + bottomLeft.y) * 0.5)
        var to = CGPoint(x: (bottomRight.x + topRight.x) * 0.5, y: (topRight.y + bottomRight.y) * 0.5)
        
        from = self.newEndPoint(to: to, from: from, d: (self.activeOverlayView.bounds.width * 0.5) + 44) // 44 Button size
        to = self.newEndPoint(to: to, from: from, d: self.activeOverlayView.bounds.width - 88)
        temporaryBrush.beginPoint = from
        temporaryBrush.currentPoint = to
        temporaryBrush.lineColor = UIColor.red
        temporaryBrush.lineAlpha = 1
        temporaryBrush.lineWidth = 10
        self.activeOverlayView.brush = temporaryBrush
        self.drawingView.brush = temporaryBrush
        self.drawingView.brush?.drawInContext()
        self.brush = self.drawingView.brush
        self.drawingView.setNeedsDisplay()
        finishDrawing()
        self.activeOverlayView.isHidden = true
    }
    
    func drawEllipsFromOverlay(){
        print("Hii")
        guard self.activeOverlayView != nil else{
            return
        }
        print("Hi ")
        self.drawingView.brush = self.activeOverlayView.brush
        let (topLeft, _, bottomLeft, bottomRight) = self.findCordinateOfView(theView: self.activeOverlayView)
        self.drawingView.brush!.beginPoint = CGPoint(x: topLeft.x + 44, y: topLeft.y + 44)
        self.drawingView.brush!.currentPoint = CGPoint(x: bottomRight.x - 44, y: bottomLeft.y - 44)
        self.drawingView.brush!.drawInContext()
        self.brush = self.drawingView.brush!
        self.drawingView.setNeedsDisplay()
        self.finishDrawing()
        self.activeOverlayView.isHidden = true
    }
    
    func drawRectFromOverlay(){
        print("Hii")
        guard self.activeOverlayView != nil else{
            return
        }
        print("Hi ")
        self.drawingView.brush = self.activeOverlayView.brush
        let (topLeft, _, bottomLeft, bottomRight) = self.findCordinateOfView(theView: self.activeOverlayView)
        self.drawingView.brush!.beginPoint = CGPoint(x: topLeft.x + 44, y: topLeft.y + 44)
        self.drawingView.brush!.currentPoint = CGPoint(x: bottomRight.x - 44, y: bottomLeft.y - 44)
        self.drawingView.brush!.drawInContext()
        self.brush = self.drawingView.brush!
        self.drawingView.setNeedsDisplay()
        self.finishDrawing()
        self.activeOverlayView.isHidden = true
        
    }
    
    //MARK: Find Four Cordinate of A View
    
    func findCordinateOfView(theView: UIView) -> (CGPoint, CGPoint, CGPoint, CGPoint){
        let originalCenter: CGPoint = theView.center.applying(theView.transform.inverted())
        
        var topLeft: CGPoint = originalCenter
        topLeft.x -= theView.bounds.size.width / 2;
        topLeft.y -= theView.bounds.size.height / 2;
        topLeft = topLeft.applying(theView.transform);
        
        var topRight: CGPoint = originalCenter;
        topRight.x += theView.bounds.size.width / 2;
        topRight.y -= theView.bounds.size.height / 2;
        topRight = topRight.applying(theView.transform)
        
        var bottomLeft: CGPoint = originalCenter;
        bottomLeft.x -= theView.bounds.size.width / 2;
        bottomLeft.y += theView.bounds.size.height / 2;
        bottomLeft = bottomLeft.applying(theView.transform)
        
        var bottomRight: CGPoint = originalCenter;
        bottomRight.x += theView.bounds.size.width / 2;
        bottomRight.y += theView.bounds.size.height / 2;
        bottomRight = bottomRight.applying(theView.transform)
        
        return (topLeft, topRight, bottomLeft, bottomRight)
    }
    
}

extension TouchDrawView {
    
    // MARK: - Draw
    
    fileprivate func finishDrawing() {
        /// Store All Brushes
        print("Finish")
        self.undoBrushStack.append(self.brush!)
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
        //   print("beginImageContext() ")
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
    }
    
    /// Ends image context and sets UIImage to what was on the context
    fileprivate func endImageContext() {
        //  print("endImageContext()")
        drawingView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    /// Redraw image for undo action
    func redrawInContext() {
        //    print("redrawInContext() ", brushStack.count)
        beginImageContext()
        for brush in undoBrushStack {
            brush.drawInContext()
        }
        endImageContext()
        drawingView.setNeedsDisplay()
        prevImage = drawingView.image
    }
    
    /// Redraw last line for redo action
    fileprivate func redrawWithBrush(_ brush: BaseBrush) {
        //  print("redrawWithBrush(_ brush: BaseBrush)")
        beginImageContext()
        drawingView.image?.draw(in: bounds)
        brush.drawInContext()
        endImageContext()
        drawingView.setNeedsDisplay()
        prevImage = drawingView.image
    }
    
    fileprivate func clearDraw() {
        ///  print("clearDraw()")
        undoBrushStack.removeAll()
        beginImageContext()
        endImageContext()
        prevImage = nil
        drawingView.setNeedsDisplay()
        self.undoBrushStack.removeAll()
        self.redoBrushStack.removeAll()
        self.redrawInContext()
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

extension TouchDrawView {
    
    func newEndPoint(to: CGPoint, from: CGPoint, d: CGFloat) -> CGPoint {
        let dist = self.distance(point1: to, curr: from)
        let m = dist - d
        let n = d
        let x = (n * to.x + m * from.x) / dist
        let y = (n * to.y + m * from.y) / dist
        return CGPoint(x: x, y: y)
    }
    
    func distance(point1: CGPoint, curr: CGPoint) -> CGFloat {
        return sqrt((point1.x - curr.x) * (point1.x - curr.x) + (point1.y - curr.y) * (point1.y-curr.y))
    }
    
}

extension TouchDrawView: OverlayViewViewDelegate {
    
    public func overlayViewDidBeginMoving(_ stickerView: OverlayLineView) {
        print("verlayViewDidBeginMoving ")
        self.activeOverlayView = stickerView
    }
    
    public func overlayViewDidChangeMoving(_ stickerView: OverlayLineView) {
        print("overlayViewDidChangeMoving  ", stickerView.frame.origin)
        self.activeOverlayView = stickerView
    }
    
    public func overlayViewDidEndMoving(_ stickerView: OverlayLineView) {
        print("overlayViewDidEndMoving  ")
        self.activeOverlayView = stickerView
    }
    
    public func overlayViewDidBeginRotating(_ stickerView: OverlayLineView) {
        print("overlayViewDidBeginRotating ")
        self.activeOverlayView = stickerView
    }
    
    //MARK: Redraw during scaling or rotating Drawing View
    public func overlayViewDidChangeRotating(_ stickerView: OverlayLineView) {
        guard stickerView.brush != nil else{
            return
        }
        ///Update draw in overlay view
        switch stickerView.brush!.type {
        case .line:
            self.activeOverlayView.brush?.lineColor = UIColor.green
            self.activeOverlayView.brush!.beginPoint = CGPoint(x: 0, y: self.newOverlayView.bounds.size.height * 0.5)
            self.activeOverlayView.brush!.currentPoint = CGPoint(x: self.activeOverlayView.bounds.size.width, y: self.activeOverlayView.bounds.size.height * 0.5)
        case .rect:
            self.activeOverlayView.brush?.lineColor = UIColor.orange
            self.activeOverlayView.brush!.beginPoint = CGPoint(x: 44, y: 44)
            self.activeOverlayView.brush!.currentPoint = CGPoint(x: self.activeOverlayView.bounds.size.width - 44, y: self.activeOverlayView.bounds.size.height - 44)
        case .ellipse:
            print("Ellips")
            self.activeOverlayView.brush?.lineColor = UIColor.orange
            self.activeOverlayView.brush!.beginPoint = CGPoint(x: 44, y: 44)
            self.activeOverlayView.brush!.currentPoint = CGPoint(x: self.activeOverlayView.bounds.size.width - 44, y: self.activeOverlayView.bounds.size.height - 44)
        case .pen:
            print("Pen")
        default:
            print("Nothing")
        }
        ///print("overlayViewDidChangeRotating  ", stickerView.frame.origin,"  ", self.activeOverlayView.frame.origin)
        self.activeOverlayView = stickerView
        self.activeOverlayView.brush?.drawInContext()
    }
    
    public func overlayViewDidEndRotating(_ stickerView: OverlayLineView) {
        print("overlayViewDidEndRotating  ")
        self.activeOverlayView = stickerView
    }
    
    public func overlayViewDidClose(_ stickerView: OverlayLineView) {
        print("overlayViewDidClose   ")
        self.activeOverlayView = nil
    }
    
    public func overlayViewDidTap(_ stickerView: OverlayLineView) {
        print("overlayViewDidTap  " )
        self.activeOverlayView = stickerView
    }
    
    public func overlayViewDidUpdatedInfo(frame: CGRect, angle: CGFloat) {
        print("overlayViewDidUpdatedInfo   ")
    }
    
}

//MARK: Drawing View

class DrawingView: UIView {
    
    var image: UIImage?
    var brush: BaseBrush?
    var type: BrushType!
    
    override func draw(_ rect: CGRect) {
        ///print("draw(_ rect: CGRect) DrawImageView")
        if self.type == .line{
            image?.draw(in: bounds)
            brush?.drawInContext()
        }else{
            image?.draw(in: bounds)
            brush?.drawInContext()
        }
    }
    
}
