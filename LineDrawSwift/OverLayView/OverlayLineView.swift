//
//  OverlayLineView`.swift
//  GestureWithSingleFinger
//
//  Created by MacBook Pro on 9/27/20.
//  Copyright © 2020 MacBook Pro. All rights reserved.
//

import UIKit

class OverlayLineView: NSObject {

}

//  StickerView.swift
//  StickerView
//
//  Copyright © All rights reserved.
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

@objc public  protocol StickerViewDelegate {
    @objc func stickerViewDidBeginMoving(_ stickerView: StickerView)
    @objc func stickerViewDidChangeMoving(_ stickerView: StickerView)
    @objc func stickerViewDidEndMoving(_ stickerView: StickerView)
    @objc func stickerViewDidBeginRotating(_ stickerView: StickerView)
    @objc func stickerViewDidChangeRotating(_ stickerView: StickerView)
    @objc func stickerViewDidEndRotating(_ stickerView: StickerView)
    @objc func stickerViewDidClose(_ stickerView: StickerView)
    @objc func stickerViewDidTap(_ stickerView: StickerView)
}

public class StickerView: UIView {
    public var delegate: StickerViewDelegate!
    /// The contentView inside the sticker view.
    public var contentView:UIView!
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
    
    public  init(contentView: UIView, origin: CGPoint) {
        self.defaultInset = 11
        self.defaultMinimumSize = 4 * self.defaultInset
        
        var frame = contentView.frame
       // frame = CGRect(x: origin.x, y: origin.y, width: frame.size.width + CGFloat(self.defaultInset) * 2, height: frame.size.height + CGFloat(self.defaultInset) * 2)
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.addGestureRecognizer(self.moveGesture)
        self.addGestureRecognizer(self.tapGesture)
        
        // Setup content view
        self.contentView = contentView
        self.contentView.center = CGRectGetCenter(self.bounds)
        self.contentView.isUserInteractionEnabled = false
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.layer.allowsEdgeAntialiasing = true
        self.addSubview(self.contentView)
        
        // Setup editing handlers
        self.setPosition(.topRight, forHandler: .close)
        self.addSubview(self.closeImageView)
        self.setPosition(.bottomRight, forHandler: .rotate)
        self.addSubview(self.rotateImageView)
        self.setPosition(.topLeft, forHandler: .flip)
        self.addSubview(self.flipImageView)
        
        self.showEditingHandlers = true
        self.enableClose = true
        self.enableRotate = true
        self.enableFlip = true
        
        self.minimumSize = self.defaultMinimumSize
        self.outlineBorderColor = .brown
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
        print("setImage")
        switch handler {
        case .close:
            self.closeImageView.image = image
        case .rotate:
            self.rotateImageView.image = image
        case .flip:
            self.flipImageView.image = image
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
    
    public func setPosition(_ position:StickerViewPosition, forHandler handler:StickerViewHandler) {
        let origin = self.contentView.frame.origin
        let size = self.contentView.frame.size
        
        var handlerView:UIImageView?
        print("Set Image Now")
        switch handler {
        case .close:
            handlerView = self.closeImageView
            print("Close")
        case .rotate:
            print("RTRT")
            handlerView = self.rotateImageView
        case .flip:
            handlerView = self.flipImageView
        }
        
        switch position {
        case .topLeft:
            print("G1")
            handlerView?.center = origin
            handlerView?.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        case .topRight:
            print("RT!")
            handlerView?.center = CGPoint(x: origin.x, y: origin.y + 30.0)
            handlerView?.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
//            handlerView?.center = CGPoint(x: origin.x + size.width, y: origin.y)
//            handlerView?.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        case .bottomLeft:
            print("CL1")
            handlerView?.center = CGPoint(x: origin.x, y: origin.y + size.height)
            handlerView?.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        case .bottomRight:
            print("CL2")
            handlerView?.center = CGPoint(x: origin.x + size.width, y: origin.y + (size.height * 0.5))
            handlerView?.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        }
        
        handlerView?.tag = position.rawValue
    }
    
    /**
     *  Customize handler's size
     *
     *  @param size Handler's size
     */
    public func setHandlerSize(_ size:Int) {
        if size <= 0 {
            return
        }
        
        self.defaultInset = NSInteger(round(Float(size) / 2))
        self.defaultMinimumSize = 4 * self.defaultInset
        self.minimumSize = max(self.minimumSize, self.defaultMinimumSize)
        
        let originalCenter = self.center
        let originalTransform = self.transform
        var frame = self.contentView.frame
        frame = CGRect(x: 0, y: 0, width: frame.size.width + CGFloat(self.defaultInset) * 2, height: frame.size.height + CGFloat(self.defaultInset) * 2)
        
        self.contentView.removeFromSuperview()
        
        self.transform = CGAffineTransform.identity
        self.frame = frame
        
        self.contentView.center = CGRectGetCenter(self.bounds)
        self.addSubview(self.contentView)
        self.sendSubviewToBack(self.contentView)
        
        let handlerFrame = CGRect(x: 0, y: 0, width: self.defaultInset * 2, height: self.defaultInset * 2)
        self.closeImageView.frame = handlerFrame
        print("TAG    ", self.closeImageView.tag,"    ", self.rotateImageView.tag)
        self.setPosition(StickerViewPosition(rawValue: self.closeImageView.tag)!, forHandler: .close)
        self.rotateImageView.frame = handlerFrame
        self.setPosition(StickerViewPosition(rawValue: self.rotateImageView.tag)!, forHandler: .rotate)
        self.flipImageView.frame = handlerFrame
        self.setPosition(StickerViewPosition(rawValue: self.flipImageView.tag)!, forHandler: .flip)
        
        self.center = originalCenter
        self.transform = originalTransform
    }
    
    /**
     *  Default value
     */
    private var defaultInset:NSInteger
    private var defaultMinimumSize:NSInteger
    
    /**
     *  Variables for moving viewes
     */
    public var beginningPoint = CGPoint.zero
    public var beginningCenter = CGPoint.zero
    
    /**
     *  Variables for rotating and resizing viewes
     */
    private var initialBounds = CGRect.zero
    private var initialDistance:CGFloat = 0
    private var deltaAngle:CGFloat = 0
    
    public lazy var moveGesture = {
        return UIPanGestureRecognizer(target: self, action: #selector(handleMoveGesture(_:)))
    }()
    public lazy var rotateImageView:UIImageView = {
        let rotateImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.defaultInset * 3, height: self.defaultInset * 3))
        rotateImageView.contentMode = UIView.ContentMode.scaleAspectFit
        rotateImageView.backgroundColor = UIColor.clear
        rotateImageView.isUserInteractionEnabled = true
        rotateImageView.addGestureRecognizer(self.rotateGesture)
        //print("Need to update")
        
        return rotateImageView
    }()
    private lazy var rotateGesture = {
        return UIPanGestureRecognizer(target: self, action: #selector(handleRotateGesture(_:)))
    }()
    private lazy var closeImageView:UIImageView = {
        let closeImageview = UIImageView(frame: CGRect(x: 0, y: 0, width: self.defaultInset * 2, height: self.defaultInset * 2))
        closeImageview.contentMode = UIView.ContentMode.scaleAspectFit
        closeImageview.backgroundColor = UIColor.clear
        closeImageview.isUserInteractionEnabled = true
        closeImageview.addGestureRecognizer(self.closeGesture)
        return closeImageview
    }()
    private lazy var closeGesture = {
        return UITapGestureRecognizer(target: self, action: #selector(handleCloseGesture(_:)))
    }()
    private lazy var flipImageView:UIImageView = {
        let flipImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.defaultInset * 2, height: self.defaultInset * 2))
        flipImageView.contentMode = UIView.ContentMode.scaleAspectFit
        flipImageView.backgroundColor = UIColor.clear
        flipImageView.isUserInteractionEnabled = true
        flipImageView.addGestureRecognizer(self.flipGesture)
        return flipImageView
    }()
    private lazy var flipGesture = {
        return UITapGestureRecognizer(target: self, action: #selector(handleFlipGesture(_:)))
    }()
    private lazy var tapGesture = {
        return UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
    }()
    // MARK: - Gesture Handlers
    @objc
    func handleMoveGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        switch recognizer.state {
        case .began:
            self.beginningPoint = touchLocation
            self.beginningCenter = self.center
            if let delegate = self.delegate {
                delegate.stickerViewDidBeginMoving(self)
            }
        case .changed:
            self.center = CGPoint(x: self.beginningCenter.x + (touchLocation.x - self.beginningPoint.x), y: self.beginningCenter.y + (touchLocation.y - self.beginningPoint.y))
            if let delegate = self.delegate {
                delegate.stickerViewDidChangeMoving(self)
            }
        case .ended:
            self.center = CGPoint(x: self.beginningCenter.x + (touchLocation.x - self.beginningPoint.x), y: self.beginningCenter.y + (touchLocation.y - self.beginningPoint.y))
            if let delegate = self.delegate {
                delegate.stickerViewDidEndMoving(self)
            }
        default:
            break
        }
    }
    
    @objc
    func handleRotateGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        let center = self.center
        
        switch recognizer.state {
        case .began:
            self.deltaAngle = CGFloat(atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))) - CGAffineTransformGetAngle(self.transform)
            self.initialBounds = self.bounds
            self.initialDistance = CGPointGetDistance(point1: center, point2: touchLocation)
            if let delegate = self.delegate {
                delegate.stickerViewDidBeginRotating(self)
            }
        case .changed:
            let angle = atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))
            let angleDiff = Float (self.deltaAngle) - angle
            setAnchorPoint(point: CGPoint(x: 0, y: 0.5))
            self.transform = CGAffineTransform(rotationAngle: CGFloat(-angleDiff))
            var scale = CGPointGetDistance(point1: center, point2: touchLocation) / self.initialDistance
            let minimumScale = CGFloat(self.minimumSize) / min(self.initialBounds.size.width, self.initialBounds.size.height)
            scale = max(scale, minimumScale)
            let scaledBounds = CGRectScale(self.initialBounds, wScale: scale, hScale: 1)
            self.bounds = scaledBounds
            self.setNeedsDisplay()
            
            if let delegate = self.delegate {
                delegate.stickerViewDidChangeRotating(self)
            }
        case .ended:
            if let delegate = self.delegate {
                delegate.stickerViewDidEndRotating(self)
            }
        default:
            break
        }
    }
    
    @objc
    func handleCloseGesture(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate {
            delegate.stickerViewDidClose(self)
        }
        self.removeFromSuperview()
    }
    
    @objc
    func handleFlipGesture(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3) {
            self.contentView.transform = self.contentView.transform.scaledBy(x: -1, y: 1)
        }
    }
    
    @objc
    func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate {
            delegate.stickerViewDidTap(self)
        }
    }
    
    // MARK: - Private Methods
    private func setEnableClose(_ enableClose:Bool) {
        self.closeImageView.isHidden = !enableClose
        self.closeImageView.isUserInteractionEnabled = enableClose
    }
    
    private func setEnableRotate(_ enableRotate:Bool) {
        self.rotateImageView.isHidden = !enableRotate
        self.rotateImageView.isUserInteractionEnabled = enableRotate
    }
    
    private func setEnableFlip(_ enableFlip:Bool) {
        self.flipImageView.isHidden = !enableFlip
        self.flipImageView.isUserInteractionEnabled = enableFlip
    }
}

extension StickerView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
extension StickerView{
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
