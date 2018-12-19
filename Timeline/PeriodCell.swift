//
//  PeriodCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/14/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class PeriodCell: UICollectionViewCell {
    @IBOutlet weak var periodBox: PeriodEventBox!
    
    func configure(isTopRow: Bool, title: String, color: UIColor, year: Int? = nil, isBeginning: Bool) {
        periodBox.isTopRow = isTopRow
        periodBox.isBeginning = isBeginning
        periodBox.stringVal = title
        periodBox.color = color
        
        if let firstYear = year {
            periodBox.isFirstOfYear = true
            periodBox.year = firstYear
        } else {
            periodBox.isFirstOfYear = false
            periodBox.year = nil
        }
        
        periodBox.setNeedsDisplay()
    }
    
}
