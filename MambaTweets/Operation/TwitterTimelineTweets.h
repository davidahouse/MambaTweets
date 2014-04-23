//
//  TwitterTimelineTweets.h
//  MambaTweets
//
//  Created by David House on 4/12/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@class TwitterAccount;

@interface TwitterTimelineTweets : NSOperation

#pragma mark - Output Properties
@property (nonatomic,readonly) NSArray *tweets;
@property (nonatomic,strong) NSString *inDirection;

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore forTwitterAccount:(TwitterAccount *)account inDirection:(NSString *)direction;

@end
