//
//  LoadOrCreateTwitterAccountModel.h
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "TwitterAccount.h"

@interface LoadOrCreateTwitterAccountModel : NSOperation

#pragma mark - Output Properties
@property (nonatomic,readonly) TwitterAccount *twitterAccount;
@property (nonatomic,readonly,getter = isNewAccount) BOOL newAccount;

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore;


@end
