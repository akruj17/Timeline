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
    var customHeight : CGFloat = 66
        
    override func sizeThatFits(_ size: CGSize) -> CGSize {
            
        return CGSize(width: UIScreen.main.bounds.width, height: customHeight)
            
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
            
        frame = CGRect(x: frame.origin.x, y:  0, width: frame.size.width, height: customHeight)
            
        // title position (statusbar height / 2)
        setTitleVerticalPositionAdjustment(0, for: UIBarMetrics.default)
            
        for subview in self.subviews {
            var stringFromClass = NSStringFromClass(subview.classForCoder)
            if stringFromClass.contains("BarBackground") {
                subview.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: customHeight)
             //   subview.backgroundColor = .yellow
            }
        
            stringFromClass = NSStringFromClass(subview.classForCoder)
            print("\(stringFromClass)")
            if stringFromClass.contains("BarContent") {
                if stringFromClass.contains("Title") {
                    print("HI")
                } else {
                    subview.frame = CGRect(x: subview.frame.origin.x, y: 20, width: subview.frame.width, height: customHeight - 20)
                }
                
                
               // subview.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 0.4)
                
                }
            }
}
}
