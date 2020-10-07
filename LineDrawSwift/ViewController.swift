//
//  ViewController.swift
//  LineDrawSwift
//
//  Created by MacBook Pro on 9/23/20.
//  Copyright © 2020 MacBook Pro. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate{
    
    @IBOutlet weak var exportImageView: UIImageView!
    @IBOutlet weak var drawingContainerView: UIView!
    var v: TouchDrawView!
    var lineView: UIView!
    var drawingView = DrawingView()
    var outputSize: CGSize!
    let screenWidth = UIScreen.main.bounds.size.width
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Did Load")
        self.outputSize = CGSize(width: screenWidth, height: screenWidth)
        let nextPhoto = UIImage(named: "img1")
        print("Image  Size  ", nextPhoto!.size)
        let horizontalRatio = CGFloat(self.outputSize.width) / nextPhoto!.size.width
        let verticalRatio = CGFloat(self.outputSize.height) / nextPhoto!.size.height
        //let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        let newSize: CGSize = CGSize(width: nextPhoto!.size.width * aspectRatio, height: nextPhoto!.size.height * aspectRatio)
        let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
        let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0
        v = TouchDrawView(frame: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
      //  v.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
        v!.delegate = self
        v!.lineWidth = 10
        v!.setImage(UIImage(named: "img1")!)
        v.clipsToBounds = true
        self.drawingContainerView.addSubview(v)
        
    }
    
    @IBAction func tappedOnDrawButton(_ sender: UIButton) {
        v!.brushType = BrushType.pen
        print("Draw")
    }
    
    @IBAction func tappedOnEraseButton(_ sender: UIButton) {
         v!.brushType = BrushType.eraser
    }
    
    @IBAction func tappedOnLine(_ sender: UIButton) {
        v!.brushType = BrushType.line
    }
    
    @IBAction func tappedOnRect(_ sender: Any) {
        v!.brushType = BrushType.rect
    }
    
    @IBAction func tappedOnEllips(_ sender: UIButton) {
        v!.brushType = BrushType.ellipse
    }
    
    @IBAction func tappedOnUndo(_ sender: UIButton) {
        //drawingContainerView.undo()
        print("UndoLen  ", v!.undoBrushStack.count)
        let index = v!.undoBrushStack.count - 1
        if index < 0 {
            return
        }
        v!.redoBrushStack.append(v!.undoBrushStack[index])
        v!.undoBrushStack.remove(at: index)
        v!.redrawInContext()
        
    }
    
    @IBAction func tappedOnRedo(_ sender: UIButton) {
        //drawingContainerView.redo()
        print("RedoLen  ", v!.redoBrushStack.count)
        let index = v!.redoBrushStack.count - 1
        if index < 0 {
            return
        }
        v!.undoBrushStack.append(v!.redoBrushStack[index])
        v!.redoBrushStack.remove(at: index)
        v!.redrawInContext()
    }
    
    @IBAction func tappedOnExportButton(_ sender: UIButton) {
        let image = v.exportImage()
        self.exportImageView.image = image
        print("Export Image   ",image!.size)
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
