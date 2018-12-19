//
//  Arrow.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/17/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class Arrow: UIView {
    
    var color: UIColor!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let arrowStick = UIView(frame: CGRect(x: 0, y: (3 * frame.height / 8), width: frame.width, height: PERIOD_CELL_BORDER))
        // arrowHead will be at 30 degree angles to the stick
        let rotationAngle: CGFloat = .pi / 6
        let arrowHeadLength = ((rect.height - PERIOD_CELL_BORDER) / 2) / sin(rotationAngle)
        let arrowHeadTop = UIView(frame: CGRect(x: arrowStick.frame.maxX - (cos(rotationAngle) * (arrowHeadLength / 2)) - (arrowHeadLength / 2), y: arrowStick.frame.minY - ((arrowHeadLength / 2) * sin(rotationAngle)), width: arrowHeadLength, height: PERIOD_CELL_BORDER))
        let arrowHeadBottom = UIView(frame: CGRect(x: arrowStick.frame.width - (cos(-1 * rotationAngle) * (arrowHeadLength / 2)) - (arrowHeadLength / 2), y: arrowStick.frame.minY + (sin(rotationAngle) * (arrowHeadLength / 2)), width: arrowHeadLength, height: PERIOD_CELL_BORDER))
        arrowStick.backgroundColor = color
        arrowHeadTop.backgroundColor = color
        arrowHeadBottom.backgroundColor = color
        arrowHeadTop.transform = CGAffineTransform(rotationAngle: rotationAngle)
        arrowHeadBottom.transform = CGAffineTransform(rotationAngle: -1 * rotationAngle)
        self.addSubview(arrowStick)
        self.addSubview(arrowHeadTop)
        self.addSubview(arrowHeadBottom)
        self.backgroundColor = UIColor.clear
    }

}
