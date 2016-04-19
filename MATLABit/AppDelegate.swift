//
//  AppDelegate.swift
//  MATLABit
//
//  Created by Tomn on 07/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var notifAfterLaunch: NSDictionary?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let appearance = UINavigationBar.appearance()
        appearance.barTintColor = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
        appearance.tintColor = UIColor(red: 0.9608, green: 0.9205, blue: 0.816, alpha: 1)
        appearance.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        window?.tintColor = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
        
        if !NSUserDefaults.standardUserDefaults().boolForKey("alreadyBeenLaunched") {
            KeychainSwift().clear()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "alreadyBeenLaunched")
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(launchFinished), name: "launchFinished", object: nil)
        
        if let notif = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary,
            _ = notif["aps"] as? NSDictionary {
            notifAfterLaunch = notif
        }
        
        return true
    }
    
    func launchFinished() {
        let sb = UIStoryboard(name:"Main", bundle:nil)
        let vc = sb.instantiateInitialViewController()!
        UIView.transitionFromView(self.window!.rootViewController!.view, toView: vc.view, duration: 0.7,
                                  options: [.TransitionFlipFromLeft, .AllowAnimatedContent, .LayoutSubviews]) { (finished) in
            if finished {
                self.window!.rootViewController = vc
                if let notif = self.notifAfterLaunch {
                    NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(self.handleNotif(_:)), userInfo: notif, repeats: false)
                    self.notifAfterLaunch = nil
                }
            }
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: Notifications
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        if Data.isConnected() {
            let tokenChars = UnsafePointer<CChar>(deviceToken.bytes)
            var push = ""
            for i in 0..<deviceToken.length {
                push += String(format: "%02.2hhx", arguments: [tokenChars[i]])
            }
            
            if let login = KeychainSwift().get("login"),
                passw = KeychainSwift().get("passw") {
                let body = ["client": login,
                            "password": passw,
                            "os": "IOS",
                            "token": push,
                            "hash": ("Erreur mémoire cache" + login + passw + "IOS" + push).sha256()]
                Data.sharedData.needsLoadingSpin(true)
                Data.JSONRequest(Data.sharedData.phpURLs["newPush"]!, on: nil, post: body) { (JSON) in
                    Data.sharedData.needsLoadingSpin(false)
                    NSUserDefaults.standardUserDefaults().setValue(push, forKey: "pushToken")
                }
            }
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(handleNotif(_:)), userInfo: userInfo, repeats: false)
    }
    
    func handleNotif(timer: NSTimer) {
        let userInfo = timer.userInfo!
        if let action = userInfo["action"] as? Int {
            if action == 1 {
                if let matchData = userInfo["matchData"] as? [String: AnyObject] {
                    let sb = UIStoryboard(name:"Match", bundle:nil)
                    let vc = sb.instantiateInitialViewController() as! Match
                    vc.modalPresentationStyle = .OverFullScreen
                    vc.setVisualData(matchData["img"] as? String, name: matchData["name"] as? String)
                    
                    window?.rootViewController!.presentViewController(vc, animated: true, completion: nil)
                }
            } else if let msg = userInfo["aps"]!!["alert"] as? String {
                var titre = "Notification"
                var message = msg
                var array = msg.componentsSeparatedByString("\n")
                if array.count > 1 {
                    titre = array[0]
                    array.removeAtIndex(0)
                    message = array.joinWithSeparator("\n")
                }
                let alert = UIAlertController(title: titre, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                window?.rootViewController!.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
}


extension UINavigationController {
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
