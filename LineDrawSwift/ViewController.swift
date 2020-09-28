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
    
    
    
    @IBOutlet weak var drawingView: TouchDrawView!
    var lineView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawingView.delegate = self
        drawingView.lineWidth = 10
        
    }
    
    @IBAction func tappedOnDrawButton(_ sender: UIButton) {
        drawingView.brushType = BrushType.pen
        print("Draw")
    }
    
    @IBAction func tappedOnEraseButton(_ sender: UIButton) {
         drawingView.brushType = BrushType.eraser
        print("Eraser")
    }
    
    @IBAction func tappedOnLine(_ sender: UIButton) {
        drawingView.brushType = BrushType.line
    }
    
    @IBAction func tappedOnRect(_ sender: Any) {
        drawingView.brushType = BrushType.rect
    }
    
    @IBAction func tappedOnEllips(_ sender: UIButton) {
        drawingView.brushType = BrushType.ellipse
    }
    
    @IBAction func tappedOnUndo(_ sender: UIButton) {
        drawingView.undo()
    }
    
    @IBAction func tappedOnRedo(_ sender: UIButton) {
        drawingView.redo()
    }
}

extension ViewController{
    func takeOverLayLineView(frame: CGRect, angle: CGFloat){
        
        self.lineView = UIView(frame: frame) //CGRect(x: 0, y: 0, width: 100, height: 60)
        self.lineView.backgroundColor = UIColor.clear
        let stickerView = StickerView.init(contentView: self.lineView, origin: frame.origin)
        stickerView.showEditingHandlers = true
        stickerView.delegate = self
        stickerView.setImage(UIImage.init(named: "Close")!, forHandler: StickerViewHandler.close)
        stickerView.setImage(UIImage.init(named: "Rotate")!, forHandler: StickerViewHandler.rotate)
        //  stickerView.setImage(UIImage.init(named: "Flip")!, forHandler: StickerViewHandler.flip)
        stickerView.showEditingHandlers = true
        stickerView.tag = 999
        stickerView.setAnchorPoint(point: CGPoint(x: 0, y: 0.5))
        stickerView.transform = CGAffineTransform(rotationAngle: angle)
        self.drawingView.addSubview(stickerView)
    }
    func addLine(frame: CGRect, angle: CGFloat) {
        self.takeOverLayLineView(frame: frame, angle: angle)
    }
    
}
extension ViewController: StickerViewDelegate{
    func stickerViewDidBeginMoving(_ stickerView: StickerView) {
        print("")
    }
    
    func stickerViewDidChangeMoving(_ stickerView: StickerView) {
        print("")
    }
    
    func stickerViewDidEndMoving(_ stickerView: StickerView) {
        print("")
    }
    
    func stickerViewDidBeginRotating(_ stickerView: StickerView) {
        print("")
    }
    
    func stickerViewDidChangeRotating(_ stickerView: StickerView) {
        print("")
    }
    
    func stickerViewDidEndRotating(_ stickerView: StickerView) {
        print("")
    }
    
    func stickerViewDidClose(_ stickerView: StickerView) {
        print("")
    }
    
    func stickerViewDidTap(_ stickerView: StickerView) {
        print("")
    }
}
