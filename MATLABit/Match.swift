//
//  Match.swift
//  MATLABit
//
//  Created by Thomas Naudet on 17/04/16.
//  Copyright © 2016 Thomas Naudet

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/
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
