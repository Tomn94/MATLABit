//
//  Tinder.swift
//  MATLABit
//
//  Created by Tomn on 07/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit
import pop

private let numberOfCards: UInt = 5

class Tinder: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var kolodaView: KolodaView!
    var emptyDataSetView: DZNEmptyDataSetView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var noBtn: UIImageView!
    @IBOutlet var yesBtn: UIImageView!
    @IBOutlet var listeBtn: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        kolodaView.delegate = self
        kolodaView.dataSource = self
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        yesBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(swipeYes)))
        noBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(swipeNo)))
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(viewWillAppear(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let hasAccess = Data.isConnected() && Data.hasProfilePic();
        tableView.hidden = hasAccess
        navigationItem.rightBarButtonItem = hasAccess ? listeBtn : nil
        if !hasAccess {
            tableView.reloadEmptyDataSet()
        }
    }
    
    
    func swipeYes() {
        kolodaView.swipe(.Right)
    }
    
    func swipeNo() {
        kolodaView.swipe(.Left)
    }
    
    
    // MARK: - DZNEmptyDataSet
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        let height = UIScreen.mainScreen().bounds.size.height
        if UI_USER_INTERFACE_IDIOM() != .Pad && (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) || UIScreen.mainScreen().bounds.size.width > height) {
            return nil
        }
        return UIImage(named: "ESEOasis")?.scaleAndCrop(CGSize(width: 127 * pow(height / 480, 2), height: 127 * pow(height / 480, 2)))
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18),
                     NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        var string = "Ajoute une image de profil pour participer !"
        if !Data.isConnected() {
            string = "On botte en touche pour trouver ton pseudo, joue grâce à ton login ESEO !"
        }
        return NSAttributedString(string: string, attributes: attrs)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17),
                     NSForegroundColorAttributeName: UINavigationBar.appearance().barTintColor!]
        var string = "Mon profil"
        if !Data.isConnected() {
            string = "Me connecter"
        }
        return NSAttributedString(string: string, attributes: attrs)
    }
    
    func emptyDataSet(scrollView: UIScrollView!, didTapButton: UIButton!) {
        UIApplication.sharedApplication().sendAction(navigationItem.leftBarButtonItem!.action, to: navigationItem.leftBarButtonItem!.target, from: nil, forEvent: nil)
    }
    
    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        return true
    }
}

//MARK: KolodaViewDelegate
extension Tinder: KolodaViewDelegate {
    
    func kolodaDidRunOutOfCards(koloda: KolodaView) {
        kolodaView.resetCurrentCardIndex()
    }
    
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt) {
    }
    
    func kolodaShouldApplyAppearAnimation(koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaShouldMoveBackgroundCard(koloda: KolodaView) -> Bool {
        return false
    }
    
    func kolodaShouldTransparentizeNextCard(koloda: KolodaView) -> Bool {
        return false
    }
    
    func koloda(kolodaBackgroundCardAnimation koloda: KolodaView) -> POPPropertyAnimation? {
        let animation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
        animation.springBounciness = 9
        animation.springSpeed = 16
        return animation
    }
}

//MARK: KolodaViewDataSource
extension Tinder: KolodaViewDataSource {
    
    func kolodaNumberOfCards(koloda: KolodaView) -> UInt {
        return numberOfCards
    }
    
    func koloda(koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView {
//        return UIImageView(image: UIImage(named: "cards_\(index + 1)"))
        
        
        let nib = UINib(nibName: "CardView", bundle: nil)
        let card = nib.instantiateWithOwner(self, options: nil).first as! CardView
        card.layer.cornerRadius = 10
        card.layer.masksToBounds = true
        
        card.image.image = Data.sharedData.logo
        card.label.text  = "Jean Pierre"
        
        return card
    }
    /*
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView? {
        return NSBundle.mainBundle().loadNibNamed("CustomOverlayView",
                                                  owner: self, options: nil)[0] as? OverlayView
    }*/
}

class CardView: UIView {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
}
