//
//  TitleScreenCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 12/2/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TitleScreenCell: UICollectionViewCell {
    
    @IBOutlet weak var titleBox: TitleScreenBox!
    
    func configure(isTopRow: Bool, title: String, color: UIColor, image: Data?) {
        titleBox.isTopRow = isTopRow
        titleBox.stringVal = title
        titleBox.color = color
        if let imageData = image {
            titleBox.image = UIImage(data: imageData)
        } else {
            titleBox.image = nil
        }
        
        titleBox.setNeedsDisplay()
    }
}
