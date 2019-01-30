// -----------------------------------------------------------------------------
//    Copyright (C) 2018 Yauheni Lychkouski.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
// -----------------------------------------------------------------------------

import Foundation
import UIKit
import QuartzCore

@IBDesignable
class ColorPickSlider: UIControl {
    let trackLayer = ColorPickSliderTrackLayer()
    let thumbLayer = ColorPickSliderThumbLayer()
    var thumbSize: CGFloat {
        return bounds.height
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
        }
    }
    
    let gradientColors: [UIColor] = [
        UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0),
        UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0),
        UIColor(red: 0.2, green: 0.2, blue: 1.0, alpha: 1.0),
        UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0),
        ]
    
    var previousLocation = CGPoint()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSublayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSublayers()
    }
    
    #if TARGET_INTERFACE_BUILDER
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if trackLayer == nil {
            addSublayers()
        }
        updateLayerFrames()
    }
    #endif
    
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
        
        let thumbCenter = positionForValue(value).cgFloat
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
    
    var pickedColor: UIColor {
        // Ensure val is in range 0...1
        let val = value.clamped(minimumValue, maximumValue)/(maximumValue-minimumValue)
        let count = Double(gradientColors.count-1)
        let i1 = (val * count).rounded(.down)
        let i2 = (val * count).rounded(.up)
        
        let c1 = gradientColors[Int(i1)].cgColor.components!
        let c2 = gradientColors[Int(i2)].cgColor.components!
        
        // for transition between colors
        let rem = CGFloat((val*count).truncatingRemainder(dividingBy: 1.0))
        
        var c = [CGFloat].init(repeating: 0, count: 4)
        for i in 0..<4 {
            c[i] = c1[i]+(c2[i]-c1[i])*rem
        }
        return UIColor(red: c[0], green: c[1], blue: c[2], alpha: c[3]-0.01)
    }
}

extension Double {
    func clamped(_ lower: Double, _ upper: Double) -> Double {
        return min(max(self, lower), upper)
    }
    
    var cgFloat: CGFloat {
        return CGFloat(self)
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
        
        UIGraphicsPushContext(ctx)
        
        let thumbFrame = bounds.insetBy(dx: 2.0, dy: 2.0)
        let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
        let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius).cgPath
        
        // Fill - with a subtle shadow
        let shadowColor = UIColor.gray.cgColor
        ctx.setShadow(offset: CGSize(width: 0.0, height: 1.0), blur: 1.0, color: shadowColor)
        ctx.setFillColor(slider.pickedColor.cgColor)
        ctx.addPath(thumbPath)
        ctx.fillPath()
 
        
        // Outline
        ctx.setStrokeColor(shadowColor)
        ctx.setLineWidth(0.5)
        ctx.addPath(thumbPath)
        ctx.strokePath()
        
        UIGraphicsPopContext()
    }
}

class ColorPickSliderTrackLayer: CALayer {
    weak var colorPickSlider: ColorPickSlider?
    
    override func draw(in ctx: CGContext) {
        guard let slider = colorPickSlider else { return }
        
        // We need to push context as described here: https://stackoverflow.com/a/27990923
        UIGraphicsPushContext(ctx)
        
        // Clip
        let cornerRadius = bounds.height * slider.curvaceousness / 2.0
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        
        // Fill the track
        let leftPoint = CGPoint.zero
        let rightPoint = CGPoint(x: bounds.size.width, y: 0)
        drawLinearGradient(in: ctx, inside: path, start: leftPoint, end: rightPoint, colors: slider.gradientColors)
        
        UIGraphicsPopContext()
    }
    
    func drawLinearGradient(in ctx:CGContext, inside path:UIBezierPath, start:CGPoint, end:CGPoint, colors:[UIColor])
    {
        ctx.saveGState()
        path.addClip() // use the path as the clipping region
        
        let cgColors = colors.map({ $0.cgColor })
        guard let gradient = CGGradient(colorsSpace: nil, colors: cgColors as CFArray, locations: nil)
            else { return }
        
        ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
        
        ctx.restoreGState() // remove the clipping region for future draw operations
    }
}
