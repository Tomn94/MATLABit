//
//  Crypt.m
//  MATLABit
//
//  Created by Tomn on 07/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

#import "Crypt.h"

@implementation Crypt

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _inField.delegate = self;
    _keyField.delegate = self;
    
    _btnChiffrer.enabled = NO;
    _btnDechiffrer.enabled = NO;
}

#pragma mark - Text Field delegate

- (BOOL)            textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
            replacementString:(NSString *)string
{
    NSString *text1 = _inField.text;
    NSString *text2 = _keyField.text;
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if ([textField isEqual:_inField])
        text1 = newText;
    else
        text2 = newText;
    
    NSString *hex = @"[0-9a-fA-F]+";
    NSPredicate *isHex = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", hex];
    
    _btnChiffrer.enabled   = ![text1 isEqualToString:@""] && ![text2 isEqualToString:@""];
    _btnDechiffrer.enabled = [isHex evaluateWithObject:text1] && ![text2 isEqualToString:@""];
    
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if ([_inField isFirstResponder])
        [_keyField becomeFirstResponder];
    else
        [_keyField resignFirstResponder];
    
    return NO;
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    if (!section)
        return 2;
    return 1;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIActivityViewController *menuPartage = [[UIActivityViewController alloc] initWithActivityItems:@[_outField.text]
                                                                              applicationActivities:nil];
    
    [menuPartage setTitle:@"Partager le message chiffré"];
    [menuPartage setExcludedActivityTypes:@[UIActivityTypeAddToReadingList]];

    [self presentViewController:menuPartage animated:YES completion:^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}

#pragma mark - Chiffrement niveau zéro

- (IBAction) chiffrer:(id)sender
{
    NSString *original = _inField.text;
    NSString *clef     = _keyField.text;
    
    NSUInteger lenM = [original length];
    unichar bufferM[lenM + 1];
    [original getCharacters:bufferM range:NSMakeRange(0, lenM)];
    
    NSUInteger lenK = [clef length];
    unichar bufferK[lenK + 1];
    [clef getCharacters:bufferK range:NSMakeRange(0, lenK)];
    
    unsigned int j = 0;
    NSMutableString *result = [NSMutableString stringWithString:@""];
    
    for (unsigned int i = 0 ; i < lenM ; i++)
    {
        unichar res = bufferM[i] ^ bufferK[j];
        j++;
        if (j == lenK)
            j = 0;
        
        [result appendFormat:@"%04X", res];
    }
    
    _outField.text = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (IBAction) dechiffrer:(id)sender
{
    NSString *original = _inField.text;
    NSString *clef     = _keyField.text;
    
    NSUInteger nbrChar = [original length] / 4;
    NSUInteger lenK = [clef length];
    unichar bufferK[lenK + 1];
    [clef getCharacters:bufferK range:NSMakeRange(0, lenK)];
    
    unsigned int j = 0;
    NSMutableString *result = [NSMutableString stringWithString:@""];
    for (unsigned int i = 0 ; i < nbrChar ; i++)
    {
        unsigned int originalChar = 0;
        NSString *hexPart = [original substringWithRange:NSMakeRange(i * 4, 4)];
        NSScanner *scanner = [NSScanner scannerWithString:hexPart];
        [scanner scanHexInt:&originalChar];
        
        unichar res = originalChar ^ bufferK[j];
        j++;
        if (j == lenK)
            j = 0;
        
        [result appendFormat:@"%c", res];
    }
    
    _outField.text = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end
