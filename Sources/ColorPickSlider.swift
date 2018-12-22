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
    let trackLayer = ColorPickSliderTrackLayer()
    let thumbLayer = ColorPickSliderThumbLayer()
    var thumbSize: CGFloat {
        return CGFloat(bounds.height)
    }
    var curvaceousness: CGFloat = 1.0 {
        didSet {
            trackLayer.setNeedsDisplay()
            thumbLayer.setNeedsDisplay()
        }
    }
    
    let minimumValue = 0.0
    let maximumValue = 1.0
    var value = 0.0  {
        didSet {
            updateLayerFrames()
            print(value)
        }
    }
    
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
        // trackLayer.backgroundColor = UIColor.blue.cgColor
        trackLayer.colorPickSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)
        
        // thumbLayer.backgroundColor = UIColor.green.cgColor
        thumbLayer.colorPickSlider = self
        thumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(thumbLayer)
        
        updateLayerFrames()
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        trackLayer.frame = bounds.insetBy(dx: thumbSize/2.0, dy: bounds.height/3.0)
        trackLayer.setNeedsDisplay()
        
        let thumbCenter = CGFloat(positionForValue(value))
        thumbLayer.frame = CGRect(x: thumbCenter - thumbSize / 2.0, y: 0.0,
                                  width: thumbSize, height: thumbSize)
        thumbLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func positionForValue(_ value: Double) -> Double {
        return Double(bounds.width - thumbSize) * (value - minimumValue) /
            (maximumValue - minimumValue) + Double(thumbSize / 2.0)
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self).clamped(to: bounds)
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
        
        previousLocation = location.clamped(to: bounds.insetBy(dx: thumbSize/2.0, dy: thumbSize/2.0))
        
        // 2. Update the values
        if thumbLayer.highlighted {
            value = (value + deltaValue).clamped(minimumValue, maximumValue)
        }
        
        sendActions(for: .valueChanged)
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
    weak var colorPickSlider: ColorPickSlider?
    var highlighted = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(in ctx: CGContext) {
        guard let slider = colorPickSlider else { return }
        
        let thumbFrame = bounds.insetBy(dx: 2.0, dy: 2.0)
        let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
        let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius).cgPath
        
        // Fill - with a subtle shadow
        let shadowColor = UIColor.gray.cgColor
        
        ctx.setShadow(offset: CGSize(width: 0.0, height: 1.0), blur: 1.0, color: shadowColor)
        ctx.setFillColor(UIColor.red.cgColor)
        ctx.addPath(thumbPath)
        ctx.fillPath()
        
        // Outline
        ctx.setStrokeColor(shadowColor)
        ctx.setLineWidth(0.5)
        ctx.addPath(thumbPath)
        ctx.strokePath()
        
        if highlighted {
            ctx.setFillColor(UIColor(white: 0.0, alpha: 0.1).cgColor)
            ctx.addPath(thumbPath)
            ctx.fillPath()
        }
    }
}

class ColorPickSliderTrackLayer: CALayer {
    weak var colorPickSlider: ColorPickSlider?
    
    override func draw(in ctx: CGContext) {
        guard let slider = colorPickSlider else { return }
        
        // Clip
        let cornerRadius = bounds.height * slider.curvaceousness / 2.0
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        ctx.addPath(path)
        
        // Fill the track
        ctx.setFillColor(UIColor.green.cgColor)
        ctx.addPath(path)
        ctx.fillPath()
    }
}
