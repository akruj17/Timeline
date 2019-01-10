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
    weak var delegate : EditorDataSaveDelegate!
    
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
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let title = titleLbl.text {
            delegate.saveTitle(title: title)
            if  title.replacingOccurrences(of: " ", with: "") == "" {
                // the title is invalid. Empty or consisting of solely spaces
                // mark the field as incomplete
                textField.layer.borderColor = UIColor.red.cgColor
            }
        }
    }
    
    func configure(timeline: Timeline, invalid: Bool) {
        titleLbl.text? = timeline.name
        titleLbl.layer.borderColor = invalid ? UIColor.red.cgColor : UIColor.darkGray.cgColor
    }
}
