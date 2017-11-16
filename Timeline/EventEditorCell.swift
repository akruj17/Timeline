//
//  EventEditorCellTableViewCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/2/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

protocol CellDelegate {
    func modifyUI(index: Int)
}

class EventEditorCell: UITableViewCell, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var yearField: UITextField!
    @IBOutlet weak var eventIndexLbl: UILabel!
    @IBOutlet weak var eventOverviewField: UITextView!
    @IBOutlet weak var eventDetailedField: UITextView!
    @IBOutlet weak var isBCE: UISwitch!
    @IBAction func switchChanged(_ sender: UISwitch) {
        event.isBCE = sender.isOn
    }
    
    var eventIndex: Int!
    var event: Event!
    let eventOverviewPlaceholder = "Enter a brief description of the event which will show up on the timeline. 70 chars max"
    let eventDetailedPlaceholder = "Enter a more detailed description of the event (Optional)"
    var delegate: CellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        eventOverviewField.delegate = self
        eventDetailedField.delegate = self
        yearField.delegate = self
        eventOverviewField.layer.borderWidth = 2
        eventOverviewField.layer.cornerRadius = 5
        eventDetailedField.layer.borderWidth = 2
        eventDetailedField.layer.cornerRadius = 5
        yearField.layer.borderWidth = 2
        yearField.layer.cornerRadius = 5
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        if textView.layer.borderColor == UIColor.red.cgColor {
            textView.layer.borderColor = UIColor.darkGray.cgColor
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.layer.borderColor == UIColor.red.cgColor {
            textField.layer.borderColor = UIColor.darkGray.cgColor
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty || (textView.text.replacingOccurrences(of: " ", with: "") == "") {
            if textView == eventOverviewField {
                textView.text = eventOverviewPlaceholder
                event.overview = ""
            } else if textView == eventDetailedField {
                textView.text = eventDetailedPlaceholder
                event.detailed = ""
            }
            textView.textColor = UIColor.lightGray
        } else {
            if textView == eventOverviewField {
                event.overview = textView.text
                event.editsRequired.updateValue(false, forKey: "overview")
            } else if textView == eventDetailedField {
                event.detailed = textView.text
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if  let text = textField.text {
            if text.isEmpty {
                event.year.value = nil
            } else {
                event.year.value = Int(text)
                event.editsRequired.updateValue(false, forKey: "year")
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == eventOverviewField {
            guard let box = textView.text else { return true }
            let newLength = box.characters.count + text.characters.count - range.length
            return newLength <= 70
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var result = true
        
        if string.characters.count > 0 {
            let disallowedCharacterSet = NSCharacterSet(charactersIn: "0123456789").inverted
            let replacementStringIsLegal = string.rangeOfCharacter(from: disallowedCharacterSet) == nil
            result = replacementStringIsLegal
            }
        if result {
            guard let box = textField.text else {return true}
            let newLength = box.characters.count + string.characters.count - range.length
            result = newLength <= 4
        }
    
        return result

    }
    
    func configure(index: Int, eventInfo: Event) {
        eventIndexLbl.text = "\(index)."
        eventIndex = index - 1
        event = eventInfo
        
        if !(event.year.value == nil) {
            yearField.text = String(event.year.value!)
        } else {
            yearField.text = ""
        }
        if !event.overview.isEmpty {
            eventOverviewField.text = event.overview
            eventOverviewField.textColor = UIColor.black
        } else {
            eventOverviewField.text = eventOverviewPlaceholder
            eventOverviewField.textColor = UIColor.lightGray
        }
        if !event.detailed.isEmpty {
            eventDetailedField.text = event.detailed
            eventDetailedField.textColor = UIColor.black
        } else {
            eventDetailedField.text = eventDetailedPlaceholder
            eventDetailedField.textColor = UIColor.lightGray
        }
        if !event.isBCE {
            isBCE.setOn(false, animated: false)
        }
        else {
            isBCE.setOn(true, animated: false)
        }
        
        if event.editsRequired["year"]! {
            yearField.layer.borderColor = UIColor.red.cgColor
        }
        else {
            yearField.layer.borderColor = UIColor.darkGray.cgColor
        }
        if event.editsRequired["overview"]! {
            eventOverviewField.layer.borderColor = UIColor.red.cgColor
        }
        else {
            eventOverviewField.layer.borderColor = UIColor.darkGray.cgColor
        }
        
    }
    

    override func layoutSubviews() {
        super.layoutSubviews()
        let f = contentView.frame
        let fr = UIEdgeInsetsInsetRect(f, UIEdgeInsetsMake(10, 10, 10, 10))
        contentView.frame = fr
        contentView.layer.shadowOpacity = 1.0
        contentView.layer.shadowRadius = 1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowColor = UIColor.lightGray.cgColor
    }
    
}


