//
//  Tinder.swift
//  MATLABit
//
//  Created by Thomas Naudet on 07/04/16.
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
import pop
import SDWebImage

class Tinder: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var kolodaView: KolodaView!
    var emptyDataSetView: DZNEmptyDataSetView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var noBtn: UIImageView!
    @IBOutlet var yesBtn: UIImageView!
    @IBOutlet var listeBtn: UIBarButtonItem!
    @IBOutlet var bestBtn: UIBarButtonItem!
    @IBOutlet var emptyLabel: UILabel!
    var matches = Array<[String : String]>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyLabel.alpha = 0.0
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
        
        let hasAccess = Data.isConnected() && Data.hasProfilePic()
        tableView.hidden = hasAccess
        navigationItem.rightBarButtonItems = hasAccess ? [listeBtn, bestBtn] : nil
        
        if !hasAccess {
            tableView.reloadEmptyDataSet()
        } else {
            fetchData()
        }
    }
    
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
        
        if Data.isConnected() {
            if Data.hasNotifs() == 1 {
                let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
                UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                UIApplication.sharedApplication().registerForRemoteNotifications()
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "notifsAsked")
            } else if Data.hasNotifs() == -1 {
                let alert = UIAlertController(title: "Quelle tristesse",
                                              message: "Tu as désactivé les notifications, nous ne pouvons pas recevoir tes matches !", preferredStyle: .Alert)
//                alert.addAction(UIAlertAction(title: "Je pleure", style: .Destructive, handler: nil))
                alert.addAction(UIAlertAction(title: "Corriger ça !", style: .Default, handler: { (a) in
                    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                }))
                presentViewController(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Sivouplé",
                                              message: "Nous avons besoin des notifications pour recevoir tes matches\n\nTape juste sur Autoriser !", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Nan", style: .Destructive, handler: nil))
                alert.addAction(UIAlertAction(title: "Autoriser", style: .Default, handler: { (a) in
                    let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
                    UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                    UIApplication.sharedApplication().registerForRemoteNotifications()
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "notifsAsked")
                }))
                presentViewController(alert, animated: true, completion: nil)
            }
        }
	}
    
    
    // MARK: Actions
    
    func fetchData() {
        if let login = KeychainSwift().get("login"),
            passw = KeychainSwift().get("passw") {
            let body = ["client": login,
                        "password": passw,
                        "hash": ("Discipliné666" + login + passw).sha256()]
            Data.JSONRequest(Data.sharedData.phpURLs["getMatches"]!, on: nil, post: body) { (JSON) in
                if let json = JSON {
                    let oldData = self.matches
                    if let status = json.valueForKey("status") as? Int,
                        data = json.valueForKey("data") as? [String: AnyObject],
                        people = data["people"] as? Array<[String: String]> {
                        if status == 1 {
                            let animation = CATransition()
                            animation.duration = 0.25
                            animation.type = kCATransitionFade
                            self.tableView.layer.addAnimation(animation, forKey: nil)
                            
                            if !self.matches.isEmpty {
                                let oldPeople = people.filter({ (elementServ: [String: String]) -> Bool in
                                    self.matches.contains({ (elementApp: [String: String]) -> Bool in
                                        elementApp["login"] == elementServ["login"]
                                    })
                                })
                                let newPeople = people.filter({ (elementServ: [String: String]) -> Bool in
                                    !self.matches.contains({ (elementApp: [String: String]) -> Bool in
                                        elementApp["login"] == elementServ["login"]
                                    })
                                })
                                let total: Array<[String: String]> = oldPeople + newPeople
                                self.matches = total
                            } else {
                                UIView.animateWithDuration(0.5) {
                                    self.emptyLabel.alpha = 1.0
                                }
                                self.matches = people
                            }
                        } else {
                            self.matches = Array<[String: String]>()
                        }
                    } else {
                        self.matches = Array<[String: String]>()
                    }
                    self.loadFetchedData(oldData)
                }
            }
        }
    }
    
    func loadFetchedData(before: Array<[String : String]>) {
        var recharger = true
        
        if matches.count == before.count {
            recharger = false
            for match in matches {
                if !before.contains({ $0 == match }) {
                    recharger = true
                    break
                }
            }
        }
        
        if recharger {
            kolodaView.reloadData()
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
        return Data.sharedData.logo2.scaleAndCrop(CGSize(width: 127 * pow(height / 480, 2), height: 127 * pow(height / 480, 2)))
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
    
    func kolodaDidResetCard(koloda: KolodaView) {
        UIView.animateWithDuration(0.5) {
            self.emptyLabel.alpha = 0.0
        }
    }
    
    func koloda(koloda: KolodaView, didSwipeCardAtIndex index: UInt, inDirection direction: SwipeResultDirection) {
        if direction == .Right {
            if let login = KeychainSwift().get("login"),
                passw = KeychainSwift().get("passw"),
                coeur = matches[Int(index)]["login"] {
                let body = ["client": login,
                            "password": passw,
                            "coeur": coeur,
                            "hash": ("AdolfUnChien.com" + login + coeur + passw).sha256()]
                Data.JSONRequest(Data.sharedData.phpURLs["sendMatch"]!, on: nil, post: body) { (JSON) in
                    if let json = JSON {
                        if let status = json.valueForKey("status") as? Int,
                            cause = json.valueForKey("cause") as? String {
                            if status != 1 {
                                let alert = UIAlertController(title: "Erreur lors de l'ajout à vos touches", message: cause, preferredStyle: .Alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                            }
                        } else {
                            let alert = UIAlertController(title: "Erreur lors de l'ajout à vos touches", message: "Erreur serveur", preferredStyle: .Alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func kolodaDidRunOutOfCards(koloda: KolodaView) {
//        kolodaView.resetCurrentCardIndex()
        UIView.animateWithDuration(0.5) { 
            self.emptyLabel.alpha = 1.0
        }
        fetchData()
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
        return UInt(matches.count)
    }
    
    func koloda(koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView {
        let nib = UINib(nibName: "CardView", bundle: nil)
        let card = nib.instantiateWithOwner(self, options: nil).first as! CardView
        card.layer.cornerRadius = 10
        card.layer.masksToBounds = true
        
        if matches.count > Int(index) {
            let match = matches[Int(index)]
            card.label.text = match["name"]
            SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: match["img"]!), options: [],
                                                                   progress: nil, completed: { (image, error, cacheType, finished, url) in
                                                                    if image != nil {
                                                                        card.image.image = image
                                                                    }
            })
        }
        
        return card
    }
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView? {
        let overlay = UINib(nibName: "CardOverlay", bundle: nil).instantiateWithOwner(self, options: nil).first as! CardOverlay
        overlay.layer.cornerRadius = 10
        overlay.layer.masksToBounds = true
        return overlay
    }
}


class CardView: UIView {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
}

