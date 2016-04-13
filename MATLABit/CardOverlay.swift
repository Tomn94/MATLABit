//
//  CardOverlay.swift
//  MATLABit
//
//  Created by Tomn on 12/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class CardOverlay: OverlayView {
    
    @IBOutlet lazy var overlayImageView: UIImageView! = {
        [unowned self] in
        
        var imageView = UIImageView(frame: self.bounds)
        self.addSubview(imageView)
        
        return imageView
        }()
    
    override var overlayState:OverlayMode  {
        didSet {
            switch overlayState {
            case .Left :
                overlayImageView.image = UIImage(named: "noOverlay")
            case .Right :
                overlayImageView.image = UIImage(named: "yesOverlay")
            default:
                overlayImageView.image = nil
            }
            
        }
    }
    
}
