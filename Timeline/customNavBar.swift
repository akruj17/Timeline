//
//  customNavBar.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 11/25/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class customNavBar: UINavigationBar {
        
    //set NavigationBar's height
    var customHeight : CGFloat = 60
        
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: customHeight)
            
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        customHeight = (UIScreen.main.traitCollection.verticalSizeClass == .regular) ? 60 : 32
        frame = CGRect(x: frame.origin.x, y:  0, width: frame.size.width, height: customHeight)
            
        // title position (statusbar height / 2)
        setTitleVerticalPositionAdjustment(0, for: UIBarMetrics.default)
        for subview in self.subviews {
            let stringFromClass = NSStringFromClass(subview.classForCoder)
            if stringFromClass.contains("BarBackground") {
                subview.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: customHeight)
            } else {
                //center the buttons vertically
                subview.frame = CGRect(x: subview.frame.origin.x, y: (self.frame.height - subview.frame.height) / 2.0, width: subview.frame.width, height: subview.frame.height)
                self.titleTextAttributes = [.font: UIFont(name: "AvenirNext-Regular", size: ((UIScreen.main.traitCollection.verticalSizeClass == .regular) ? 30 : 18))!, .foregroundColor: UIColor.darkGray]
            }
        }
    }
}
