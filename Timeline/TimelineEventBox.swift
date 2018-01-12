//
//  TimelineEventBox.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 6/17/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TimelineEventBox: UIView {
    
    var eventBox: UIView
    var textView: UITextView
    var supplementalView: UIView
    var stickView: UIView
    var textViewBlur: UIVisualEffectView
    var yearBlur: UIVisualEffectView
    var yearLabel: UILabel

    let colorConstant: CGFloat = 100
    var alreadyConstructed: Bool = false

    var isTitleScreenEventBox: Bool = false
    var isTopRow: Bool = false
    var isFirstOfYear: Bool = false
    var stringVal: String = ""
    var year: Int?
    var color: UIColor = UIColor()

    required init?(coder aDecoder: NSCoder) {
        eventBox = UIView()
        textView = UITextView()
        supplementalView = UIView()
        stickView = UIView()
        textViewBlur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        yearBlur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        yearLabel = UILabel()
        
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
            eventBox.layer.borderWidth = 5
            supplementalFrame.size = CGSize(width: rect.width, height: rect.height - boxHeight)
        }
        else {
            textView.font = UIFont(name: "AvenirNext-Regular", size: 25)
            supplementalFrame.size = CGSize(width: rect.width / 2, height: rect.height - boxHeight)
            eventBox.layer.borderWidth = 8
        }

        boxFrame.size = CGSize(width: rect.width, height: boxHeight)
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

        for subview in supplementalView.subviews {
            subview.removeFromSuperview()
            
        }
        if isFirstOfYear {  // the supplemental view will be the year displayed
            yearBlur.frame = CGRect(x: 10, y: 10, width: supplementalFrame.width - 20, height: supplementalFrame.height - 20)
            supplementalView.addSubview(yearBlur)
            yearLabel.text = String(describing: year!)
            yearLabel.font = UIFont(name: "AvenirNext-Regular", size: 50)
            yearLabel.sizeToFit()
            yearLabel.textAlignment = .center
            yearLabel.frame = yearBlur.frame
            supplementalView.addSubview(yearLabel)
        } else {    // the supplemental view will be a stick
            var stickFrame = CGRect()
            stickFrame.size = CGSize(width: 5, height: rect.height - boxHeight)
            stickView.frame = stickFrame
            stickView.center.x = supplementalView.center.x
            supplementalView.addSubview(stickView)
            stickView.backgroundColor = color
        }

        if !isTitleScreenEventBox {
            textViewBlur.frame = subFrame
            eventBox.insertSubview(textViewBlur, at: 1)
            alreadyConstructed = true
        }

        eventBox.backgroundColor = UIColor.clear
        textView.backgroundColor = UIColor.clear
        textView.backgroundColor = UIColor.clear
       // supplementalView.backgroundColor = UIColor.clear
       // supplementalView.layer.zPosition = 100
        textView.text = stringVal

        eventBox.layer.borderColor = color.cgColor
        eventBox.center.x = self.center.x
        supplementalView.center.x = self.center.x

        eventBox.addSubview(textView)
        self.addSubview(eventBox)
        self.addSubview(supplementalView)
    }
}

