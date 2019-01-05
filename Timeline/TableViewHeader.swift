//
//  TableViewHeader.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/14/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class TableViewHeader: UITableViewCell {

    @IBOutlet weak var sectionTitle: UILabel!
    @IBOutlet weak var arrowLbl: UILabel!
    
    var isCollapsed: Bool = false
    var index: Int!
    var toggleDelegate: ToggleTableDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        // Initialization code
    }
    
    func setAppearance(index: Int, title: String, collapsed: Bool) {
        sectionTitle.text = title
        self.index = index
        isCollapsed = collapsed
        arrowLbl.rotate(isCollapsed ? 0.0 : .pi)
        arrowLbl.setNeedsDisplay()
    }

    @objc func didTap(gestureRecognizer: UIGestureRecognizer) {
        isCollapsed = !isCollapsed
        arrowLbl.rotate(isCollapsed ? 0.0 : .pi)
        arrowLbl.setNeedsDisplay()
        arrowLbl.setNeedsLayout()
        arrowLbl.layoutIfNeeded()

        toggleDelegate.updateSectionAppearance(index: index, isCollapsed: isCollapsed)

        
        // Configure the view for the selected state
    }
    
}

extension UIView {
    func rotate(_ toValue: CGFloat, duration: CFTimeInterval = 0.2) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.toValue = toValue
        animation.duration = duration
        animation.isRemovedOnCompletion = true
        animation.fillMode = CAMediaTimingFillMode.forwards
        self.layer.add(animation, forKey: nil)
    }
}

protocol ToggleTableDelegate {
    func updateSectionAppearance(index: Int, isCollapsed: Bool)
}
