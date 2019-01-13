//
//  TitleScreenCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 12/2/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TitleScreenCell: UICollectionViewCell {
    
    @IBOutlet weak var titleBox: TitleBox!
    
    func configure(isTopRow: Bool, title: String, isLoading: Bool) {
        titleBox.configure(title: title, isTop: isTopRow)
        titleBox.isLoading = isLoading
    }
    
    func setLoading(isLoading: Bool) {
        titleBox.isLoading = isLoading
    }
    
}
