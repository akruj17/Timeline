//
//  PeriodEventBox.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/14/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class PeriodEventBox: UIView {

    var eventBox: UIView
    var textView: UITextView
    var supplementalView: UIView
    var stickView: UIView
    var arrowContainer: Arrow
    var textViewBlur: UIVisualEffectView
    var timeBlur: UIVisualEffectView
    var timeLabel: UILabel
    
    let colorConstant: CGFloat = 100
    var alreadyConstructed: Bool = false
    
    var isTopRow: Bool = false
    var isFirstOfYear: Bool = false
    var isBeginning: Bool = false
    var stringVal: String = ""
    var year: Int?
    var color: UIColor = UIColor()
    
    required init?(coder aDecoder: NSCoder) {
        eventBox = UIView()
        textView = UITextView()
        supplementalView = UIView()
        stickView = UIView()
        arrowContainer = Arrow()
        textViewBlur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        timeBlur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        timeLabel = UILabel()
        
        
        super.init(coder: aDecoder)
        textView.isEditable = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.textAlignment = .center
    }
    
    override func draw(_ rect: CGRect) {
        var boxFrame = CGRect()
        var timeFrame = CGRect()
        var subFrame = CGRect()
        var supplementalFrame  = CGRect()
        let boxHeight: CGFloat = 0.2 * collectionHeight
        let timeLblHeight: CGFloat = 0.1 * collectionHeight
        
        textView.font = UIFont(name: "AvenirNext-Regular", size: 30)
        supplementalFrame.size = CGSize(width: rect.width, height: rect.height - boxHeight - timeLblHeight)
        eventBox.layer.borderWidth = 8
        
        boxFrame.size = CGSize(width: rect.width, height: boxHeight)
        timeFrame.size = CGSize(width: rect.width, height: timeLblHeight)
        
        if isTopRow {
            timeFrame.origin = CGPoint(x: 0, y: 0)
            boxFrame.origin = CGPoint(x: 0, y: timeFrame.height)
            supplementalFrame.origin = CGPoint(x: 0, y: boxHeight + timeLblHeight)
        }
        else {
            timeFrame.origin = CGPoint(x: 0, y: rect.size.height - timeLblHeight)
            boxFrame.origin = CGPoint(x: 0, y: rect.size.height - boxHeight - timeLblHeight)
            supplementalFrame.origin = CGPoint(x: 0, y: 0)
        }
        eventBox.frame = boxFrame
        timeLabel.frame = timeFrame
        supplementalView.frame = supplementalFrame
        subFrame = boxFrame
        subFrame.origin = CGPoint(x: 0, y: 0)
        textView.frame = subFrame
        
        for subview in supplementalView.subviews {
            subview.removeFromSuperview()
            
        }
        
        arrowContainer.frame.size = CGSize(width: 0.5 * rect.width, height: 0.05 * rect.height)
        
        if !isBeginning {
            arrowContainer.transform = CGAffineTransform(rotationAngle: .pi)
        }
        arrowContainer.frame.origin.x = isBeginning ? supplementalView.center.x : 0
        arrowContainer.backgroundColor = UIColor.clear
        arrowContainer.frame.origin.y = isTopRow    ? supplementalView.frame.height - arrowContainer.frame.height : 0
        arrowContainer.color = color
        supplementalView.addSubview(arrowContainer)
        
        timeBlur.frame = timeFrame
        self.addSubview(timeBlur)
        timeLabel.text = (isBeginning ? "BEGAN" : "ENDED") + " - " + "\(abs(year!))" + ((year! < 0) ? " BCE" : "")
        timeLabel.font = UIFont(name: "AvenirNext-Regular", size: 50)
        timeLabel.sizeToFit()
        timeLabel.textAlignment = .center
        timeLabel.center.x = supplementalView.center.x
        
            var stickFrame = CGRect()
            stickFrame.size = CGSize(width: PERIOD_CELL_BORDER, height: rect.height - boxHeight - timeLblHeight - ((arrowContainer.frame.height - PERIOD_CELL_BORDER) / 2))
            stickFrame.origin.y = isTopRow ? 0 : (supplementalFrame.height - stickFrame.height)
            stickView.frame = stickFrame
            stickView.center.x = supplementalView.center.x
            supplementalView.addSubview(stickView)
            stickView.backgroundColor = color
//        }
        
        textViewBlur.frame = subFrame
        eventBox.insertSubview(textViewBlur, at: 1)
        alreadyConstructed = true
        
        eventBox.backgroundColor = UIColor.clear
        textView.backgroundColor = UIColor.clear
        textView.backgroundColor = UIColor.clear
        // supplementalView.backgroundColor = UIColor.clear
        // supplementalView.layer.zPosition = 100
        textView.text = stringVal
        
        eventBox.layer.borderColor = color.cgColor
        eventBox.center.x = self.center.x
        supplementalView.center.x = self.center.x
        
        eventBox.layer.cornerRadius = 10

        eventBox.addSubview(textView)
        self.addSubview(timeLabel)
        self.addSubview(eventBox)
        self.addSubview(supplementalView)
    }

}
