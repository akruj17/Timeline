//
//  PeriodBox.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/2/19.
//  Copyright © 2019 Edumacation!. All rights reserved.
//

import UIKit

class PeriodBox: UIView {

    //VIEWS
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var infoStackView: UIStackView!
    @IBOutlet weak var eventBox: UIView!
    @IBOutlet weak var overviewField: UITextView!
    @IBOutlet weak var yearContainer: UIView!
    @IBOutlet weak var yearField: UILabel!
    @IBOutlet weak var arrowContainer: UIView!
    @IBOutlet weak var arrowStackView: UIStackView!
    @IBOutlet weak var arrowSubStack: UIStackView!
    @IBOutlet weak var stickResidualStack: UIStackView!
    @IBOutlet weak var residualView: UIView!
    @IBOutlet weak var stickResidual: UIView!
    @IBOutlet weak var arrow: Arrow!
    @IBOutlet weak var stick: UIView!
    @IBOutlet weak var nonArrowView: UIView!
    
    //DATA VARIABLES
    var top = false
    var yearValue: Int? = nil
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
        Bundle.main.loadNibNamed("PeriodTestBox", owner: self, options: nil)
        //some layout setup
        eventBox.layer.borderWidth = EVENT_BORDER
        eventBox.layer.borderColor = UIColor.darkGray.cgColor
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configure(isTop: Bool, color: UIColor, overview: String, year: Int?, isBeginning: Bool) {
        self.isTop = isTop
        self.tintColor = color
        overviewField.text = overview
        self.isBeginning = isBeginning
        self.year = year
    }
    
//GET-SET VARIABLES
    override var tintColor: UIColor? {
        get {
            return super.tintColor
        } set (v) {
            super.tintColor = v
            stick.backgroundColor = v
            stickResidual.backgroundColor = v
            arrow.tintColor = v
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
                yearField.text = (beginning) ? "BEGAN" : "ENDED"
            } else {
                //this is the first event of the year, show the year
                yearField.text = "\(v!) - \((beginning ? "BEGAN" : "ENDED"))"
            }
        }
    }
//
    var isTop : Bool {
        get {
            return top
        } set (v) {
            top = v
            if v {
                stackView.insertArrangedSubview(infoStackView, at: 0)
                stackView.insertArrangedSubview(arrowStackView, at: 2)
                infoStackView.insertArrangedSubview(eventBox, at: 0)
                arrowStackView.insertArrangedSubview(arrowContainer, at: 2)
                arrowStackView.insertArrangedSubview(nonArrowView, at: 0)
                stickResidualStack.insertArrangedSubview(residualView, at: 0)
            } else {
                stackView.insertArrangedSubview(arrowStackView, at: 0)
                stackView.insertArrangedSubview(infoStackView, at: 2)
                infoStackView.insertArrangedSubview(yearContainer, at: 0)
                arrowStackView.insertArrangedSubview(arrowContainer, at: 0)
                arrowStackView.insertArrangedSubview(nonArrowView, at: 2)
                stickResidualStack.insertArrangedSubview(residualView, at: 1)
            }
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
