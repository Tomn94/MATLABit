//
//  Match.swift
//  MATLABit
//
//  Created by Tomn on 17/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class Match: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    
    private var nom = "Il/elle"
    private var img = ""
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        descLabel.text = nom + " te veut dans sa liste BDE"
        if img != "" {
            imageView.sd_setImageWithURL(NSURL(string: img), placeholderImage: UIImage(named: "placeholder"))
        }
        
        imageView.layer.cornerRadius = CGFloat(imageView.frame.width / 2)
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 4
        imageView.layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    func setVisualData(pic: String?, name: String?) {
        if let n = name {
            nom = n
        }
        if let i = pic {
            img = i
        }
    }

    @IBAction func close() {
        dismissViewControllerAnimated(true, completion:nil)
    }
}
