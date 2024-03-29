//
//  CustomButton.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/29/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

public let mbPink = NSColor(red:0.92, green:0.55, blue:0.73, alpha:1.0)
public let mbDarkBlue = NSColor(red:0.00, green:0.06, blue:0.16, alpha:1.0)
public let mbBlue = NSColor(red:0.16, green:0.20, blue:0.48, alpha:1.0)
public let mbWhite = NSColor(red:0.97, green:0.97, blue:0.98, alpha:1.0)

@IBDesignable class CustomButton: NSButton
{
    //This allows you to set the custom button's corner radius in Interface Builder
    @IBInspectable var cornerRadius: CGFloat = 10
    {
        didSet
        {
            layer?.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderColor: NSColor = mbWhite
    {
        didSet
        {
            layer?.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2
    {
        didSet
        {
            layer?.borderWidth = borderWidth
        }
    }
    
    //This allows you to set the button's background color in Interface Builder
    @IBInspectable var backgroundColor: NSColor = .clear
    {
        didSet
        {
            layer?.backgroundColor = backgroundColor.cgColor
        }
    }
    
    @IBInspectable var titleColor: NSColor = mbWhite
    {
        didSet
        {
            self.attributedTitle = getAttributedTitle()
        }
    }
    
    @IBInspectable var halfBorder: Bool = false
    {
        didSet
        {
            //
        }
    }
    
    //TODO: These have not yet been implemented
    @IBInspectable var bgColorHover: NSColor = .clear
    @IBInspectable var titleColorHover: NSColor = mbWhite
    
    //A little prep work to make sure everything is in order
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        self.wantsLayer = true
    }
    
    override func prepareForInterfaceBuilder()
    {
        self.attributedTitle = getAttributedTitle()
        layer?.backgroundColor = backgroundColor.cgColor
        layer?.borderColor = borderColor.cgColor
        layer?.borderWidth = borderWidth
        layer?.cornerRadius = cornerRadius
    }
    
    override func awakeFromNib()
    {
        self.attributedTitle = getAttributedTitle()
        layer?.backgroundColor = backgroundColor.cgColor
        layer?.borderColor = borderColor.cgColor
        layer?.borderWidth = borderWidth
        layer?.cornerRadius = cornerRadius
    }
    
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
        
        if halfBorder
        {
            //Ignore the other settings
            cornerRadius = 0
            borderWidth = 0
            borderColor = .clear
            
            //Draw the half border
            let cornerRad: CGFloat = 10
            let lineWidth: CGFloat = 2
            
            let path = NSBezierPath()
            path.lineWidth = lineWidth
            path.lineCapStyle = NSBezierPath.LineCapStyle.square
            
            let bottomLeft = NSMakePoint(NSMinX(bounds) + lineWidth + cornerRad, NSMaxY(bounds) - 1)
            let bottomLeftCorner = NSMakePoint(NSMinX(bounds) + lineWidth + 2, NSMaxY(bounds) - 3)
            let bottomRight = NSMakePoint(NSMaxX(bounds) - lineWidth - cornerRad, NSMaxY(bounds) - 1)
            let bottomRightCorner = NSMakePoint(NSMaxX(bounds) - 2 - lineWidth, NSMaxY(bounds) - 3)
            let halfUpOnLeft = NSMakePoint(NSMinX(bounds) + lineWidth, NSMaxY(bounds)/2)
            let halfUpOnRight = NSMakePoint(NSMaxX(bounds) - lineWidth, NSMaxY(bounds)/2)
            
            path.move(to: halfUpOnLeft)
            path.line(to: NSMakePoint(NSMinX(bounds) + lineWidth, (NSMaxY(bounds)/2) + 1))
            path.curve(to: bottomLeft, controlPoint1: bottomLeftCorner, controlPoint2: bottomLeftCorner)
            path.line(to: bottomRight)
            path.curve(to: NSMakePoint(NSMaxX(bounds) - lineWidth, (NSMaxY(bounds)/2) + 1), controlPoint1: bottomRightCorner, controlPoint2: bottomRightCorner)
            path.line(to: halfUpOnRight)
            
            mbWhite.setStroke()
            path.stroke()
        }
    }
    
    override var title: String
    {
        didSet
        {
            self.attributedTitle = getAttributedTitle()
        }
    }
    
    func getAttributedTitle() -> NSAttributedString
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let buttonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): titleColor,
                                                               NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): self.font!,
                                                               NSAttributedString.Key(rawValue: NSAttributedString.Key.paragraphStyle.rawValue): paragraphStyle]
        let attributedTitle = NSAttributedString(string: self.title, attributes: buttonAttributes)
        return attributedTitle
    }
    
}
