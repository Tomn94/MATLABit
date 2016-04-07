//
//  Crypt.h
//  MATLABit
//
//  Created by Tomn on 07/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;

@interface Crypt : UITableViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *inField;
@property (weak, nonatomic) IBOutlet UITextField *keyField;
@property (weak, nonatomic) IBOutlet UITextField *outField;
@property (weak, nonatomic) IBOutlet UIButton *btnChiffrer;
@property (weak, nonatomic) IBOutlet UIButton *btnDechiffrer;

- (IBAction) chiffrer:(id)sender;
- (IBAction) dechiffrer:(id)sender;

@end
