//
//  Welcome.swift
//  MATLABit
//
//  Created by Tomn on 08/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit
import SpriteKit

class Welcome: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    private let sectionSize = 10
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var tableView: UITableView!
    var emptyDataSetView: DZNEmptyDataSetView!
    @IBOutlet var content: UIView!
    @IBOutlet var logo: Logo!
    @IBOutlet var playBtn: UIBarButtonItem!
    private var animator: UIDynamicAnimator!
    
    private var scores = Array<Array<(String, Int)>>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logo.image = Data.sharedData.logo
        logo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bounce)))
        animator = UIDynamicAnimator(referenceView: content)
        
        let backView = UIView()
        backView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        tableView.backgroundView = backView
        
        loadFetchedData()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(viewWillAppear(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadEmptyDataSet()
        Data.JSONRequest(Data.sharedData.phpURLs["getScores"]!, on: self) { (JSON) in
            if let json = JSON {
                if let status = json.valueForKey("status") as? Int,
                    data = json.valueForKey("data") as? [String: AnyObject],
                    scores = data["scores"] as? [AnyObject] {
                    if status == 1 {
                        var newScores = Array<(String, Int)>()
                        for score in scores {
                            let tuple = (score.valueForKey("login") as! String, score.valueForKey("score") as! Int)
                            let name = score.valueForKey("login") as? String
                            if name == KeychainSwift().get("login") || name == KeychainSwift().get("uname") {
                                Data.sharedData.bestScore = score.valueForKey("score") as? Int ?? 0
                            }
                            newScores.append(tuple)
                        }
                        let animation = CATransition()
                        animation.duration = 0.25
                        animation.type = kCATransitionFade
                        self.tableView.layer.addAnimation(animation, forKey: nil)
                        Data.sharedData.scores = newScores
                    } else {
                        Data.sharedData.scores = Array<(String, Int)>()
                    }
                } else {
                    Data.sharedData.scores = Array<(String, Int)>()
                }
                self.loadFetchedData()
            }
        }
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        animator.removeAllBehaviors()
    }
    
    
    // MARK: - Actions
    
    func loadFetchedData() {
        if !Data.isConnected() {
            scores.removeAll()
        } else {
            scores = Data.sharedData.scores.chunk(sectionSize)
        }
        
        let hasScores = scores.count > 0
        tableView.backgroundColor = hasScores ? UIColor.whiteColor() : UIColor.groupTableViewBackgroundColor()
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
        presentViewController(vc, animated: true, completion: nil)
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
            let pusher = UIPushBehavior(items: [logo], mode: .Instantaneous)
            pusher.pushDirection = CGVectorMake(50, 40)
            pusher.active = true
            animator.addBehavior(pusher)
            
            let paddle = UIDynamicItemBehavior(items: [logo])
            paddle.elasticity = 0.8
            animator.addBehavior(paddle)
        }
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return scores.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scores[section].count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let index = section * sectionSize
        return "\(index + 1)-\(index + sectionSize)"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("scoreCell", forIndexPath: indexPath)
        
        let data = scores[indexPath.section][indexPath.row]
        var rang = String(data.1)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                rang = "🏆" + rang
            } else if indexPath.row == 1 {
                if #available(iOS 9.1, *) {
                    rang = "🏅" + rang
                } else {
                    rang = "💪" + rang
                }
            } else if indexPath.row == 2 {
                rang = "⚡️" + rang
            } else if indexPath.row == 3 {
                rang = "🍌" + rang
            }
        }
        
        let currentUser = data.0 == KeychainSwift().get("login") || data.0 == KeychainSwift().get("uname")
        cell.textLabel!.text = data.0
        cell.textLabel!.font = currentUser ? UIFont.boldSystemFontOfSize(cell.textLabel!.font.pointSize) : UIFont.systemFontOfSize(cell.textLabel!.font.pointSize)
        cell.detailTextLabel!.text = rang
        cell.detailTextLabel!.font = currentUser ? UIFont.boldSystemFontOfSize(cell.detailTextLabel!.font.pointSize) : UIFont.systemFontOfSize(cell.detailTextLabel!.font.pointSize)
        
        return cell
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
        return NSAttributedString(string: "On botte en touche pour trouver ton pseudo, joue grâce à ton login ESEO !", attributes: attrs)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17),
                     NSForegroundColorAttributeName: UINavigationBar.appearance().barTintColor!]
        return NSAttributedString(string: "Me connecter", attributes: attrs)
    }
    
    func emptyDataSet(scrollView: UIScrollView!, didTapButton: UIButton!) {
        UIApplication.sharedApplication().sendAction(navigationItem.leftBarButtonItem!.action, to: navigationItem.leftBarButtonItem!.target, from: nil, forEvent: nil)
    }
}

class Logo: UIImageView {
    private var hasFallen = false
    
    @available(iOS 9.0, *)
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return (hasFallen) ? .Ellipse : .Rectangle
    }
}