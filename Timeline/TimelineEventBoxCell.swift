//
//  TimelineEventBoxCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 6/27/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TimelineEventBoxCell: UICollectionViewCell {
    
    @IBOutlet weak var timelineBox: TimelineEventBox!
    
    func configure(isTopRow: Bool, title: String, color: UIColor, year: Int? = nil, isTitleScreenEventBox: Bool) {
        timelineBox.isTopRow = isTopRow
        timelineBox.isTitleScreenEventBox = isTitleScreenEventBox
        
        timelineBox.stringVal = title
        timelineBox.color = color
        
        if let firstYear = year {
            timelineBox.isFirstOfYear = true
            timelineBox.year = firstYear
        }
        
        timelineBox.setNeedsDisplay()
    }
    
}
