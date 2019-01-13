//
//  Arrow.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/17/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class Arrow: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var tail: UIView!
    @IBOutlet weak var head1: UIView!
    @IBOutlet weak var head2: UIView!
    
    
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
        Bundle.main.loadNibNamed("Arrow", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        head1.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        head1.transform = CGAffineTransform(rotationAngle: .pi / 6)
        head2.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        head2.transform = CGAffineTransform(rotationAngle: .pi / -6)
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
