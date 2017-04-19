//
//  CustomButton.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/29/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

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
    @IBInspectable var titleColorHover: NSColor = mbPink
    
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
            path.lineCapStyle = NSLineCapStyle.squareLineCapStyle
            
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
    
    override var isEnabled: Bool
    {
        didSet
        {
            if isEnabled
            {
                self.attributedTitle = getAttributedTitle()
            }
            else
            {
                self.attributedTitle = getDisabledAttributedTitle()
            }
        }
    }
        
    func getAttributedTitle() -> NSAttributedString
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let buttonAttributes: [String: AnyObject] = [NSForegroundColorAttributeName: titleColor,
                                                     NSFontAttributeName: self.font!,
                                                     NSParagraphStyleAttributeName: paragraphStyle]
        let attributedTitle = NSAttributedString(string: self.title, attributes: buttonAttributes)
        return attributedTitle
    }
    
    func getDisabledAttributedTitle() -> NSAttributedString
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let buttonAttributes: [String: AnyObject] = [NSForegroundColorAttributeName: NSColor.white,
                                                     NSFontAttributeName: self.font!,
                                                     NSParagraphStyleAttributeName: paragraphStyle]
        let attributedTitle = NSAttributedString(string: self.title, attributes: buttonAttributes)
        
        return attributedTitle
    }
    
}
