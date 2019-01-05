//
//  LoadingScreen.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 12/29/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

class LoadingScreen: UIView {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("LoadingScreen", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    override var isHidden: Bool {
        get {
            return super.isHidden
        }
        set(v) {
            super.isHidden = v
            if indicatorView != nil {
                if v {
                    indicatorView.stopAnimating()
                } else {
                    indicatorView.startAnimating()
                }

            }
        }
    }
    

}
