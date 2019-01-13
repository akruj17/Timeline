//
//  EventBox.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/2/19.
//  Copyright © 2019 Edumacation!. All rights reserved.
//

import UIKit

class EventBox: UIView {

    //VIEWS
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var eventBox: UIView!
    @IBOutlet weak var overviewField: UITextView!
    //either the stick or yearContainer + field must be present; ONLY ONE
    @IBOutlet weak var stick: UIView!
    @IBOutlet weak var yearContainer: UIView!
    @IBOutlet weak var yearField: UILabel!
    
    //CONSTRAINTS (EXACTLY ONE OF THE PAIRS MUST BE ACTIVE AT ONCE)
    //PAIR ONE - TOP EVENTS
    @IBOutlet weak var topConstraint1: NSLayoutConstraint!
    @IBOutlet weak var topConstraint2: NSLayoutConstraint!
    //PAIR TWO - BOTTOM EVENTS
    @IBOutlet weak var bottomConstraint1: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint2: NSLayoutConstraint!
    
    //DATA VARIABLES
    var top = false
    var yearValue: Int? = nil
    var _eventType: EventType = .REGULAR
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()

    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("EventBox", owner: self, options: nil)
        //some layout setup
        eventBox.layer.borderWidth = EVENT_BORDER
        eventBox.layer.borderColor = UIColor.darkGray.cgColor
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configure(isTop: Bool, year: Int?, overview: String, color: UIColor, eventType: EventType) {
        self.isTop = isTop
        self._eventType = eventType
        self.year = year
        self.overviewField.text = overview
        self.tintColor = color
    }
    
//GET-SET VARIABLES
    override var tintColor: UIColor? {
        get {
            return super.tintColor
        } set (v) {
            super.tintColor = v
            stick.backgroundColor = v
            eventBox.layer.borderColor = v!.cgColor
        }
    }
    
    var year: Int? {
        get {
            return yearValue
        } set (v) {
            yearValue = v
            if v == nil {
                //this is not the first event of the year
                yearContainer.isHidden = _eventType == .REGULAR
                stick.isHidden = _eventType != .REGULAR
                if _eventType != .REGULAR {
                    yearField.text = _eventType == .BEGIN ? "BEGAN" : "ENDED"
                }
            } else {
                //this is the first event of the year, show the year
                yearField.text = "\(v!)"
                if _eventType != .REGULAR {
                    yearField.text! += (_eventType == .BEGIN) ? "- BEGAN" : "- ENDED"
                }
                yearContainer.isHidden = false
                stick.isHidden = true
            }
        }
    }
    
    var isTop : Bool {
        get {
            return top
        } set (v) {
            top = v
            if v {
                addConstraints([topConstraint1, topConstraint2])
                removeConstraints([bottomConstraint1, bottomConstraint2])
            } else {
                removeConstraints([topConstraint1, topConstraint2])
                addConstraints([bottomConstraint1, bottomConstraint2])
            }
        }
    }
}
