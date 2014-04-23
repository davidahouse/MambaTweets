//
//  LoadTweetSummary.h
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TwitterAccount;

@interface LoadTweetSummary : NSOperation

#pragma mark - Properties

#pragma mark - Initializer
- (id)initWithNotificationName:(NSString *)notificationName account:(TwitterAccount *)account;

@end
