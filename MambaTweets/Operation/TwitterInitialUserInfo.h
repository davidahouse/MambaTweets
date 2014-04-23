//
//  TwitterInitialUserInfo.h
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterAccount.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface TwitterInitialUserInfo : NSOperation

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore;

#pragma mark - Output Properties
@property (nonatomic,readonly) NSDictionary *tweetResponse;
@property (nonatomic,readonly) NSError *error;

@end
