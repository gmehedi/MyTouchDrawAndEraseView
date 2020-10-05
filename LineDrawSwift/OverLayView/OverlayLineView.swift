//
//  OverlayLineView`.swift
//  GestureWithSingleFinger
//
//  Created by MacBook Pro on 9/27/20.
//  Copyright © 2020 MacBook Pro. All rights reserved.
//

import UIKit

public enum StickerViewHandler:Int {
    case close
    case rotate
    case flip
}

public enum StickerViewPosition:Int {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

@inline(__always) func CGRectGetCenter(_ rect:CGRect) -> CGPoint {
    return CGPoint(x: rect.midX, y: rect.midY)
}

@inline(__always) func CGRectScale(_ rect:CGRect, wScale:CGFloat, hScale:CGFloat) -> CGRect {
    return CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width * wScale, height: rect.size.height * hScale)
}

@inline(__always) func CGAffineTransformGetAngle(_ t:CGAffineTransform) -> CGFloat {
    return atan2(t.b, t.a)
}

@inline(__always) func CGPointGetDistance(point1:CGPoint, point2:CGPoint) -> CGFloat {
    let fx = point2.x - point1.x
    let fy = point2.y - point1.y
    return sqrt(fx * fx + fy * fy)
}

@objc public  protocol OverlayViewViewDelegate {
    @objc func overlayViewDidBeginMoving(_ stickerView: OverlayLineView)
    @objc func overlayViewDidChangeMoving(_ stickerView: OverlayLineView)
    @objc func overlayViewDidEndMoving(_ stickerView: OverlayLineView)
    @objc func overlayViewDidBeginRotating(_ stickerView: OverlayLineView)
    @objc func overlayViewDidChangeRotating(_ stickerView: OverlayLineView)
    @objc func overlayViewDidEndRotating(_ stickerView: OverlayLineView)
    @objc func overlayViewDidClose(_ stickerView: OverlayLineView)
    @objc func overlayViewDidTap(_ stickerView: OverlayLineView)
    @objc func overlayViewDidUpdatedInfo(frame: CGRect, angle: CGFloat)
}

public class OverlayLineView: UIView{
    
    public var delegate: OverlayViewViewDelegate!
    /// The contentView inside the Overlay view.
    public var contentView:UIView!
    public var initialFrame: CGRect!
    ///Draw Line On OverLayView
    var image: UIImage?
    var brush: BaseBrush?
    var type: BrushType!
    
    //MARK: Draw On OverlayView
    
    public override func draw(_ rect: CGRect) {
        if self.type == .line{
            image?.draw(in: bounds) // export drawing
            brush?.drawInContext() // preview drawing
        }else{
            image?.draw(in: bounds) // export drawing
            brush?.drawInContext() // preview drawing
        }
    }
    
    /// Enable the close handler or not. Default value is YES.
    public var enableClose:Bool = true {
        didSet {
            if self.showEditingHandlers {
                self.setEnableClose(self.enableClose)
            }
        }
    }
    
    /// Enable the rotate/resize handler or not. Default value is YES.
    public var enableRotate:Bool = true{
        didSet {
            if self.showEditingHandlers {
                self.setEnableRotate(self.enableRotate)
            }
        }
    }
    
    /// Enable the flip handler or not. Default value is YES.
    public var enableFlip:Bool = true
    
    /// Show close and rotate/resize handlers or not. Default value is YES.
    public var showEditingHandlers:Bool = true {
        didSet {
            if self.showEditingHandlers {
                self.setEnableClose(self.enableClose)
                self.setEnableRotate(self.enableRotate)
                self.setEnableFlip(self.enableFlip)
                self.contentView?.layer.borderWidth = 1
            }
            else {
                self.setEnableClose(false)
                self.setEnableRotate(false)
                self.setEnableFlip(false)
                self.contentView?.layer.borderWidth = 0
            }
        }
    }
    
    /// Minimum value for the shorter side while resizing. Default value will be used if not set.
    private var _minimumSize:NSInteger = 0
    
    public  var minimumSize:NSInteger {
        set {
            _minimumSize = max(newValue, self.defaultMinimumSize)
        }
        get {
            return _minimumSize
        }
    }
    
    /// Color of the outline border. Default: brown color.
    private var _outlineBorderColor:UIColor = .clear
    
    public  var outlineBorderColor:UIColor {
        set {
            _outlineBorderColor = newValue
            self.contentView?.layer.borderColor = _outlineBorderColor.cgColor
        }
        get {
            return _outlineBorderColor
        }
    }
    
    /// A convenient property for you to store extra information.
    public  var userInfo:Any?
    
    //MARK: Overlay View Initialize
    
    public  init(contentView: UIView, origin: CGPoint) {
        self.defaultInset = 11 // button size 
        self.defaultMinimumSize = 10
        let frame = contentView.frame
        super.init(frame: frame)
        self.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        self.addGestureRecognizer(self.moveGesture)
        self.addGestureRecognizer(self.tapGesture)
        
        /// Setup content view
        self.contentView = contentView
        self.contentView.center = CGRectGetCenter(self.bounds)
        self.contentView.isUserInteractionEnabled = false
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.layer.allowsEdgeAntialiasing = true
        self.addSubview(self.contentView)
        
        /// Setup editing handlers
        self.setPosition(.topRight, forHandler: .close)
        self.addSubview(self.closeLineButton)
        self.setPosition(.bottomRight, forHandler: .rotate)
        /// self.addSubview(self.rotateLineButton)
        self.setPosition(.topLeft, forHandler: .flip)
        /// self.addSubview(self.flipLineButton)
        
        self.showEditingHandlers = true
        self.enableClose = true
        self.enableRotate = true
        self.enableFlip = true
        
        self.minimumSize = self.defaultMinimumSize
        self.outlineBorderColor = .brown
        self.rotateLineButton.frame = CGRect(x: Int(self.frame.size.width - CGFloat(self.defaultInset * 4)), y: 0, width: self.defaultInset * 4, height: self.defaultInset * 4)
        self.closeLineButton.frame = CGRect(x: 0, y: Int(self.frame.size.height - CGFloat(self.defaultInset * 4)), width: self.defaultInset * 4, height: self.defaultInset * 4)
    }
    
    public  required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /**
     *  Use image to customize each editing handler.
     *  It is your responsibility to set image for every editing handler.
     *
     *  @param image   The image to be used.
     *  @param handler The editing handler.
     */
    public func setImage(_ image:UIImage, forHandler handler:StickerViewHandler) {
        ///  print("setImage")
        switch handler {
        case .close:
            self.closeLineButton.setImage(UIImage(named: "Close"), for: .normal)
            self.addSubview(closeLineButton)
        case .rotate:
            self.rotateLineButton.setImage(UIImage(named: "Rotate"), for: .normal)
            self.addSubview(rotateLineButton)
        case .flip:
            print("Flip Off")
            /// self.flipImageView.setImage(UIImage(named: "Flip"), for: .normal)
        }
    }
    
    /**
     *  Customize each editing handler's position.
     *  If not set, default position will be used.
     *  @note  It is your responsibility not to set duplicated position.
     *
     *  @param position The position for the handler.
     *  @param handler  The editing handler.
     */
    
    public func setPosition(_ position: StickerViewPosition, forHandler handler: StickerViewHandler) {
        let origin = self.contentView.frame.origin
        let size = self.contentView.frame.size
        
        var handlerView: UIButton?
        ///  print("Set Image Now")
        switch handler {
        case .close:
            handlerView = self.closeLineButton
            print(".close")
        case .rotate:
            print(".rotate")
            handlerView = self.rotateLineButton
        case .flip:
            print("Flip off")
            /// handlerView = self.flipImageView
        }
        
        switch position {
        case .topLeft:
            print(".topLeft")
            handlerView?.center = origin
            handlerView?.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        case .topRight:
            print(".topRight") // cross button
            handlerView?.center = CGPoint(x: origin.x, y: origin.y)
            handlerView?.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        case .bottomLeft:
            print(".bottomLeft")
            handlerView?.center = CGPoint(x: origin.x, y: origin.y + size.height)
            handlerView?.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        case .bottomRight:
            print(".bottomRight") // scale button
            handlerView?.center = CGPoint(x: origin.x + size.width, y: origin.y)
            handlerView?.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        }
        
        handlerView?.tag = position.rawValue
    }
    
    private var defaultInset:NSInteger
    private var defaultMinimumSize:NSInteger
    public var beginningPoint = CGPoint.zero
    public var beginningCenter = CGPoint.zero
    
    /**
     *  Variables for rotating and resizing viewes
     */
    
    private var initialBounds = CGRect.zero
    private var initialDistance:CGFloat = 0
    private var deltaAngle:CGFloat = 0
    private var currentAngle:CGFloat = 0
    
    public lazy var moveGesture = {
        return UIPanGestureRecognizer(target: self, action: #selector(handleMoveGesture(_:)))
    }()
    
    public lazy var rotateLineButton:UIButton = {
        let rotateButton = UIButton() // self.defaultInset == 11
        rotateButton.contentMode = .center
        rotateButton.backgroundColor = UIColor.gray
        rotateButton.isUserInteractionEnabled = true
        rotateButton.addGestureRecognizer(diagonalRotateGesture)
        return rotateButton
    }()
    
    private lazy var diagonalRotateGesture = {
        return UIPanGestureRecognizer(target: self, action: #selector(handleDiagonalPanGesture(_:)))
    }()
    
    private lazy var closeLineButton: UIButton = {
        let closeButton = UIButton()
        closeButton.contentMode = UIView.ContentMode.center
        closeButton.backgroundColor = UIColor.red
        closeButton.isUserInteractionEnabled = true
        closeButton.addGestureRecognizer(self.closeGesture)
        return closeButton
    }()
    
    private lazy var closeGesture = {
        return UITapGestureRecognizer(target: self, action: #selector(handleCloseGesture(_:)))
    }()
    
    private lazy var flipLineButton:UIImageView = {
        let flipButton = UIImageView(frame: CGRect(x: 0, y: 0, width: self.defaultInset * 2, height: self.defaultInset * 2))
        flipButton.contentMode = UIView.ContentMode.scaleAspectFit
        flipButton.backgroundColor = UIColor.clear
        flipButton.isUserInteractionEnabled = true
        flipButton.addGestureRecognizer(self.flipGesture)
        return flipButton
    }()
    
    private lazy var flipGesture = {
        return UITapGestureRecognizer(target: self, action: #selector(handleFlipGesture(_:)))
    }()
    
    private lazy var tapGesture = { () -> UITapGestureRecognizer in
        /// print("Tapped On Overlay")
        return UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
    }()
    
    // MARK: Gesture Handlers
    
    @objc func handleMoveGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        switch recognizer.state {
        case .began:
            self.beginningPoint = touchLocation
            self.beginningCenter = self.center
            if let delegate = self.delegate {
                delegate.overlayViewDidBeginMoving(self)
                delegate.overlayViewDidUpdatedInfo(frame: self.frame, angle: self.currentAngle)
            }
        case .changed:
            self.center = CGPoint(x: self.beginningCenter.x + (touchLocation.x - self.beginningPoint.x), y: self.beginningCenter.y + (touchLocation.y - self.beginningPoint.y))
            if let delegate = self.delegate {
                delegate.overlayViewDidChangeMoving(self)
                delegate.overlayViewDidUpdatedInfo(frame: self.frame, angle: self.currentAngle)
            }
        case .ended:
            self.center = CGPoint(x: self.beginningCenter.x + (touchLocation.x - self.beginningPoint.x), y: self.beginningCenter.y + (touchLocation.y - self.beginningPoint.y))
            if let delegate = self.delegate {
                delegate.overlayViewDidUpdatedInfo(frame: self.frame, angle: self.currentAngle)
                delegate.overlayViewDidEndMoving(self)
            }
        default:
            break
        }
    }
    
    @objc func handleDiagonalPanGesture(_ recognizer: UIPanGestureRecognizer) {
        print("Scale Diagonaly")
        let touchLocation = recognizer.location(in: self.superview)
        let center = self.center
    
        switch recognizer.state {
        case .began:
            self.deltaAngle = CGFloat(atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))) - CGAffineTransformGetAngle(self.transform)
            self.initialBounds = self.bounds
            self.initialFrame = self.frame
            self.initialDistance = CGPointGetDistance(point1: center, point2: touchLocation)
            if self.brush!.type == .line{
                setAnchorPoint(point: CGPoint(x: 0, y: 0.5))
            }
            
            if let delegate = self.delegate {
                delegate.overlayViewDidBeginRotating(self)
            }
        case .changed:
            if self.brush!.type == .line{
                let angle = atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))
                let angleDiff = Float (self.deltaAngle) - angle
                setAnchorPoint(point: CGPoint(x: 0, y: 0.5))
                self.currentAngle = CGFloat(-angleDiff)
                self.transform = CGAffineTransform(rotationAngle: CGFloat(-angleDiff))
            }
            var scale = CGPointGetDistance(point1: center, point2: touchLocation) / self.initialDistance
            let minimumScale = CGFloat(self.minimumSize) / min(self.initialBounds.size.width, self.initialBounds.size.height)
            scale = max(scale, minimumScale)
            
            switch self.brush!.type {
            case .line:
                self.bounds = CGRectScale(self.initialBounds, wScale: scale, hScale: 1)
            default:
                if touchLocation.x - self.initialFrame.origin.x > 44 {
                    self.frame = CGRect(origin: CGPoint(x: self.frame.origin.x, y: touchLocation.y), size: CGSize(width: touchLocation.x - self.initialFrame.origin.x, height: self.initialFrame.size.height + (initialFrame.origin.y - touchLocation.y)))
                }
            }
            
            self.brush?.drawInContext()
            self.setNeedsDisplay()
            
            if let delegate = self.delegate {
                delegate.overlayViewDidChangeRotating(self)
                // delegate.overlayViewDidUpdatedInfo(frame: self.frame, angle: self.currentAngle)
            }
        case .ended:
            self.brush?.drawInContext()
            self.setNeedsDisplay()
            if let delegate = self.delegate {
                delegate.overlayViewDidEndRotating(self)
                // delegate.overlayViewDidUpdatedInfo(frame: self.frame, angle: self.currentAngle)
            }
        default:
            break
        }
        recognizer.setTranslation(.zero, in: self.superview)
    }
    
//    @objc func handleVerticalPanGesture(_ recognizer: UIPanGestureRecognizer) {
//        print("Scale Verticallye")
//        let touchLocation = recognizer.location(in: self.superview)
//        let center = self.center
//
//        switch recognizer.state {
//        case .began:
//            self.deltaAngle = CGFloat(atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))) - CGAffineTransformGetAngle(self.transform)
//            self.initialBounds = self.bounds
//            self.initialDistance = CGPointGetDistance(point1: center, point2: touchLocation)
//            if let delegate = self.delegate {
//                delegate.overlayViewDidBeginRotating(self)
//            }
//        case .changed:
//            if self.brush!.type == .line{
//                let angle = atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))
//                let angleDiff = Float (self.deltaAngle) - angle
//                setAnchorPoint(point: CGPoint(x: 0, y: 0.5))
//                self.currentAngle = CGFloat(-angleDiff)
//                self.transform = CGAffineTransform(rotationAngle: CGFloat(-angleDiff))
//            }
//            setAnchorPoint(point: CGPoint(x: 0, y: 1))
//            var scale = CGPointGetDistance(point1: center, point2: touchLocation) / self.initialDistance
//            let minimumScale = CGFloat(self.minimumSize) /  self.initialBounds.size.height
//            scale = max(scale, minimumScale)
//            print("VSS   ", scale)
//            let scaledBounds = CGRectScale(self.initialBounds, wScale: 1, hScale: scale)
//            self.bounds = scaledBounds
//
//            self.brush?.drawInContext()
//            self.setNeedsDisplay()
//
//            if let delegate = self.delegate {
//                delegate.overlayViewDidChangeRotating(self)
//                // delegate.overlayViewDidUpdatedInfo(frame: self.frame, angle: self.currentAngle)
//            }
//        case .ended:
//            self.brush?.drawInContext()
//            self.setNeedsDisplay()
//            if let delegate = self.delegate {
//                delegate.overlayViewDidEndRotating(self)
//                // delegate.overlayViewDidUpdatedInfo(frame: self.frame, angle: self.currentAngle)
//            }
//        default:
//            break
//        }
//    }
//
//    @objc func handleHorizontalPanGesture(_ recognizer: UIPanGestureRecognizer) {
//        print("Scale Horizontaly")
//        let touchLocation = recognizer.location(in: self.superview)
//        let center = self.center
//
//        switch recognizer.state {
//        case .began:
//            self.deltaAngle = CGFloat(atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))) - CGAffineTransformGetAngle(self.transform)
//            self.initialBounds = self.bounds
//            self.initialDistance = CGPointGetDistance(point1: center, point2: touchLocation)
//            if let delegate = self.delegate {
//                delegate.overlayViewDidBeginRotating(self)
//            }
//        case .changed:
//            if self.brush!.type == .line{
//                let angle = atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))
//                let angleDiff = Float (self.deltaAngle) - angle
//                setAnchorPoint(point: CGPoint(x: 0, y: 0.5))
//                self.currentAngle = CGFloat(-angleDiff)
//                self.transform = CGAffineTransform(rotationAngle: CGFloat(-angleDiff))
//            }
//            var scale = CGPointGetDistance(point1: center, point2: touchLocation) / self.initialDistance
//            print("SHHH   ", scale)
//            let minimumScale = CGFloat(self.minimumSize) / min(self.initialBounds.size.width, self.initialBounds.size.height)
//            scale = max(scale, minimumScale)
//
//            var scaledBounds: CGRect!
//            scaledBounds = CGRectScale(self.initialBounds, wScale: scale, hScale: 1)
//
//            self.bounds = scaledBounds
//
//            self.brush?.drawInContext()
//            self.setNeedsDisplay()
//
//            if let delegate = self.delegate {
//                delegate.overlayViewDidChangeRotating(self)
//                // delegate.overlayViewDidUpdatedInfo(frame: self.frame, angle: self.currentAngle)
//            }
//        case .ended:
//            self.brush?.drawInContext()
//            self.setNeedsDisplay()
//            if let delegate = self.delegate {
//                delegate.overlayViewDidEndRotating(self)
//                // delegate.overlayViewDidUpdatedInfo(frame: self.frame, angle: self.currentAngle)
//            }
//        default:
//            break
//        }
//    }
    
    @objc func handleCloseGesture(_ recognizer: UITapGestureRecognizer) {
        /// print("Handle Close Button")
        if let delegate = self.delegate {
            delegate.overlayViewDidClose(self)
        }
        self.removeFromSuperview()
    }
    
    @objc func handleFlipGesture(_ recognizer: UITapGestureRecognizer) {
        /// print("Flipped")
        UIView.animate(withDuration: 0.3) {
            self.contentView.transform = self.contentView.transform.scaledBy(x: -1, y: 1)
        }
    }
    
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        /// print("Tapped Found on Overlay")
        if let delegate = self.delegate {
            delegate.overlayViewDidTap(self)
        }
    }
    
    // MARK: - Private Methods
    
    private func setEnableClose(_ enableClose:Bool) {
        self.closeLineButton.isHidden = !enableClose
        self.closeLineButton.isUserInteractionEnabled = enableClose
    }
    
    private func setEnableRotate(_ enableRotate:Bool) {
        self.rotateLineButton.isHidden = !enableRotate
        self.rotateLineButton.isUserInteractionEnabled = enableRotate
    }
    
    private func setEnableFlip(_ enableFlip:Bool) {
        self.flipLineButton.isHidden = !enableFlip
        self.flipLineButton.isUserInteractionEnabled = enableFlip
    }
}

extension OverlayLineView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension OverlayLineView{
    
    public func setAnchorPoint( point: CGPoint) {
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
