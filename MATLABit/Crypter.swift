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
        
        let original = inField.text!
        let clef = keyField.text!
        
        let charsM = Array(original.characters)
        let charsK = Array(clef.characters)
        
        var j = 0
        let result = NSMutableString()
        
        for charM in charsM {
            let charMUTF = String(charM).utf16
            let charKUTF = String(charsK[j]).utf16
            let res = charMUTF[charMUTF.startIndex] ^ charKUTF[charKUTF.startIndex]
            j += 1
            if j == charsK.count {
                j = 0
            }
            
            result.appendFormat("%04X", res)
        }
        
        outField.text = result.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    @IBAction func dechiffrer() {
        inField.resignFirstResponder()
        keyField.resignFirstResponder()
        
        let original: NSString = inField.text!
        let clef = keyField.text!
        
        let nbrChar = original.length / 4
        let charsK = Array(clef.characters)
        
        var j = 0
        let result = NSMutableString()
        
        for i in 0 ..< nbrChar {
            var originalChar: UInt32 = 0
            let hexPart = original.substringWithRange(NSMakeRange(i * 4, 4))
            let scanner = NSScanner(string: hexPart)
            scanner.scanHexInt(&originalChar)
            
            let charKUTF = String(charsK[j]).utf16
            let charK16: UInt16 = charKUTF[charKUTF.startIndex]
            let originalChar16: UInt16 = UInt16(originalChar)
            let res = originalChar16 ^ charK16
            
            j += 1
            if j == charsK.count {
                j = 0
            }
            
            result.appendFormat("%c", res)
        }
        
        outField.text = result.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}
