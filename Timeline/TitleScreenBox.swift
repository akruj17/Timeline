//
//  TitleScreenBox.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 12/2/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TitleScreenBox: UIView {

    var titleBox: UIView
    var textView: UITextView
    var stickView: UIView
    var image: UIImage?
    var imageView: UIImageView
    
    var isTopRow: Bool = false
    var stringVal: String = ""
    var color: UIColor
    let colorConstant: CGFloat = 100
    
    required init?(coder aDecoder: NSCoder) {
        titleBox = UIView()
        textView = UITextView()
        stickView = UIView()
        imageView = UIImageView()
        
        color = UIColor()
        
        super.init(coder: aDecoder)
        textView.isEditable = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.textAlignment = .center
        
        textView.font = UIFont(name: "AvenirNext-Regular", size: 25)
        textView.textAlignment = NSTextAlignment.center
        titleBox.layer.borderWidth = 5
    }
    
    override func draw(_ rect: CGRect) {
        let view = UIView()
        var boxFrame = CGRect()
        var stickFrame = CGRect()
        let boxHeight: CGFloat = 0.7 * rect.size.height
        
        boxFrame.size = CGSize(width: rect.width, height: boxHeight)
        if isTopRow {
            boxFrame.origin = CGPoint(x: 0, y: 0)
            stickFrame.origin = CGPoint(x: 0, y: boxHeight)
        }
        else {
            boxFrame.origin = CGPoint(x: 0, y: rect.size.height - boxHeight)
            stickFrame.origin = CGPoint(x: 0, y: 0)
        }
        
        titleBox.frame = boxFrame
        textView.frame = CGRect(x: 0, y: 0, width: titleBox.frame.width, height: titleBox.frame.height)
        stickFrame.size = CGSize(width: 5, height: rect.height - boxHeight)
        stickView.frame = stickFrame
        stickView.backgroundColor = color
        stickView.center.x = self.center.x
        
        textView.text = stringVal
        textView.backgroundColor = UIColor.clear
        titleBox.layer.borderColor = color.cgColor
        titleBox.center.x = self.center.x
        
        if let backgroundImage = image {
            imageView.image = image
        }
        imageView.frame = CGRect(x: 0, y: 0, width: titleBox.frame.width, height: titleBox.frame.height)
        imageView.alpha = 0.5
        
        titleBox.addSubview(imageView)
        titleBox.addSubview(textView)
        self.addSubview(titleBox)
        self.addSubview(stickView)
    }
}
