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
}

class EventDetailedVC: UIViewController {

    @IBOutlet weak var yearLbl: UILabel!
    @IBOutlet weak var overviewLbl: UILabel!
    @IBOutlet weak var detailedTextView: UITextView!
    @IBOutlet weak var stick1: UIView!
    @IBOutlet weak var stick2: UIView!
    @IBOutlet weak var stick3: UIView!
    @IBOutlet weak var stick4: UIView!
    @IBOutlet weak var stick5: UIView!
    @IBOutlet weak var overviewContainer: UIView!
    @IBOutlet weak var detailedContainer: UIView!
    
    weak var delegate: EventDetailedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overviewContainer.layer.borderWidth = 2
        overviewContainer.layer.cornerRadius = 4
        detailedContainer.layer.borderWidth = 2
        detailedContainer.layer.cornerRadius = 4

        // Do any additional setup after loading the view.
    }

    func updateAppearance(event: Event, color: UIColor) {
        yearLbl.text = String(event.year.value!)
        overviewLbl.text? = event.overview
        detailedTextView.text = event.detailed
        
        stick1.backgroundColor = color
        stick2.backgroundColor = color
        stick3.backgroundColor = color
        stick4.backgroundColor = color
        stick5.backgroundColor = color
        
        overviewContainer.layer.borderColor = color.cgColor
        detailedContainer.layer.borderColor = color.cgColor
    }
    
    @IBAction func donePressed(_ sender: Any) {
        delegate?.removeContainerView()
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
