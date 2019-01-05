////
////  EventDetailedVC.swift
////  Timeline
////
////  Created by Arjun Kunjilwar on 10/7/17.
////  Copyright © 2017 Edumacation!. All rights reserved.
////
//
//import UIKit
//
//protocol EventDetailedDelegate: class {
//    func removeContainerView()
//    func updateEvent(event: Event?, index: Int)
//}
//
//class EventDetailedVC: UIViewController, UITextViewDelegate, UITextFieldDelegate {
//
//    @IBOutlet weak var containerMinusBlur: UIView!
//    //TEXT FIELDS
//    @IBOutlet weak var yearField: UITextField!
//    @IBOutlet weak var eventOverviewField: UITextField!
//    @IBOutlet weak var detailedTextView: UITextView!
//    //DATA CONTAINERS (need to color their borders)
//    @IBOutlet weak var overviewContainer: UIView!
//    @IBOutlet weak var detailedContainer: UIView!
//    //STICKS THAT NEED TO BE COLORED
//    @IBOutlet weak var stick1: UIView!
//    @IBOutlet weak var stick2: UIView!
//    @IBOutlet weak var stick3: UIView!
//    @IBOutlet weak var stick4: UIView!
//    @IBOutlet weak var stick5: UIView!
//    //STICK CONSTRAINT FOR YEAR
//    @IBOutlet weak var stickConstraint: NSLayoutConstraint!
//    
//    //EVENT INFO
//    var eventsLayout: [TimeObject]!
//    var currEvent: TimeObject!
//    //FOR SAVING UPDATED DATA
//    var realmOperator: RealmOperator!
//    var doneEditing = false
//    
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        //some layout setup
//        containerMinusBlur.layer.borderColor = UIColor.lightGray.cgColor
//        containerMinusBlur.layer.borderWidth = TEXT_FIELD_BORDER
//        containerMinusBlur.layer.cornerRadius = TEXT_FIELD_RADIUS
//        overviewContainer.layer.borderWidth = TEXT_FIELD_BORDER
//        overviewContainer.layer.cornerRadius = TEXT_FIELD_RADIUS
//        detailedContainer.layer.borderWidth = TEXT_FIELD_BORDER
//        detailedContainer.layer.cornerRadius = TEXT_FIELD_RADIUS
//        ////////////////////////////////////////
//        //these variables should be passed in, so make sure they exist
//        assert(realmOperator != nil)
//        assert(eventsLayout != nil && eventsLayout.count > 0)
//    }
//
//    func updateAppearance(event: Event, color: UIColor, yearPercentage: CGFloat, index: Int) {
//        yearField.text = String(event.startYear.value!)
//        eventOverviewField.text = event.overview
//        detailedTextView.text = event.detailed
//        currEvent = event
//        currIndex = index
//        
//        stick1.backgroundColor = color
//        stick2.backgroundColor = color
//        stick3.backgroundColor = color
//        stick4.backgroundColor = color
//        stick5.backgroundColor = color
//        
//        overviewContainer.layer.borderColor = color.cgColor
//        detailedContainer.layer.borderColor = color.cgColor
//        
//        let yearLineLength = stick1.frame.height
//        stickConstraint.constant = yearLineLength * yearPercentage
//        stick2.setNeedsLayout()
//        yearField.setNeedsLayout()
//        stick2.superview?.setNeedsLayout()
//        stick2.superview?.layoutIfNeeded()
//    }
//    
////    @IBAction func donePressed(_ sender: Any) {
////        // perform validation
////        self.view.endEditing(true)
////        if yearField.text!.isEmpty || eventOverviewField.text!.isEmpty {
////            let incompleteAlert = UIAlertController(title: "Incomplete", message: nil, preferredStyle: .alert)
////            incompleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
////            incompleteAlert.title = "The event must have a year and overview."
////            self.present(incompleteAlert, animated: true, completion: nil)
////        } else {
////            if Int(yearField.text!) != currEvent.startYear.value! || eventOverviewField.text != currEvent.overview || detailedTextView.text != currEvent.detailed { // event is valid and may need to be resaved
////                currEvent.startYear.value = Int(yearField.text!)!
////                currEvent.overview = eventOverviewField.text!
////                currEvent.detailed = detailedTextView.text
////                RealmOperator.saveToDatabase(event: currEvent)
////                delegate?.updateEvent(event: currEvent, index: currIndex)
////            }
////            delegate?.removeContainerView()
////        }
////    }
//    
////////TEXT FIELD DELEGATE METHODS
//    func textViewDidBeginEditing(_ textView: UITextView) {
//        if textView.textColor == UIColor.lightGray {
//            // the placeholder text should be removed
//            textView.text = nil
//            textView.textColor = UIColor.black
//        }
//    }
//    
//    func textViewDidEndEditing(_ textView: UITextView) {
//        //only text view is detailed field
//        if textView.text.replacingOccurrences(of: " ", with: "") == "" {
//            // a field was left empty
//            textView.text = EVENT_DETAILED_PLACEHOLDER
//            textView.textColor = UIColor.lightGray
//        }
//        realmOperator.persistEventField(event: currEvent.event, field: textView.text, type: EventInfo.DETAILED, sync: doneEditing)
//    }
//    
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        if  let text = textField.text {
//            if textField == yearField {
//                if currEvent.isEndYear {
//                    realmOperator.persistEventField(event: currEvent.event, field: Int(text), type: EventInfo.END_YEAR, sync: doneEditing)
//                } else {
//                    realmOperator.persistEventField(event: currEvent.event, field: Int(text), type: EventInfo.START_YEAR, sync: doneEditing)
//                }
//            } else {
//                //field is overview field
//                realmOperator.persistEventField(event: currEvent.event, field: textField.text!, type: EventInfo.OVERVIEW, sync: doneEditing)
//            }
//        }
//    }
//    
//    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if textField == eventOverviewField {
//            // make sure overview field does not extend past 70 characters
//            guard let box = textField.text else { return true }
//            let newLength = box.count + string.count - range.length
//            return newLength <= 70
//        } else if textField == yearField {
//            // make sure year field is numeric positive or negative integers
//            var result = true
//            var disallowedCharacterSet: CharacterSet
//            if let input = textField.text {
//                if input.count != 0 {
//                    disallowedCharacterSet = NSCharacterSet(charactersIn: "0123456789").inverted
//                } else {
//                    disallowedCharacterSet = NSCharacterSet(charactersIn: "-0123456789").inverted
//                }
//            } else {
//                disallowedCharacterSet = NSCharacterSet(charactersIn: "-0123456789").inverted
//            }
//            if string.count > 0 {
//                let replacementStringIsLegal = string.rangeOfCharacter(from: disallowedCharacterSet) == nil
//                result = replacementStringIsLegal
//            }
//            if result {
//                guard let box = textField.text else {return true}
//                let newLength = box.count + string.count - range.length
//                result = newLength <= 5
//            }
//            return result
//        }
//        return true
//    }
//}
