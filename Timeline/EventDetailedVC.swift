//
//  EventDetailedVC.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 10/7/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class EventDetailedVC: UIViewController {

    @IBOutlet weak var yearLbl: UILabel!
    @IBOutlet weak var overviewLbl: UILabel!
    @IBOutlet weak var detailedTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func updateEventFields(event: Event) {
        yearLbl.text = String(event.year.value!)
        overviewLbl.text? = event.overview
        detailedTextView.text = event.detailed
    }
    
    @IBAction func donePressed(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
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
