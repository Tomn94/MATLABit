//
//  CustomKolodaView.swift
//  Koloda
//
//  Created by Eugene Andreyev on 7/11/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import UIKit

class CustomKolodaView: KolodaView {
    
    private let cardSideMargin: CGFloat = 50.0
    private let backgroundCardsTopMargin: CGFloat = 100.0
    private let backgroundCardsScalePercent: CGFloat = 0.95
    
    override func frameForCardAtIndex(_ index: UInt) -> CGRect {
        let bottomOffset:CGFloat = 100
        let topOffset = backgroundCardsTopMargin * CGFloat(self.countOfVisibleCards - 1)
        let scalePercent = backgroundCardsScalePercent
        var width = self.frame.width * pow(scalePercent, CGFloat(index)) - cardSideMargin
        var height = (self.frame.height - bottomOffset - topOffset) * pow(scalePercent, CGFloat(index))
        let square = min(width, height, 400)
        width = square
        height = square
        let xOffset = (self.frame.width - width) / 2
        let multiplier: CGFloat = index > 0 ? 1.0 : 0.0
        let previousCardFrame = index > 0 ? frameForCardAtIndex(max(index - 1, 0)) : CGRect.zero
        let yOffset: CGFloat = 100.0 + (multiplier * (previousCardFrame.height - height) / 2)//(CGRectGetHeight(previousCardFrame) - height + previousCardFrame.origin.y + backgroundCardsTopMargin) * multiplier
        let frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        
        return frame
    }
    
}
