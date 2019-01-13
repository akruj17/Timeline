//
//  EventEditorCellTableViewCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/2/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class EventEditorCell: UITableViewCell, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var startYearField: UITextField!
    @IBOutlet weak var endYearField: UITextField!
    @IBOutlet weak var eventIndexLbl: UILabel!
    @IBOutlet weak var eventOverviewField: UITextView!
    @IBOutlet weak var eventDetailedField: UITextView!
    @IBOutlet weak var isTimePeriod: UISwitch!
    @IBAction func switchChanged(_ sender: UISwitch) {
        delegate.saveTimePeriod(isTimePeriod: sender.isOn, index: eventIndex)
        showEndYearLabel(isTimePeriod: sender.isOn)
    }
    
    var eventIndex: Int!
    var delegate : EditorDataSaveDelegate!
    let eventOverviewPlaceholder = "Enter a brief description of the event which will show up on the timeline. 70 chars max"
    let eventDetailedPlaceholder = "Enter a more detailed description of the event (Optional)"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        eventOverviewField.delegate = self
        eventDetailedField.delegate = self
        startYearField.delegate = self
        endYearField.delegate = self
        eventOverviewField.layer.borderWidth = TEXT_FIELD_BORDER
        eventOverviewField.layer.cornerRadius = TEXT_FIELD_RADIUS
        eventDetailedField.layer.borderWidth = TEXT_FIELD_BORDER
        eventDetailedField.layer.cornerRadius = TEXT_FIELD_RADIUS
        startYearField.layer.borderWidth = TEXT_FIELD_BORDER
        endYearField.layer.borderWidth = TEXT_FIELD_BORDER
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate.setActiveTextField(textField: textView)
        if textView.textColor == UIColor.lightGray {
            // the placeholder text should be removed
            textView.text = nil
            textView.textColor = UIColor.black
        }
        if textView.layer.borderColor == UIColor.red.cgColor {
            // change red to gray borders when clicked
            textView.layer.borderColor = UIColor.darkGray.cgColor
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate.setActiveTextField(textField: textField)
        if textField.layer.borderColor == UIColor.red.cgColor {
            //change red to gray borders when clicked
            textField.layer.borderColor = UIColor.darkGray.cgColor
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // regardless, save the new value so the VC knows if this field is incomplete
        if textView == eventOverviewField {
            delegate.saveOverview(overview: textView.text, index: eventIndex)
        } else if textView == eventDetailedField {
            delegate.saveDetailed(detailed: textView.text, index: eventIndex)
        }
        if textView.text.replacingOccurrences(of: " ", with: "") == "" {
            // a field was left empty
            if textView == eventOverviewField {
                textView.text = eventOverviewPlaceholder
                // mark this field as incomplete
                textView.layer.borderColor = UIColor.red.cgColor
            } else if textView == eventDetailedField {
                textView.text = eventDetailedPlaceholder
            }
            textView.textColor = UIColor.lightGray
        }
    }

//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if(text == "\n") {
//            textView.resignFirstResponder()
//            return false
//        }
//        return true
//    }
//
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if  let text = textField.text {
            if textField == startYearField {
                if text.isEmpty {
                    //mark this field as incomplete
                    textField.layer.borderColor = UIColor.red.cgColor
                }
                // regardless, save the new value so the VC knows if this field is incomplete
                delegate.saveYear(year: Int(text), index: eventIndex)
            } else if isTimePeriod.isOn && textField == endYearField {
                if text.isEmpty {
                    //mark this field as incomplete
                    textField.layer.borderColor = UIColor.red.cgColor
                }
                // regardless, save the new value so the VC knows if this field is incomplete
                delegate.saveEndYear(year: Int(text), index: eventIndex)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        //or
        //self.view.endEditing(true)
        return true
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        if textView == eventOverviewField {
            guard let box = textView.text else { return true }
            let newLength = box.count + text.count - range.length
            return newLength <= 70
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
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
    
    func configure(index: Int, event: Event, invalid: [Bool]) {
        // the user wants 1 based indexing, but I dont!
        eventIndexLbl.text = "\(index)."
        eventIndex = index - 1
        // making sure year is filled
        startYearField.text = (event.startYear.value == nil) ? "" : String(event.startYear.value!)
        startYearField.layer.borderColor = invalid[START_YEAR_INDEX] ? UIColor.red.cgColor : UIColor.darkGray.cgColor
        // making sure end year is filled if appropriate
        if event.isTimePeriod {
            endYearField.text = (event.endYear.value == nil) ? "" : String(event.endYear.value!)
            endYearField.layer.borderColor = invalid[END_YEAR_INDEX] ? UIColor.red.cgColor : UIColor.darkGray.cgColor
        }
        //making sure overview is filled
        eventOverviewField.text = event.overview.isEmpty ? eventOverviewPlaceholder : event.overview
        eventOverviewField.textColor = event.overview.isEmpty ? UIColor.lightGray : UIColor.black
        eventOverviewField.layer.borderColor = invalid[OVERVIEW_INDEX] ? UIColor.red.cgColor : UIColor.darkGray.cgColor
        //making sure detailed is filled if appropriate
        eventDetailedField.text = event.detailed.isEmpty ? eventDetailedPlaceholder : event.detailed
        eventDetailedField.textColor = event.detailed.isEmpty ? UIColor.lightGray : UIColor.black
        //making sure time period switch is properly set
        isTimePeriod.setOn(event.isTimePeriod, animated: false)
        showEndYearLabel(isTimePeriod: event.isTimePeriod)
    }
    
    func showEndYearLabel(isTimePeriod: Bool) {
        endYearField.isHidden = !isTimePeriod
        startYearField.placeholder = isTimePeriod ? "Start Year" : "Event Year"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let f = contentView.frame
        let fr = f.inset(by: UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10))
        contentView.frame = fr
        contentView.layer.shadowOpacity = 1.0
        contentView.layer.shadowRadius = 1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowColor = UIColor.lightGray.cgColor
    }
    
}


