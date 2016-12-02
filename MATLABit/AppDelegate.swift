//
//  AppDelegate.swift
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var notifAfterLaunch: NSDictionary?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let appearance = UINavigationBar.appearance()
        appearance.barTintColor = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
        appearance.tintColor = UIColor(red: 0.9608, green: 0.9205, blue: 0.816, alpha: 1)
        appearance.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        window?.tintColor = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
        
        if !UserDefaults.standard.bool(forKey: "alreadyBeenLaunched") {
            _ = KeychainSwift().clear()
            UserDefaults.standard.set(true, forKey: "alreadyBeenLaunched")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(launchFinished), name: NSNotification.Name(rawValue: "launchFinished"), object: nil)
        
        if let notif = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary,
            let _ = notif["aps"] as? NSDictionary {
            notifAfterLaunch = notif
        }
        
        return true
    }
    
    func launchFinished() {
        let sb = UIStoryboard(name:"Main", bundle:nil)
        let vc = sb.instantiateInitialViewController()!
        UIView.transition(from: self.window!.rootViewController!.view, to: vc.view, duration: 0.7,
                                  options: [.transitionFlipFromLeft, .allowAnimatedContent, .layoutSubviews]) { (finished) in
            if finished {
                self.window!.rootViewController = vc
                if let notif = self.notifAfterLaunch {
                    Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.handleNotif(_:)), userInfo: notif, repeats: false)
                    self.notifAfterLaunch = nil
                }
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Foundation.Data) {
        if Data.isConnected() {
            let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
            var push = ""
            for i in 0..<deviceToken.count {
                push += String(format: "%02.2hhx", arguments: [tokenChars[i]])
            }
            
            if let login = KeychainSwift().get("login"),
               let passw = KeychainSwift().get("passw") {
               let body = ["client": login,
                            "password": passw,
                            "os": "IOS",
                            "token": push,
                            "hash": ("Erreur mémoire cache" + login + passw + "IOS" + push).sha256()]
                Data.sharedData.needsLoadingSpin(true)
                Data.JSONRequest(Data.sharedData.phpURLs["newPush"]!, on: nil, post: body) { (JSON) in
                    Data.sharedData.needsLoadingSpin(false)
                    UserDefaults.standard.setValue(push, forKey: "pushToken")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(handleNotif(_:)), userInfo: userInfo, repeats: false)
    }
    
    func handleNotif(_ timer: Timer) {
        let userInfo = timer.userInfo as! [String: AnyObject]
        if let action = userInfo["action"] as? Int {
            if action == 1 {
                if let matchData = userInfo["matchData"] as? [String: AnyObject] {
                    let sb = UIStoryboard(name:"Match", bundle:nil)
                    let vc = sb.instantiateInitialViewController() as! Match
                    vc.modalPresentationStyle = .overFullScreen
                    vc.setVisualData(matchData["img"] as? String, name: matchData["name"] as? String)
                    
                    window?.rootViewController!.present(vc, animated: true, completion: nil)
                }
            } else if let msg = userInfo["aps"]!["alert"] as? String {
                var titre = "Notification"
                var message = msg
                var array = msg.components(separatedBy: "\n")
                if array.count > 1 {
                    titre = array[0]
                    array.remove(at: 0)
                    message = array.joined(separator: "\n")
                }
                let alert = UIAlertController(title: titre, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                window?.rootViewController!.present(alert, animated: true, completion: nil)
            }
        }
    }
}


extension UINavigationController {
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
