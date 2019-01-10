//
//  PeriodCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/14/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class PeriodStickCell: UICollectionViewCell {
    @IBOutlet weak var periodStick: PeriodStick!
    
    func configure(isTopRow: Bool, color: UIColor, isBeginning: Bool) {
        periodStick.configure(isTop: isTopRow, color: color, isBeginning: isBeginning)
    }
    
}
