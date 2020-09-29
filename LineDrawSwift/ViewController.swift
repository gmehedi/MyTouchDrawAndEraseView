//
//  ViewController.swift
//  LineDrawSwift
//
//  Created by MacBook Pro on 9/23/20.
//  Copyright © 2020 MacBook Pro. All rights reserved.
//

//let v = DrawingView(frame: self.containerView.frame)
//       v.backgroundColor = UIColor.lightGray
//       self.containerView.addSubview(v)

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate, TouchDrawViewDelegate{
    
    @IBOutlet weak var drawingContainerView: TouchDrawView!
    var lineView: UIView!
    var drawingView = DrawingView()
    override func viewDidLoad() {
        super.viewDidLoad()
        drawingContainerView.delegate = self
        drawingContainerView.lineWidth = 10
        
    }
    
    @IBAction func tappedOnDrawButton(_ sender: UIButton) {
        drawingContainerView.brushType = BrushType.pen
        print("Draw")
    }
    
    @IBAction func tappedOnEraseButton(_ sender: UIButton) {
         drawingContainerView.brushType = BrushType.eraser
        print("Eraser")
    }
    
    @IBAction func tappedOnLine(_ sender: UIButton) {
        drawingContainerView.brushType = BrushType.line
    }
    
    @IBAction func tappedOnRect(_ sender: Any) {
        drawingContainerView.brushType = BrushType.rect
    }
    
    @IBAction func tappedOnEllips(_ sender: UIButton) {
        drawingContainerView.brushType = BrushType.ellipse
    }
    
    @IBAction func tappedOnUndo(_ sender: UIButton) {
       // drawingContainerView.undo()
    }
    
    @IBAction func tappedOnRedo(_ sender: UIButton) {
        drawingContainerView.redo()
    }
    
}

extension ViewController{
    func takeOverLayLineView(frame: CGRect, angle: CGFloat){
        
        self.lineView = UIView(frame: frame) //CGRect(x: 0, y: 0, width: 100, height: 60)
        self.lineView.backgroundColor = UIColor.clear
        let overlayView = OverlayLineView.init(contentView: self.lineView, origin: frame.origin)
        overlayView.showEditingHandlers = true
        overlayView.delegate = self
        overlayView.setImage(UIImage.init(named: "Close")!, forHandler: StickerViewHandler.close)
        overlayView.setImage(UIImage.init(named: "Rotate")!, forHandler: StickerViewHandler.rotate)
        //  stickerView.setImage(UIImage.init(named: "Flip")!, forHandler: StickerViewHandler.flip)
        overlayView.showEditingHandlers = true
        overlayView.tag = 999
        overlayView.setAnchorPoint(point: CGPoint(x: 0, y: 0.5))
        overlayView.transform = CGAffineTransform(rotationAngle: angle)
      //  print("IIII  ", (stickerView.brush?.beginPoint!.x)! - frame.size.width)
      //  stickerView.brush?.currentPoint!.x = (stickerView.brush?.beginPoint!.x)! + frame.size.width
        overlayView.brush?.drawInContext()
        self.drawingContainerView.addSubview(overlayView)
    }
}
extension ViewController: StickerViewDelegate{
    func overlayViewDidBeginMoving(_ stickerView: OverlayLineView) {
        print("")
    }
    
    func overlayViewDidChangeMoving(_ stickerView: OverlayLineView) {
        print("")
    }
    
    func overlayViewDidEndMoving(_ stickerView: OverlayLineView) {
        print("")
    }
    
    func overlayViewDidBeginRotating(_ stickerView: OverlayLineView) {
        print("")
    }
    
    func overlayViewDidChangeRotating(_ stickerView: OverlayLineView) {
        print("")
    }
    
    func overlayViewDidEndRotating(_ stickerView: OverlayLineView) {
        print("")
    }
    
    func overlayViewDidClose(_ stickerView: OverlayLineView) {
        print("")
    }
    
    func overlayViewDidTap(_ stickerView: OverlayLineView) {
        print("")
    }
    
    func addLine(frame: CGRect, angle: CGFloat) {
        self.takeOverLayLineView(frame: frame, angle: angle)
    }
}
