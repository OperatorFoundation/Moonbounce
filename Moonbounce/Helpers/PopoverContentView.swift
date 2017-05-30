//
//  PopoverContentView.swift
//  Moonbounce
//
//  Created by Adelita Schule on 10/25/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class PopoverContentView: NSView
{
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidMoveToWindow()
    {
        guard let frameView = window?.contentView?.superview else { return }
        
        let backgroundView = NSView(frame: frameView.bounds)
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = mbDarkBlue.cgColor
        backgroundView.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        frameView.addSubview(backgroundView, positioned: .below, relativeTo: frameView)
    }

}
