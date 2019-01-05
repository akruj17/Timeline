//
//  TitleBox.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 1/2/19.
//  Copyright © 2019 Edumacation!. All rights reserved.
//

import UIKit

class TitleBox: UIView {

    //VIEWS
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var eventBox: UIView!
    @IBOutlet weak var stick: UIView!
    @IBOutlet weak var titleView: UITextView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    //CONSTRAINTS (EXACTLY ONE OF THE PAIRS MUST BE ACTIVE AT ONCE)
    //PAIR ONE - TOP EVENTS
    @IBOutlet weak var topConstraint1: NSLayoutConstraint!
    @IBOutlet weak var topConstraint2: NSLayoutConstraint!
    //PAIR TWO - BOTTOM EVENTS
    @IBOutlet weak var bottomConstraint1: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint2: NSLayoutConstraint!
    
    //DATA VARIABLES
    var top = false
    var loading = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("TitleBox", owner: self, options: nil)
        //some layout setup
        eventBox.layer.borderWidth = TITLE_BORDER
        eventBox.layer.borderColor = UIColor.darkGray.cgColor
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configure(title: String, isTop: Bool) {
        titleView.text = title
        self.isTop = isTop
    }
    
//////GET-SET VARIABLES
    var isLoading : Bool {
        get {
            return loading
        } set (v) {
            loading = v
            if v {
                loadingIndicator.isHidden = false
                loadingIndicator.startAnimating()
                titleView.isHidden = true
            } else {
                loadingIndicator.stopAnimating()
                loadingIndicator.isHidden = true
                titleView.isHidden = false
            }
        }
    }
    
    var isTop : Bool {
        get {
            return top
        } set (v) {
            top = v
            if v {
                addConstraints([topConstraint1, topConstraint2])
                removeConstraints([bottomConstraint1, bottomConstraint2])
            } else {
                removeConstraints([topConstraint1, topConstraint2])
                addConstraints([bottomConstraint1, bottomConstraint2])
            }
        }
    }
}
