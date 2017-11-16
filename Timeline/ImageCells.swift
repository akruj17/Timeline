//
//  BackgroundModifierCell.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/28/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TimelineImageCell: UICollectionViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    var gradientLayer = CAGradientLayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.01).cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.9).cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.01).cgColor]
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0);
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0);
        self.layer.mask = gradientLayer
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer.bounds.size != gradientLayer.bounds.size {
            gradientLayer.frame = layer.bounds
        }
    }
    
}

class BackgroundModifierImageCell: UICollectionViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var checkmark: UIImageView!
    var alphaLayer =  CALayer()
    var _didSelect = false
    
    var didSelect: Bool {
        set {
            if newValue {
                checkmark.isHidden = false
                imgView.layer.addSublayer(alphaLayer)
            } else {
                checkmark.isHidden = true
                alphaLayer.removeFromSuperlayer()
                checkmark.layer.zPosition = 0
            }
            _didSelect = newValue
        } get {
            return _didSelect
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        alphaLayer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.7).cgColor
        alphaLayer.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
    

    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer.bounds.size != alphaLayer.bounds.size {
            alphaLayer.frame = layer.bounds
        }
    }

    
}
