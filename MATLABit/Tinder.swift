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
        tableView.backgroundColor = UIColor.groupTableViewBackground
        
        yesBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(swipeYes)))
        noBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(swipeNo)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillAppear(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let hasAccess = Data.isConnected() && Data.hasProfilePic()
        tableView.isHidden = hasAccess
        navigationItem.rightBarButtonItems = hasAccess ? [listeBtn, bestBtn] : nil
        
        if !hasAccess {
            tableView.reloadEmptyDataSet()
        } else {
            fetchData()
        }
    }
    
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
        
        if Data.isConnected() {
            if Data.hasNotifs() == 1 {
                let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)
                UIApplication.shared.registerForRemoteNotifications()
                UserDefaults.standard.set(true, forKey: "notifsAsked")
            } else if Data.hasNotifs() == -1 {
                let alert = UIAlertController(title: "Quelle tristesse",
                                              message: "Tu as désactivé les notifications, nous ne pouvons pas recevoir tes matches !", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "Je pleure", style: .Destructive, handler: nil))
                alert.addAction(UIAlertAction(title: "Corriger ça !", style: .default, handler: { (a) in
                    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                }))
                present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Sivouplé",
                                              message: "Nous avons besoin des notifications pour recevoir tes matches\n\nTape juste sur Autoriser !", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Nan", style: .destructive, handler: nil))
                alert.addAction(UIAlertAction(title: "Autoriser", style: .default, handler: { (a) in
                    let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                    UIApplication.shared.registerUserNotificationSettings(settings)
                    UIApplication.shared.registerForRemoteNotifications()
                    UserDefaults.standard.set(true, forKey: "notifsAsked")
                }))
                present(alert, animated: true, completion: nil)
            }
        }
	}
    
    
    // MARK: Actions
    
    func fetchData() {
        if let login = KeychainSwift().get("login"),
           let passw = KeychainSwift().get("passw") {
           let body = ["client": login,
                       "password": passw,
                       "hash": ("Discipliné666" + login + passw).sha256()]
            Data.JSONRequest(Data.sharedData.phpURLs["getMatches"]!, on: nil, post: body) { (JSON) in
                if let json = JSON {
                    let oldData = self.matches
                    if let status = json["status"] as? Int,
                       let data = json["data"] as? [String: AnyObject],
                       let people = data["people"] as? Array<[String: String]> {
                        if status == 1 {
                            let animation = CATransition()
                            animation.duration = 0.25
                            animation.type = kCATransitionFade
                            self.tableView.layer.add(animation, forKey: nil)
                            
                            if !self.matches.isEmpty {
                                let oldPeople = people.filter({ (elementServ: [String: String]) -> Bool in
                                    self.matches.contains(where: { (elementApp: [String: String]) -> Bool in
                                        elementApp["login"] == elementServ["login"]
                                    })
                                })
                                let newPeople = people.filter({ (elementServ: [String: String]) -> Bool in
                                    !self.matches.contains(where: { (elementApp: [String: String]) -> Bool in
                                        elementApp["login"] == elementServ["login"]
                                    })
                                })
                                let total: Array<[String: String]> = oldPeople + newPeople
                                self.matches = total
                            } else {
                                UIView.animate(withDuration: 0.5, animations: {
                                    self.emptyLabel.alpha = 1.0
                                }) 
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
    
    func loadFetchedData(_ before: Array<[String : String]>) {
        var recharger = true
        
        if matches.count == before.count {
            recharger = false
            for match in matches {
                if !before.contains(where: { $0 == match }) {
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
        kolodaView.swipe(.right)
    }
    
    func swipeNo() {
        kolodaView.swipe(.left)
    }
    
    
    // MARK: - DZNEmptyDataSet
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        let height = UIScreen.main.bounds.size.height
        if UI_USER_INTERFACE_IDIOM() != .pad && (UIDeviceOrientationIsLandscape(UIDevice.current.orientation) || UIScreen.main.bounds.size.width > height) {
            return nil
        }
        return Data.sharedData.logo2.scaleAndCrop(CGSize(width: 127 * pow(height / 480, 2), height: 127 * pow(height / 480, 2)))
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
                     NSForegroundColorAttributeName: UIColor.darkGray]
        var string = "Ajoute une image de profil pour participer !"
        if !Data.isConnected() {
            string = "On botte en touche pour trouver ton pseudo, joue grâce à ton login ESEO !"
        }
        return NSAttributedString(string: string, attributes: attrs)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17),
                     NSForegroundColorAttributeName: UINavigationBar.appearance().barTintColor!] as [String : Any]
        var string = "Mon profil"
        if !Data.isConnected() {
            string = "Me connecter"
        }
        return NSAttributedString(string: string, attributes: attrs)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap didTapButton: UIButton!) {
        UIApplication.shared.sendAction(navigationItem.leftBarButtonItem!.action!, to: navigationItem.leftBarButtonItem!.target, from: nil, for: nil)
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}

//MARK: KolodaViewDelegate
extension Tinder: KolodaViewDelegate {
    
    func kolodaDidResetCard(_ koloda: KolodaView) {
        UIView.animate(withDuration: 0.5, animations: {
            self.emptyLabel.alpha = 0.0
        }) 
    }
    
    func koloda(_ koloda: KolodaView, didSwipeCardAtIndex index: UInt, inDirection direction: SwipeResultDirection) {
        if direction == .right {
            if let login = KeychainSwift().get("login"),
               let passw = KeychainSwift().get("passw"),
               let coeur = matches[Int(index)]["login"] {
                let body = ["client": login,
                            "password": passw,
                            "coeur": coeur,
                            "hash": ("AdolfUnChien.com" + login + coeur + passw).sha256()]
                Data.JSONRequest(Data.sharedData.phpURLs["sendMatch"]!, on: nil, post: body) { (JSON) in
                    if let json = JSON {
                        if let status = json["status"] as? Int,
                            let cause = json["cause"] as? String {
                            if status != 1 {
                                let alert = UIAlertController(title: "Erreur lors de l'ajout à vos touches", message: cause, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        } else {
                            let alert = UIAlertController(title: "Erreur lors de l'ajout à vos touches", message: "Erreur serveur", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
//        kolodaView.resetCurrentCardIndex()
        UIView.animate(withDuration: 0.5, animations: { 
            self.emptyLabel.alpha = 1.0
        }) 
        fetchData()
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAtIndex index: UInt) {
        
    }
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool {
        return false
    }
    
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool {
        return false
    }
    
    func koloda(kolodaBackgroundCardAnimation koloda: KolodaView) -> POPPropertyAnimation? {
        let animation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
        animation?.springBounciness = 9
        animation?.springSpeed = 16
        return animation
    }
}

//MARK: KolodaViewDataSource
extension Tinder: KolodaViewDataSource {
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> UInt {
        return UInt(matches.count)
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView {
        let nib = UINib(nibName: "CardView", bundle: nil)
        let card = nib.instantiate(withOwner: self, options: nil).first as! CardView
        card.layer.cornerRadius = 10
        card.layer.masksToBounds = true
        
        if matches.count > Int(index) {
            let match = matches[Int(index)]
            card.label.text = match["name"]
            SDWebImageManager.shared().downloadImage(with: URL(string: match["img"]!), options: [],
                                                                   progress: nil, completed: { (image, error, cacheType, finished, url) in
                                                                    if image != nil {
                                                                        card.image.image = image
                                                                    }
            })
        }
        
        return card
    }
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView? {
        let overlay = UINib(nibName: "CardOverlay", bundle: nil).instantiate(withOwner: self, options: nil).first as! CardOverlay
        overlay.layer.cornerRadius = 10
        overlay.layer.masksToBounds = true
        return overlay
    }
}


class CardView: UIView {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
}

