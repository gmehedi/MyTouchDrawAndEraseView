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

class ViewController: UIViewController, UIGestureRecognizerDelegate, TouchDrawViewDelegate {
    
    @IBOutlet weak var drawingView: TouchDrawView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawingView.lineWidth = 10
        let v = OverlayView()
        v.setOverLayView(locations: CGPoint(x: 100, y: 100))
        v.overlay.backgroundColor = UIColor.red
        drawingView.addSubview(v.overlay)
        
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
