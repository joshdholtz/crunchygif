//
//  AspectFillImageView.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 10/26/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

class AspectFillImageView: NSImageView {
    override var image: NSImage? {
          set {
                self.layer = CALayer()
                self.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
                self.layer?.contents = newValue
                self.wantsLayer = true

                super.image = newValue
          }

          get {
                return super.image
          }
    }
}
