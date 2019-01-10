//
//  Arrow.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/17/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class Arrow: UIView {
    
    let tail = UIView()
    let head1 = UIView()
    let head2 = UIView()
    
    var _pointsRight = false
    var _isTop = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        tail.frame = CGRect(x: -1 * (PERIOD_CELL_BORDER / 2), y: (frame.height / 2) - (PERIOD_CELL_BORDER / 2), width: frame.width, height: PERIOD_CELL_BORDER)
        let rotationAngle: CGFloat = .pi * (30.0 / 180.0)
        let headLength = ((frame.height - PERIOD_CELL_BORDER) / 2) / sin(rotationAngle)
        head1.frame = CGRect(x: tail.frame.maxX - (cos(rotationAngle) * (headLength / 2)) - (headLength / 2), y: tail.frame.minY - ((headLength / 2) * sin(rotationAngle)), width: headLength, height: PERIOD_CELL_BORDER)
        head2.frame = CGRect(x: tail.frame.maxX - (cos(-1 * rotationAngle) * (headLength / 2)) - (headLength / 2), y: tail.frame.minY + (sin(rotationAngle) * (headLength / 2)), width: headLength, height: PERIOD_CELL_BORDER)
        head1.transform = CGAffineTransform(rotationAngle: rotationAngle)
        head2.transform = CGAffineTransform(rotationAngle: -1 * rotationAngle)
        self.addSubview(tail)
        self.addSubview(head1)
        self.addSubview(head2)
    }
    
    override var tintColor: UIColor? {
        get {
            return super.tintColor
        } set (v) {
            super.tintColor = v
            tail.backgroundColor = v
            head1.backgroundColor = v
            head2.backgroundColor = v
        }
    }
    
    var pointsRight: Bool {
        get {
            return _pointsRight
        } set (v) {
            _pointsRight = v
            self.transform = CGAffineTransform(scaleX: _pointsRight ? 1 : -1, y: _isTop ? 1 : -1)
        }
    }
    
    var isTop: Bool {
        get {
            return _isTop
        } set (v) {
            _isTop = v
            self.transform = CGAffineTransform(scaleX: _pointsRight ? 1 : -1, y: _isTop ? 1 : -1)
        }
    }
}
