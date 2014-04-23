//
//  LoadOrCreateTwitterAccountModel.m
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "LoadOrCreateTwitterAccountModel.h"

@interface LoadOrCreateTwitterAccountModel()

#pragma mark - Properties
@property (nonatomic,strong) ACAccountStore *accountStore;

@end

@implementation LoadOrCreateTwitterAccountModel {
    TwitterAccount *_twitterAccount;
    BOOL _newAccount;
}

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore
{
    if ( self = [super init] ) {
        _accountStore = accountStore;
    }
    return self;
}

#pragma mark - NSOperation
- (void)main
{
    @autoreleasepool {
    
        if ( self.isCancelled ) {
            return;
        }
        
        if ( self.accountStore.accounts && [self.accountStore.accounts count] == 1) {

            ACAccount *authAccount = self.accountStore.accounts[0];
            TwitterAccount *account = [TwitterAccount MB_findWithKey:authAccount.username];
            if ( account ) {
                _twitterAccount = account;
                _newAccount = NO;
                NSLog(@"loaded existing account minID: %@ maxID: %@",account.minID,account.maxID);
            }
            else {
                
                TwitterAccount *newAccount = [[TwitterAccount alloc] init];
                newAccount.userName = authAccount.username;
                newAccount.totalTweets = @0;
                newAccount.totalFavorites = @0;
                newAccount.totalReplies = @0;
                newAccount.totalRetweets = @0;
                newAccount.minID = @"";
                newAccount.maxID = @"";
                newAccount.maxLoaded = @NO;
                [newAccount MB_save];
                _twitterAccount = newAccount;
                _newAccount = YES;
            }
        }
    }
}

@end
