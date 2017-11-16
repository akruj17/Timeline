//
//  TimelineEventBox.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 6/17/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TimelineEventBox: UIView {

    var eventBox = UIView()
    var textView = UITextView()
    var supplementalView: UIView!
    let colorConstant: CGFloat = 100
    var alreadyConstructed = false
    
    var isTitleScreenEventBox: Bool = false
    var isTopRow: Bool = false
    var isFirstOfYear: Bool = false
    var stringVal: String = ""
    var year: Int?
    var color: UIColor = UIColor()
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        textView.isEditable = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.textAlignment = .center
    }

    override func draw(_ rect: CGRect) {
        var boxFrame = CGRect()
        var subFrame = CGRect()
        var supplementalFrame  = CGRect()
        let boxHeight: CGFloat = 0.7 * rect.size.height
        
        if isTitleScreenEventBox {
            textView.font = UIFont(name: "AvenirNext-Regular", size: 20)
            textView.textAlignment = NSTextAlignment.center
        }
        else {
            textView.font = UIFont(name: "AvenirNext-Regular", size: 25)
        }
        
        boxFrame.size = CGSize(width: rect.width, height: boxHeight)
        
        if isFirstOfYear {      // the supplemental view will be the year displayed
            supplementalView = UILabel()
            (supplementalView as! UILabel).text = String(describing: year!)
            (supplementalView as! UILabel).font = UIFont(name: "AvenirNext-Bold", size: 32)
            (supplementalView as! UILabel).textAlignment = .center
            supplementalFrame.size = CGSize(width: rect.width, height: rect.height - boxHeight)
        } else {               // the supplemental view will be a stick
            supplementalView = UIView()
            supplementalFrame.size = CGSize(width: 5, height: rect.height - boxHeight)
            supplementalView.backgroundColor = color
        }
        
        if isTopRow {
            boxFrame.origin = CGPoint(x: 0, y: 0)
            supplementalFrame.origin = CGPoint(x: 0, y: boxHeight)
        }
        else {
            boxFrame.origin = CGPoint(x: 0, y: rect.size.height - boxHeight)
            supplementalFrame.origin = CGPoint(x: 0, y: 0)
        }
        
        eventBox.frame = boxFrame
        supplementalView.frame = supplementalFrame
        subFrame = boxFrame
        subFrame.origin = CGPoint(x: 0, y: 0)
        textView.frame = subFrame
        
        if !isTitleScreenEventBox && !alreadyConstructed {
            let blurEffect = UIBlurEffect(style: .light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = subFrame
            eventBox.insertSubview(blurEffectView, at: 1)
            alreadyConstructed = true
        }
        
        eventBox.layer.borderWidth = 5
        eventBox.backgroundColor = UIColor.clear
        textView.backgroundColor = UIColor.clear
        textView.backgroundColor = UIColor.clear
        textView.text = stringVal
        
        eventBox.layer.borderColor = color.cgColor
        eventBox.center.x = self.center.x
        supplementalView.center.x = self.center.x

        eventBox.addSubview(textView)
        self.addSubview(eventBox)
        self.addSubview(supplementalView)

    }
    
    
}

