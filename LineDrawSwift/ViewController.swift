//
//  ViewController.swift
//  LineDrawSwift
//
//  Created by MacBook Pro on 9/23/20.
//  Copyright © 2020 MacBook Pro. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate{
    
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
        //drawingContainerView.undo()
        print("UndoLen  ", drawingContainerView.undoBrushStack.count)
        let index = drawingContainerView.undoBrushStack.count - 1
        if index < 0 {
            return
        }
        drawingContainerView.redoBrushStack.append(drawingContainerView.undoBrushStack[index])
        drawingContainerView.undoBrushStack.remove(at: index)
        drawingContainerView.redrawInContext()
        
    }
    
    @IBAction func tappedOnRedo(_ sender: UIButton) {
        //drawingContainerView.redo()
        print("RedoLen  ", drawingContainerView.redoBrushStack.count)
        let index = drawingContainerView.redoBrushStack.count - 1
        if index < 0 {
            return
        }
        drawingContainerView.undoBrushStack.append(drawingContainerView.redoBrushStack[index])
        drawingContainerView.redoBrushStack.remove(at: index)
        drawingContainerView.redrawInContext()
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
      /// print("Chnage ")
    }
    
    func overlayViewDidEndMoving(_ stickerView: OverlayLineView) {
       /// print("")
    }
    
    func overlayViewDidBeginRotating(_ stickerView: OverlayLineView) {
      ///  print("")
    }
    
    func overlayViewDidChangeRotating(_ stickerView: OverlayLineView) {
        //print("")
    }
    
    func overlayViewDidEndRotating(_ stickerView: OverlayLineView) {
       /// print("")
    }
    
    func overlayViewDidClose(_ stickerView: OverlayLineView) {
       /// print("")
    }
    
    func overlayViewDidTap(_ stickerView: OverlayLineView) {
        ///print("")
    }
    
}

extension ViewController: TouchDrawViewDelegate{
    
    func undoEnable(_ isEnable: Bool) {
        print("Undo")
    }
    
    func redoEnable(_ isEnable: Bool) {
        print("Redo")
    }
    
}
