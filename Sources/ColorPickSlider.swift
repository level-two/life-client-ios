//
//  ColorPickSlider.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 12/22/18.
//  Copyright © 2018 Yauheni Lychkouski. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class ColorPickSlider: UIControl {
    let trackLayer = CALayer()
    let thumbLayer = ColorPickSliderThumbLayer()
    var thumbSize: CGFloat {
        return CGFloat(bounds.height)
    }
    
    let minimumValue = 0.0
    let maximumValue = 1.0
    var value = 0.0
    
    var previousLocation = CGPoint()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSublayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSublayers()
    }
    
    func addSublayers() {
        trackLayer.backgroundColor = UIColor.blue.cgColor
        layer.addSublayer(trackLayer)
        
        thumbLayer.backgroundColor = UIColor.green.cgColor
        thumbLayer.colorPickSlider = self
        layer.addSublayer(thumbLayer)
        
        updateLayerFrames()
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    func updateLayerFrames() {
        trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height / 3)
        trackLayer.setNeedsDisplay()
        
        let thumbCenter = CGFloat(positionForValue(value))
        thumbLayer.frame = CGRect(x: thumbCenter - thumbSize / 2.0, y: 0.0,
                                  width: thumbSize, height: thumbSize)
        thumbLayer.setNeedsDisplay()
    }
    
    func positionForValue(_ value: Double) -> Double {
        return Double(bounds.width - thumbSize) * (value - minimumValue) /
            (maximumValue - minimumValue) + Double(thumbSize / 2.0)
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)
        if thumbLayer.frame.contains(previousLocation) {
            thumbLayer.highlighted = true
        }
        return thumbLayer.highlighted
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        
        // 1. Determine by how much the user has dragged
        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - thumbSize)
        
        previousLocation = location.clamped(to: bounds)
        
        // 2. Update the values
        if thumbLayer.highlighted {
            value += deltaValue
            value.clamp(minimumValue, maximumValue)
        }
        
        // 3. Update the UI
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateLayerFrames()
        CATransaction.commit()
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        thumbLayer.highlighted = false
    }
}

extension Double {
    func clamped(_ lower: Double, _ upper: Double) -> Double {
        return min(max(self, lower), upper)
    }
    
    mutating func clamp(_ lower: Double, _ upper: Double) {
        self = min(max(self, lower), upper)
    }
}

extension CGFloat {
    func clamped(_ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        return self < lower ? lower :
               self > upper ? upper : self
    }
}

extension CGPoint {
    func clamped(to rect: CGRect) -> CGPoint {
        return CGPoint(x: self.x.clamped(rect.minX, rect.maxX),
                       y: self.y.clamped(rect.minY, rect.maxY))
    }
}

class ColorPickSliderThumbLayer: CALayer {
    var highlighted = false
    weak var colorPickSlider: ColorPickSlider?
}
