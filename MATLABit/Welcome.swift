//
//  Welcome.swift
//  MATLABit
//
//  Created by Thomas Naudet on 08/04/16.
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
import SpriteKit

class Welcome: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    private let sectionSize = 10
    private let decalageBest = 3 // < sectionSize
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var tableView: UITableView!
    var emptyDataSetView: DZNEmptyDataSetView!
    @IBOutlet var content: UIView!
    @IBOutlet var logo: Logo!
    @IBOutlet var playBtn: UIBarButtonItem!
    private var animator: UIDynamicAnimator!
    
    private var iOSPic = UIImage(named: "ios")?.scaleAndCrop(CGSize(width: 15, height: 15)).withRenderingMode(.alwaysTemplate)
    private var androidPic = UIImage(named: "android")?.scaleAndCrop(CGSize(width: 15, height: 15)).withRenderingMode(.alwaysTemplate)
    
    private var scores = Array<Array<(String, Int, String, Int)>>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logo.image = Data.sharedData.logo
        logo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bounce)))
        animator = UIDynamicAnimator(referenceView: content)
        
        let backView = UIView()
        backView.backgroundColor = UIColor.groupTableViewBackground
        tableView.backgroundView = backView
        
        loadFetchedData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillAppear(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadEmptyDataSet()
        Data.JSONRequest(Data.sharedData.phpURLs["getScores"]!, on: nil) { (JSON) in
            if let json = JSON {
                if let status = json["status"] as? Int,
                   let data   = json["data"]   as? [String: AnyObject],
                   let scores = data["scores"] as? [AnyObject] {
                    if status == 1 {
                        var newScores = Array<(String, Int, String, Int)>()
                        for score in scores {
                            let tuple = (score.value(forKey: "login") as! String,
                                         score.value(forKey: "score") as! Int,
                                         score.value(forKey: "os") as! String,
                                         score.value(forKey: "order") as! Int)
                            let name = score.value(forKey: "login") as? String
                            if name == KeychainSwift().get("login") || name == KeychainSwift().get("uname") {
                                Data.sharedData.bestScore = score.value(forKey: "score") as? Int ?? 0
                            }
                            newScores.append(tuple)
                        }
                        let animation = CATransition()
                        animation.duration = 0.25
                        animation.type = kCATransitionFade
                        self.tableView.layer.add(animation, forKey: nil)
                        Data.sharedData.scores = newScores
                    } else {
                        Data.sharedData.scores = Array<(String, Int, String, Int)>()
                    }
                } else {
                    Data.sharedData.scores = Array<(String, Int, String, Int)>()
                }
                self.loadFetchedData()
            }
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        animator.removeAllBehaviors()
    }
    
    
    // MARK: - Actions
    
    func loadFetchedData() {
        if !Data.isConnected() {
            scores.removeAll()
        } else {
            scores = Data.sharedData.scores.chunk(sectionSize)
        }
        
        let hasScores = !scores.isEmpty
        tableView.backgroundColor = hasScores ? UIColor.white : UIColor.groupTableViewBackground
        tableView.tableFooterView = hasScores ? nil : UIView()
        
        tableView.reloadData()
        
        navigationItem.rightBarButtonItem = Data.isConnected() ? playBtn : nil
    }
    
    @IBAction func play() {
        if !Data.isConnected() {
            return
        }
        let vc = GameVC()
        let gameView = SKView()
        gameView.ignoresSiblingOrder = true
        vc.view = gameView
        present(vc, animated: true, completion: nil)
    }
    
    func bounce() {
        animator.removeAllBehaviors()
        
        let collisionBehavior = UICollisionBehavior(items: [logo])
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true;
        animator.addBehavior(collisionBehavior)
        
        if !logo.hasFallen {
            logo.hasFallen = true
            
            let gravityBehavior = UIGravityBehavior(items: [logo])
            gravityBehavior.magnitude = 5
            animator.addBehavior(gravityBehavior)
            
            let elasticityBehavior = UIDynamicItemBehavior(items: [logo])
            elasticityBehavior.elasticity = 0.8;
            animator.addBehavior(elasticityBehavior)
        } else {
            let pusher = UIPushBehavior(items: [logo], mode: .instantaneous)
            pusher.pushDirection = CGVector(dx: 50, dy: 40)
            pusher.active = true
            animator.addBehavior(pusher)
            
            let paddle = UIDynamicItemBehavior(items: [logo])
            paddle.elasticity = 0.8
            animator.addBehavior(paddle)
        }
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if scores.isEmpty {
            return 0
        }
        return scores.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return decalageBest
        } else if section == 1 {
            return scores[0].count - decalageBest
        }
        return scores[section - 1].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Podium"
        } else if section == 1 {
            return "\(decalageBest + 1)-\(sectionSize)"
        }
        let index = (section - 1) * sectionSize
        return "\(index + 1)-\(index + sectionSize)"
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 100
        }
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var index = indexPath.row
        var data: (String, Int, String, Int)
        if indexPath.section == 1 {
            index += decalageBest
        }
        if indexPath.section == 0 {
            data = scores[0][index]
        } else {
            data = scores[indexPath.section - 1][index]
        }
        var rang = String(data.1) + " point"
        if data.1 > 1 {
            rang += "s"
        }
        let currentUser = data.0 == KeychainSwift().get("login") || data.0 == KeychainSwift().get("uname")
        
        var cell: UITableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "scoreBestCell", for: indexPath)
            
            cell.textLabel!.text = data.0
            cell.textLabel!.font = currentUser ? UIFont.boldSystemFont(ofSize: cell.textLabel!.font.pointSize) : UIFont.systemFont(ofSize: cell.textLabel!.font.pointSize)
            cell.detailTextLabel!.font = currentUser ? UIFont.boldSystemFont(ofSize: cell.detailTextLabel!.font.pointSize) : UIFont.systemFont(ofSize: cell.detailTextLabel!.font.pointSize)
            cell.imageView?.image = UIImage(named: ("medal" + String(index + 1)))
            
            let st = rang + " " + data.2
            let at = NSMutableAttributedString(string: st)
            at.setAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 13), NSForegroundColorAttributeName: UIColor(white: 0.85, alpha: 1)],
                             range: NSMakeRange(st.characters.count - data.2.characters.count, data.2.characters.count))
            cell.detailTextLabel!.attributedText = at
            
        } else {
            let scoreCell = tableView.dequeueReusableCell(withIdentifier: "scoreCell", for: indexPath) as! ScoreCell
            
            scoreCell.nameLabel.text = data.0
            scoreCell.nameLabel.font = currentUser ? UIFont.boldSystemFont(ofSize: scoreCell.nameLabel.font.pointSize) : UIFont.systemFont(ofSize: scoreCell.nameLabel.font.pointSize)
            scoreCell.scoreLabel.text = rang
            scoreCell.scoreLabel.font = currentUser ? UIFont.boldSystemFont(ofSize: scoreCell.scoreLabel.font.pointSize) : UIFont.systemFont(ofSize: scoreCell.scoreLabel.font.pointSize)
            scoreCell.descLabel.text = String(data.3)
            scoreCell.osLabel.text = data.2
            
            cell = scoreCell
        }
        
        
        /*cell.imageView?.tintColor = UIColor(white: 0.8, alpha: 1);
        if data.2.lowercaseString == "ios" {
            cell.imageView?.image = iOSPic
        } else if data.2.lowercaseString == "android" {
            cell.imageView?.image = androidPic
        } else {
            cell.imageView?.image = nil
        }*/
        
        return cell
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
        return NSAttributedString(string: "On botte en touche pour trouver ton pseudo, joue grâce à ton login ESEO !", attributes: attrs)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17),
                     NSForegroundColorAttributeName: UINavigationBar.appearance().barTintColor!] as [String : Any]
        return NSAttributedString(string: "Me connecter", attributes: attrs)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap didTapButton: UIButton!) {
        UIApplication.shared.sendAction(navigationItem.leftBarButtonItem!.action!, to: navigationItem.leftBarButtonItem!.target, from: nil, for: nil)
    }
}

class Logo: UIImageView {
    fileprivate var hasFallen = false
    
    @available(iOS 9.0, *)
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return (hasFallen) ? .ellipse : .rectangle
    }
}
