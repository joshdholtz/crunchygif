//
//  ProgressViewController.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 12/30/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

class ProgressViewController: NSViewController {
    
    typealias AnimationCompletion = () -> Void
    
    @IBOutlet private var crunchBackgroundImageView: NSImageView!
    @IBOutlet private var crunchLogoImageView: NSImageView!
    
    private var inProgress = false
    private var animationCompletion: AnimationCompletion?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func stop() {
        self.inProgress = false
    }
    
    func start(animationCompletion: AnimationCompletion?) {
        self.inProgress = true
        self.animationCompletion = animationCompletion
        rotate()
    }
     
    private func rotate() {
        guard inProgress else {
            self.animationCompletion?()
            self.animationCompletion = nil
            return
        }
        
        crunchLogoImageView.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
        
        if crunchLogoImageView.layer?.animationKeys()?.count == 0 || crunchLogoImageView.layer?.animationKeys() == nil {

            CATransaction.begin()

            let rotate = CABasicAnimation(keyPath: "transform.rotation")
            rotate.fromValue = 0
            rotate.toValue = CGFloat(-1 * .pi * 2.0)
            rotate.duration = 2
            rotate.repeatCount = 1

            let scaleUp = CABasicAnimation(keyPath: "transform.scale")
            scaleUp.fromValue = 1
            scaleUp.toValue = 1.25
            scaleUp.duration = 0.6
            scaleUp.repeatCount = 1
            scaleUp.beginTime = CACurrentMediaTime() + 1.9

            let scaleDown = CABasicAnimation(keyPath: "transform.scale")
            scaleDown.fromValue = 1.25
            scaleDown.toValue = 1.0
            scaleDown.duration = 0.6
            scaleDown.repeatCount = 1
            scaleDown.beginTime = CACurrentMediaTime() + 2.5

            CATransaction.setCompletionBlock { [weak self] in
                self?.rotate()
            }

            crunchLogoImageView.layer?.add(rotate, forKey: "rotation")
            crunchLogoImageView.layer?.add(scaleUp, forKey: "scaleUp")
            crunchLogoImageView.layer?.add(scaleDown, forKey: "scaleDown")
            CATransaction.commit()
        }
    }
}
