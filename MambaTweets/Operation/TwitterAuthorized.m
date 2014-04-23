//
//  TwitterAuthorized.m
//  MambaTweets
//
//  Created by David House on 4/12/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "TwitterAuthorized.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface TwitterAuthorized()

@property (nonatomic,assign,getter = isAuthFinished) BOOL authFinished;

@end

@implementation TwitterAuthorized

- (void)main
{
    @autoreleasepool {
        
        self.authFinished = NO;
        
        // Don't bother if we are cancelled
        if ( self.isCancelled ) {
            self.authFinished = YES;
            return;
        }
        
        NSLog(@"TwitterAuthorized started...");
        
        if ( [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter] ) {
            
            NSLog(@"twitter is authorized!");
            _accountStore = [[ACAccountStore alloc] init];
            ACAccountType *twitterAccountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

            [_accountStore requestAccessToAccountsWithType:twitterAccountType options:NULL completion:^(BOOL granted, NSError *error) {

                
                if ( granted ) {
                    NSLog(@"TwitterAuthorized and granted!");
                    
                    for ( ACAccount *account in _accountStore.accounts ) {
                        NSLog(@"account: %@ %@",account.username,account.userFullName);
                    }
                    
                    _authorizedState = TwitterAuthorizedStateGranted;
                }
                else {
                    NSLog(@"Error getting twitter access: %@",error);
                    _authorizedState = TwitterAuthorizedStateError;
                }
                [self willChangeValueForKey:@"isFinished"];
                self.authFinished = YES;
                [self didChangeValueForKey:@"isFinished"];
            }];
            
        }
        else {
            
            NSLog(@"twitter is not authorized!");
            _authorizedState = TwitterAuthorizedStateError;
            [self willChangeValueForKey:@"isFinished"];
            self.authFinished = YES;
            [self didChangeValueForKey:@"isFinished"];
        }
    }
}

- (BOOL)isFinished
{
    return self.authFinished;
}

@end
