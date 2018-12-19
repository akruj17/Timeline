//
//  TimelineTitleEditorCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/5/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TimelineTitleEditorCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var titleLbl: UITextField!
    var timelineTitle: Timeline!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLbl.delegate = self
        titleLbl.layer.borderColor = UIColor.darkGray.cgColor
        titleLbl.layer.borderWidth = 2
        titleLbl.layer.cornerRadius = 5
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 1
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.layer.borderColor == UIColor.red.cgColor {
            textField.layer.borderColor = UIColor.darkGray.cgColor
            timelineTitle.editsRequired = false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let title = titleLbl.text {
            timelineTitle.name = title
        }
    }
    
    func configure(timeline: Timeline) {
        timelineTitle = timeline
        titleLbl.text? = timeline.name
        if timeline.editsRequired {
            titleLbl.layer.borderColor = UIColor.red.cgColor
        }
    }

    
}
