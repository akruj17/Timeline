//
//  TimelineEventBoxCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 6/27/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TimelineEventBoxCell: UICollectionViewCell {
    
    @IBOutlet weak var eventBox: EventBox!
    
    func configure(isTopRow: Bool, overview: String, color: UIColor, year: Int?, eventType: EventType) {
        eventBox.configure(isTop: isTopRow, year: year, overview: overview, color: color, eventType: eventType)
    }
    
}
