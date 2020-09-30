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
        drawingContainerView.undo()
    }
    
    @IBAction func tappedOnRedo(_ sender: UIButton) {
        drawingContainerView.redo()
    }
    
}
extension ViewController: OverlayViewViewDelegate{
    
    func overlayViewDidUpdatedInfo(frame: CGRect, angle: CGFloat) {
        print("Update Active    ", frame,"     ", angle)
    }
    
    func overlayViewDidBeginMoving(_ stickerView: OverlayLineView) {
        print("Movi Ovelay")
    }
    
    func overlayViewDidChangeMoving(_ stickerView: OverlayLineView) {
      // print("Chnage ")
    }
    
    func overlayViewDidEndMoving(_ stickerView: OverlayLineView) {
       // print("")
    }
    
    func overlayViewDidBeginRotating(_ stickerView: OverlayLineView) {
      //  print("")
    }
    
    func overlayViewDidChangeRotating(_ stickerView: OverlayLineView) {
        //print("")
    }
    
    func overlayViewDidEndRotating(_ stickerView: OverlayLineView) {
       // print("")
    }
    
    func overlayViewDidClose(_ stickerView: OverlayLineView) {
       // print("")
    }
    
    func overlayViewDidTap(_ stickerView: OverlayLineView) {
        //print("")
    }
}
