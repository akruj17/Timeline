//
//  PeriodCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/14/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class PeriodCell: UICollectionViewCell {
    @IBOutlet weak var periodBox: PeriodBox!
    
    func configure(isTopRow: Bool, overview: String, color: UIColor, year: Int?, isBeginning: Bool) {
        periodBox.configure(isTop: isTopRow, color: color, overview: overview, year: year, isBeginning: isBeginning)
    }
    
}
