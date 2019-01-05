//
//  EventDetailedView.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 12/30/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class EventDetailedView: UIView, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var containerMinusBlur: UIView!
    //TEXT FIELDS
    @IBOutlet weak var yearField: UITextField!
    @IBOutlet weak var eventOverviewField: UITextField!
    @IBOutlet weak var detailedTextView: UITextView!
    //DATA CONTAINERS (need to color their borders)
    @IBOutlet weak var overviewContainer: UIView!
    @IBOutlet weak var detailedContainer: UIView!
    //STICKS THAT NEED TO BE COLORED
    @IBOutlet weak var stick1: UIView!
    @IBOutlet weak var stick2: UIView!
    @IBOutlet weak var stick3: UIView!
    @IBOutlet weak var stick4: UIView!
    @IBOutlet weak var stick5: UIView!
    //STICK CONSTRAINT FOR YEAR
    @IBOutlet weak var stickConstraint: NSLayoutConstraint!
    
    //INFO FOR CALCULATING YEAR FRACTION
    private var yearVal: Int = 0
    private var firstYear: Int = 0
    private var lastYear: Int = 0
    private var secondYear: Int? = nil
    private var secondLastYear: Int? = nil
    var layoutIndex: Int = -1
    //FOR SAVING UPDATED DATA
    var delegate : EditorDataSaveDelegate!
    //COMPLETION HANDLER
    var completion : ((String, String, UIView) -> ())!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("EventDetailedView", owner: self, options: nil)
        //some layout setup
        containerMinusBlur.layer.borderColor = UIColor.lightGray.cgColor
        containerMinusBlur.layer.borderWidth = TEXT_FIELD_BORDER
        containerMinusBlur.layer.cornerRadius = TEXT_FIELD_RADIUS
        overviewContainer.layer.borderWidth = TEXT_FIELD_BORDER
        overviewContainer.layer.cornerRadius = TEXT_FIELD_RADIUS
        detailedContainer.layer.borderWidth = TEXT_FIELD_BORDER
        detailedContainer.layer.cornerRadius = TEXT_FIELD_RADIUS
        yearField.delegate = self
        eventOverviewField.delegate = self
        detailedTextView.delegate = self
        ////////////////////////////////////////
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configure(index: Int, timeObject: TimeObject, first: Int, last: Int, second: Int?, secondLast: Int?) {
        eventOverviewField.text = timeObject.event.overview
        if timeObject.event.detailed.replacingOccurrences(of: " ", with: "") == "" {
            detailedTextView.text = EVENT_DETAILED_PLACEHOLDER
            detailedTextView.textColor = UIColor.lightGray
        } else {
            detailedTextView.text = timeObject.event.detailed
        }
        layoutIndex = index
        //LOCK THESE YEARS DOWN AND THEN UPDATE THE ACTUAL YEAR
        firstYear = first
        lastYear = last
        secondYear = second
        secondLastYear = secondLast
        //////////////////
        year = timeObject.year
    }

    @IBAction func donePressed(_ sender: Any) {
        assert(completion != nil)
        completion(yearField.text!, eventOverviewField.text!, self)
    }
    
    
//////OVERRIDEN VARIABLES
    override var tintColor: UIColor? {
        get {
            return super.tintColor
        }
        set(v) {
            super.tintColor = v
            if stick1 != nil {
                //all sticks are laid out
                stick1.backgroundColor = v
                stick2.backgroundColor = v
                stick3.backgroundColor = v
                stick4.backgroundColor = v
                stick5.backgroundColor = v
                //update container border colors
                containerMinusBlur.layer.borderColor = v!.cgColor
                overviewContainer.layer.borderColor = v!.cgColor
                detailedContainer.layer.borderColor = v!.cgColor
            }
        }
    }
    
    var year: Int {
        get {
            return yearVal
        } set (v) {
            // kind of recursive
            if v >= firstYear && v <= lastYear {
                //year is within current range, no additional calculations required
                stickConstraint.constant = (lastYear - firstYear) == 0 ? 0 : stick1.frame.height * (CGFloat(v - firstYear) / CGFloat(lastYear - firstYear))
                yearField.text = "\(v)"
            } else {
                if layoutIndex == 0 {
                    //moving the first event
                    if secondYear == nil {
                        //VERY SPECIAL CASE, ONLY ONE EVENT IN THE TIMELINE
                        firstYear = v
                        lastYear = v
                    } else if v < secondYear! {
                        //no changes required just change the year
                        firstYear = v
                    } else {
                        firstYear = secondYear!
                        if v > lastYear {
                            lastYear = v
                        }
                    }
                } else if secondLastYear != nil {
                    //moving the last event
                    if v > secondLastYear! {
                        //no changes required just change the year
                        lastYear = v
                    } else {
                        lastYear = secondLastYear!
                        if v < firstYear {
                            firstYear = v
                        }
                    }
                } else {
                    //moving a middle year to an extremė
                    if v < firstYear {
                        firstYear = v
                    } else {
                        lastYear = v
                    }
                }
                self.year = v
            }
            yearVal = v
        }
    }
    
    
//////TEXT FIELD DELEGATE METHODS
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            // the placeholder text should be removed
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        //only text view is detailed field
        delegate.saveDetailed(detailed: textView.text, index: layoutIndex)
        if textView.text.replacingOccurrences(of: " ", with: "") == "" {
            // a field was left empty
            textView.text = EVENT_DETAILED_PLACEHOLDER
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if  let text = textField.text {
            if textField == yearField {
                delegate.saveEndYear(year: Int(text), index: layoutIndex)
                year = Int(text)!
            } else {
                //field is overview field
                delegate.saveOverview(overview: text, index: layoutIndex)
                if text.replacingOccurrences(of: " ", with: "") == "" {
                    textField.text = "" //set back the placeholder
                }
            }
        }
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == eventOverviewField {
            // make sure overview field does not extend past 70 characters
            guard let box = textField.text else { return true }
            let newLength = box.count + string.count - range.length
            return newLength <= 70
        } else if textField == yearField {
            // make sure year field is numeric positive or negative integers
            var result = true
            var disallowedCharacterSet: CharacterSet
            if let input = textField.text {
                if input.count != 0 {
                    disallowedCharacterSet = NSCharacterSet(charactersIn: "0123456789").inverted
                } else {
                    disallowedCharacterSet = NSCharacterSet(charactersIn: "-0123456789").inverted
                }
            } else {
                disallowedCharacterSet = NSCharacterSet(charactersIn: "-0123456789").inverted
            }
            if string.count > 0 {
                let replacementStringIsLegal = string.rangeOfCharacter(from: disallowedCharacterSet) == nil
                result = replacementStringIsLegal
            }
            if result {
                guard let box = textField.text else {return true}
                let newLength = box.count + string.count - range.length
                result = newLength <= 5
            }
            return result
        }
        return true
    }
    
    
    
}
