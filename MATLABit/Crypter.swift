//
//  Crypter.swift
//  MATLABit
//
//  Created by Tomn on 07/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class Crypter: UITableViewController, UITextFieldDelegate {

    @IBOutlet var inField: UITextField!
    @IBOutlet var keyField: UITextField!
    @IBOutlet var outField: UITextField!
    @IBOutlet var btnChiffrer: UIButton!
    @IBOutlet var btnDechiffrer: UIButton!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard #available(iOS 9.1, *) else {
            btnChiffrer.setTitle("Chiffrer", forState: .Normal)
            btnDechiffrer.setTitle("Déchiffrer", forState: .Normal)
            return
        }
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return 1
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if outField.text == "" {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        let menuPartage = UIActivityViewController(activityItems: [outField.text!], applicationActivities: nil)
        menuPartage.title = "Partager le message chiffré"
        menuPartage.excludedActivityTypes = [UIActivityTypeAddToReadingList]
        
        if let pop = menuPartage.popoverPresentationController {
            pop.sourceView = tableView
            pop.sourceRect = tableView.cellForRowAtIndexPath(indexPath)!.frame
            pop.permittedArrowDirections = .Up
        }
        
        presentViewController(menuPartage, animated: true) {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    
    // MARK: - Text Field delegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        var text1 = inField.text
        var text2 = keyField.text
        let text = textField.text
        let newText = (text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        if textField == inField {
            text1 = newText
        }
        else {
            text2 = newText
        }
        
        let hex = "[0-9a-fA-F]+"
        let isHex = NSPredicate(format: "SELF MATCHES %@", hex)
        
        btnChiffrer.enabled   = text1 != "" && text2 != ""
        btnDechiffrer.enabled = isHex.evaluateWithObject(text1) && text2 != ""
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if inField.isFirstResponder() {
            keyField.becomeFirstResponder()
        }
        else {
            keyField.resignFirstResponder()
        }
        return false;
    }
    
    
    // MARK: - Chiffrement niveau zéro
    
    @IBAction func chiffrer() {
        inField.resignFirstResponder()
        keyField.resignFirstResponder()
        
        let in16 = Array(inField.text!.utf16)
        let ke16 = Array(keyField.text!.utf16)
        
        var j = 0
        var result = ""
        
        for inChar in in16 {
            let res = inChar ^ ke16[j]
            result += String(format: "%04X", res)
            
            j += 1
            if j == ke16.count {
                j = 0
            }
        }
        
        outField.text = result.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    @IBAction func dechiffrer() {
        inField.resignFirstResponder()
        keyField.resignFirstResponder()
        
        let original = inField.text!
        let nbrChar = original.characters.count / 4
        let ke16 = Array(keyField.text!.utf16)
        
        var j = 0
        var result = Array<UInt16>()
        
        for i in 0 ..< nbrChar {
            var originalChar: UInt32 = 0
            let range = original.startIndex.advancedBy(i * 4) ..< original.startIndex.advancedBy((i * 4) + 4)
            let hexPart = original.substringWithRange(range)
            let scanner = NSScanner(string: hexPart)
            scanner.scanHexInt(&originalChar)
            
            let res = UInt16(originalChar) ^ ke16[j]
            result.append(res)
            
            j += 1
            if j == ke16.count {
                j = 0
            }
        }
        
        let final = String(utf16CodeUnits: result, count: result.count)
        outField.text = final.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}
