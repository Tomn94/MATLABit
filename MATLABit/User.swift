//
//  User.swift
//  MATLABit
//
//  Created by Tomn on 08/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class User: JAQBlurryTableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    private let nbrMaxConnectAttempts = 5
    private let imgSize: CGFloat = max(UIScreen.mainScreen().bounds.size.height, UIScreen.mainScreen().bounds.size.width) < 500 ? 120 : 170
    private let ph = ["lannistertyr", "snowjohn", "starkarya", "whitewalter", "pinkmanjesse", "swansonron", "nadirabed", "mccormickkenny", "foxmulder", "goodmansaul", "rothasher", "archersterling"]
    
    var emptyDataSetView: DZNEmptyDataSetView!
    @IBOutlet var connexionCell: UITableViewCell!
    @IBOutlet var idField: UITextField!
    @IBOutlet var mdpField: UITextField!
    @IBOutlet var spin: UIActivityIndicatorView!
    @IBOutlet var spinBtn: UIBarButtonItem!
    private var decoBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        decoBtn = UIBarButtonItem(title: "Déconnexion", style: .Plain, target: self, action: #selector(deconnexion))
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(viewWillAppear(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        chargerUI()
        reloadEmpty()
    }
    
    
    // MARK: - Actions
    
    func chargerUI() {
        let index = Int(arc4random_uniform(UInt32(ph.count)))
        idField.placeholder = ph[index]
        
        if !Data.isConnected() {
            navigationItem.setLeftBarButtonItems([spinBtn], animated: true)
            configureBannerWithImage(UIImage(named: "header"),
                                     blurRadius: 0, blurTintColor: UIColor.clearColor(), saturationFactor: 1, maxHeight: 157)
        } else {
            navigationItem.setLeftBarButtonItems([decoBtn], animated: true)
            configureBannerWithImage(nil)
        }
    }
    
    @IBAction func fermer() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func connexion() {
        idField.resignFirstResponder()
        mdpField.resignFirstResponder()
        
        let login = idField.text?.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
        let pass: NSString = mdpField.text!
        
        if login == "" || pass == "" {
            return
        }
        
        // Éviter le brute force et la surcharge
        var bug = false
        if let lastTry = Data.sharedData.connectionsTooMany {
            if NSDate.timeIntervalSinceReferenceDate() - lastTry <= 300 {
                bug = true
            }
        }
        else if Data.sharedData.connectionsAttempts >= nbrMaxConnectAttempts {
            Data.sharedData.connectionsTooMany = NSDate.timeIntervalSinceReferenceDate()
            bug = true
        }
        if bug {
            let alert = UIAlertController(title: "Doucement",
                                          message: "Veuillez attendre 5 minutes, vous avez réalisé trop de tentatives à la suite.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title:"Mince !", style: .Cancel, handler:nil))
            presentViewController(alert, animated:true, completion:nil)
            return;
        }
        
        // CONNEXION
        Data.sharedData.connectionsAttempts += 1
        
        connexionCell.textLabel?.enabled = false
        connexionCell.userInteractionEnabled = false
        connexionCell.selectionStyle = .None
        
        // Codage du mot de passe
        let passDec = NSMutableString()
        for i in 0 ..< pass.length {
            let ch = pass.characterAtIndex(i)
            passDec.appendFormat("%c", (unichar)(ch + 1))
        }
        let pass1: NSString = (pass.dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([]))!
        let pass2: NSString = (passDec.dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([]))!
        let passFinal = NSMutableString()
        for i in 0 ..< pass2.length {
            passFinal.appendFormat("%c%c", pass1.characterAtIndex(i), pass2.characterAtIndex(i))
        }
        let finPass = passFinal.length > 2 ? passFinal.substringFromIndex(passFinal.length - 2) : ""
        if finPass != "==" {
            passFinal.appendString("==")
        }
        
        let lePassFinal = "Oups, erreur de connexion\(pass)".sha256()
        
        // Envoi
        let hash = (login! + (passFinal as String) + "selfRetain_$_0x128D4_objc").sha256()
        let body: [String: String] = ["username": login!, "password": passFinal as String, "hash": hash]
        Data.JSONRequest(Data.sharedData.phpURLs["connect"]!, on: self, post: body) { (JSON) in
            var connecté = false
            if let json = JSON {
                let alert = UIAlertController(title: "Erreur inconnue",
                                              message: "Impossible de valider votre connexion.", preferredStyle: .Alert)
                if let status = json["status"] as? Int,
                    cause = json["cause"] as? String {
                    if status == 1 {
                        if let data = json["data"] as? [String: AnyObject],
                            username = data["username"] as? String,
                            info = data["info"] as? String {
                            let nom = username.componentsSeparatedByString(" ")[0]
                            var title = "Bienvenue \(nom) !"
                            if info.containsString("existe") {
                                title = "Hey, de retour, \(nom) !"
                            }
                            
                            connecté = true
                            Data.sharedData.connectionsAttempts = 0
                            Data.sharedData.connectionsTooMany = nil
                            
                            alert.title = title
                            alert.message = "MATLABit te souhaite beaucoup de fruits, de l'eau de source, du fun\n\nN'oublie pas de choisir une photo de profil !"
                            
                            Data.connect(login!, pass: lePassFinal, username: username)
                        }
                    } else if status == -2 {
                        alert.title = "Oups…"
                        alert.message = "Mauvaise combinaison identifiant/mot de passe.\nVeuillez vérifier vos informations, puis réessayer."
                    } else {
                        alert.title = "Erreur"
                        alert.message = cause
                    }
                }
                
                alert.addAction(UIAlertAction(title: connecté ? "OKLM 👌🏼" : "OK", style: .Cancel, handler: { (a) in
                    if connecté {
                        self.chargerUI()
                        self.tableView.reloadData()
                        self.reloadEmpty()
                    }
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
            self.spin.stopAnimating()
            self.connexionCell.textLabel!.enabled = true
            self.connexionCell.userInteractionEnabled = true
            self.connexionCell.selectionStyle = .Default
        }
        spin.startAnimating()
    }
    
    func deconnexion() {
        let alert = UIAlertController(title: "Veux-tu vraiment te déconnecter ?",
                                      message: "On s'amusait bien !", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Annuler", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Oui", style: .Default, handler: { (a) in
            
            let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
            if NSData(contentsOfFile: filePath) != nil {
                self.removePhoto()
            }
            
            Data.deconnect()
            
            self.chargerUI()
            self.tableView.reloadData()
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Photo
    
    func choosePhoto() {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
        if NSData(contentsOfFile: filePath) != nil {
            let alert = UIAlertController(title: "Changer l'image de profil", message: "", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Supprimer la photo", style: .Destructive, handler: { (a) in
                self.removePhoto()
            }))
            alert.addAction(UIAlertAction(title: "Choisir une photo", style: .Default, handler: { (a) in
                self.showPhotos()
            }))
            alert.addAction(UIAlertAction(title: "Annuler", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        } else {
            showPhotos()
        }
    }
    
    func removePhoto() {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtPath(filePath)
        } catch let error as NSError {
            let alert = UIAlertController(title: "Impossible de supprimer l'image",
                                          message: error.localizedDescription, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
        
        reloadEmpty()
    }
    
    func showPhotos() {
        if (UI_USER_INTERFACE_IDIOM() == .Pad)
        {
            let pop = UIImagePickerController()
            pop.sourceType = .PhotoLibrary
            pop.delegate = self
            let popOver = UIPopoverController(contentViewController: pop)
            popOver.presentPopoverFromRect(tableView.emptyDataSetView.imageView.convertRect(tableView.emptyDataSetView.imageView.bounds, toView: navigationController!.view), inView: view, permittedArrowDirections: .Any, animated: true)
        }
        else
        {
            let pop = UIImagePickerController()
            pop.sourceType = .PhotoLibrary
            pop.delegate = self
            presentViewController(pop, animated: true, completion: { 
                UIApplication.sharedApplication().statusBarStyle = .LightContent
            })
        }
    }
    
    
    // MARK: Image picker delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
        
        image = image.scaleAndCrop(CGSizeMake(imgSize, imgSize), retina: false, fit: false, opaque: true)
        let imageData = UIImagePNGRepresentation(image)
        imageData?.writeToFile(filePath, atomically: false)
        
        reloadEmpty()
        
        dismissViewControllerAnimated(true) {
            UIApplication.sharedApplication().statusBarStyle = .LightContent
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true) {
            UIApplication.sharedApplication().statusBarStyle = .LightContent
        }
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (Data.isConnected()) ? 0 : 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Data.isConnected() {
            return 0
        } else if section == 1 {
            return 1
        }
        return 2
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            connexion()
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    // MARK: - Text Field delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if idField.isFirstResponder() {
            return mdpField.becomeFirstResponder()
        } else {
            connexion()
        }
        return false
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text
        var proposedString: NSString = (text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        proposedString = proposedString.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
        let length = proposedString.length
        
        var prev1 = idField.text != ""
        var prev2 = mdpField.text != ""
        let prev  = prev1 && prev2
        if textField.tag > 0 {
            prev2 = length > 0
        } else {
            prev1 = length > 0
        }
        
        let nouv = prev1 && prev2
        if prev != nouv {
            connexionCell.textLabel?.enabled = nouv
            connexionCell.selectionStyle = (nouv) ? .Default : .None
        }
        
        if textField.tag > 0 {
            return true
        }
        
        return length <= 15
    }
    
    
    // MARK: - DZNEmptyDataSet
    
    func reloadEmpty() {
        tableView.reloadEmptyDataSet()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(choosePhoto))
        tableView.emptyDataSetView.imageView.userInteractionEnabled = true
        tableView.emptyDataSetView.imageView.addGestureRecognizer(tap)
        
        tableView.emptyDataSetView.imageView.layer.cornerRadius = CGFloat(imgSize / 2)
        tableView.emptyDataSetView.imageView.clipsToBounds = true
        tableView.emptyDataSetView.imageView.layer.borderWidth = 4
        tableView.emptyDataSetView.imageView.layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
        if let data = NSData(contentsOfFile: filePath) {
            return UIImage(data: data)
        }
        
        if UIScreen.mainScreen().bounds.size.height < 500 {
            return UIImage(named:"defaultUser")?.scaleAndCrop(CGSizeMake(imgSize, imgSize), retina: false, fit: false, opaque: true)
        }
        return UIImage(named:"defaultUser")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Salut \(KeychainSwift().get("uname")!) !"
        let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18),
                     NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17),
                     NSForegroundColorAttributeName: UINavigationBar.appearance().barTintColor!]
        var string = "Choisir une photo"
        if Data.hasProfilePic() {
            string = "Modifier ma photo"
        }
        return NSAttributedString(string: string, attributes: attrs)
    }
    
    func emptyDataSet(scrollView: UIScrollView!, didTapButton: UIButton!) {
        choosePhoto()
    }
}
