//
//  BackgroundLoadHistoricalTweets.h
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//
#import <Accounts/Accounts.h>

@class TwitterAccount;

@interface BackgroundLoadHistoricalTweets : NSOperation

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore account:(TwitterAccount *)twitterAccount;

@end
