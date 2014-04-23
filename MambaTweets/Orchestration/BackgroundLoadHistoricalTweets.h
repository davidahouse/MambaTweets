//
//  BackgroundLoadHistoricalTweets.h
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "RAOrchestration.h"
#import <Accounts/Accounts.h>

@class TwitterAccount;

@interface BackgroundLoadHistoricalTweets : RAOrchestration

#pragma mark - Class methods
+ (void)startWithAccountStore:(ACAccountStore *)accountStore account:(TwitterAccount *)twitterAccount;

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore account:(TwitterAccount *)twitterAccount;

@end
