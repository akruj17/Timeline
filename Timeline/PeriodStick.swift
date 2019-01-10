//
//  PeriodStick.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/8/19.
//  Copyright © 2019 Edumacation!. All rights reserved.
//

import UIKit

class PeriodStick: UIView {
    
    //VIEWS
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var arrowContainer: UIView!
    @IBOutlet weak var arrowStackView: UIStackView!
    @IBOutlet weak var arrowSubStack: UIStackView!
    @IBOutlet weak var arrow: Arrow!
    @IBOutlet weak var stick: UIView!
    @IBOutlet weak var nonArrowView: UIView!
    
    //DATA VARIABLES
    var top = false
    var beginning: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("PeriodStick", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configure(isTop: Bool, color: UIColor, isBeginning: Bool) {
        self.isTop = isTop
        self.tintColor = color
        self.isBeginning = isBeginning
    }
    
    //GET-SET VARIABLES
    override var tintColor: UIColor? {
        get {
            return super.tintColor
        } set (v) {
            super.tintColor = v
            stick.backgroundColor = v
            arrow.tintColor = v
        }
    }
    
    var isTop : Bool {
        get {
            return top
        } set (v) {
            top = v
            if !v {
                arrowStackView.insertArrangedSubview(arrowContainer, at: 2)
                arrowStackView.insertArrangedSubview(nonArrowView, at: 0)
            } else {
                arrowStackView.insertArrangedSubview(arrowContainer, at: 0)
                arrowStackView.insertArrangedSubview(nonArrowView, at: 2)
            }
            arrow.isTop = top
        }
    }
    
    var isBeginning : Bool {
        get {
            return beginning
        } set (v) {
            beginning = v
            if v {
                arrowSubStack.insertArrangedSubview(arrow, at: 1)
                arrow.pointsRight = true
            } else {
                arrowSubStack.insertArrangedSubview(arrow, at: 0)
                arrow.pointsRight = false
            }
        }
    }
}
