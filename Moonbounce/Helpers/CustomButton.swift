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
    
    @IBInspectable var borderColor: NSColor = .white
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
    
    @IBInspectable var titleColor: NSColor = .white
    {
        didSet
        {
            self.attributedTitle = getAttributedTitle()
        }
    }
    
    @IBInspectable var bgColorHover: NSColor = .clear
    @IBInspectable var titleColorHover: NSColor = .blue
    
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
        
        let buttonAttributes: [String: AnyObject] = [NSForegroundColorAttributeName: titleColor,
                                                     NSFontAttributeName: self.font!,
                                                     NSParagraphStyleAttributeName: paragraphStyle]
        let attributedTitle = NSAttributedString(string: self.title, attributes: buttonAttributes)
        return attributedTitle
    }
    
}
