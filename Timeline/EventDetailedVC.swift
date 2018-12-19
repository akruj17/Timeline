//
//  EventDetailedVC.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 10/7/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

protocol EventDetailedDelegate: class {
    func removeContainerView()
    func updateEvent(event: Event?, index: Int)
}

class EventDetailedVC: UIViewController {


    @IBOutlet weak var yearField: UITextField!
    @IBOutlet weak var eventOverviewField: UITextField!
    
    @IBOutlet weak var detailedTextView: UITextView!
    @IBOutlet weak var stick1: UIView!
    @IBOutlet weak var stick2: UIView!
    @IBOutlet weak var stick3: UIView!
    @IBOutlet weak var stick4: UIView!
    @IBOutlet weak var stick5: UIView!
    @IBOutlet weak var overviewContainer: UIView!
    @IBOutlet weak var detailedContainer: UIView!
    @IBOutlet weak var stickConstraint: NSLayoutConstraint!
    
    weak var delegate: EventDetailedDelegate?
    var currEvent: Event!
    var currIndex: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overviewContainer.layer.borderWidth = 2
        overviewContainer.layer.cornerRadius = 4
        detailedContainer.layer.borderWidth = 2
        detailedContainer.layer.cornerRadius = 4

        // Do any additional setup after loading the view.
    }

    func updateAppearance(event: Event, color: UIColor, yearPercentage: CGFloat, index: Int) {
        yearField.text = String(event.startYear.value!)
        eventOverviewField.text = event.overview
        detailedTextView.text = event.detailed
        currEvent = event
        currIndex = index
        
        stick1.backgroundColor = color
        stick2.backgroundColor = color
        stick3.backgroundColor = color
        stick4.backgroundColor = color
        stick5.backgroundColor = color
        
        overviewContainer.layer.borderColor = color.cgColor
        detailedContainer.layer.borderColor = color.cgColor
        
        let yearLineLength = stick1.frame.height
        let yearLineMin = stick1.frame.minY
        stickConstraint.constant = yearLineLength * yearPercentage
        stick2.setNeedsLayout()
        yearField.setNeedsLayout()
        stick2.superview?.setNeedsLayout()
        stick2.superview?.layoutIfNeeded()
    }
    
    @IBAction func donePressed(_ sender: Any) {
        // perform validation
        self.view.endEditing(true)
        if yearField.text!.isEmpty || eventOverviewField.text!.isEmpty {
            let incompleteAlert = UIAlertController(title: "Incomplete", message: nil, preferredStyle: .alert)
            incompleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            incompleteAlert.title = "The event must have a year and overview."
            self.present(incompleteAlert, animated: true, completion: nil)
        } else {
            if Int(yearField.text!) != currEvent.startYear.value! || eventOverviewField.text != currEvent.overview || detailedTextView.text != currEvent.detailed { // event is valid and may need to be resaved
                currEvent.startYear.value = Int(yearField.text!)
                currEvent.overview = eventOverviewField.text!
                currEvent.detailed = detailedTextView.text
                RealmOperator.saveToDatabase(event: currEvent)
                delegate?.updateEvent(event: currEvent, index: currIndex)
            }
            delegate?.removeContainerView()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
