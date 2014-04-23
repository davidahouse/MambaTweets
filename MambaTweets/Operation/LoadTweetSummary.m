//
//  LoadTweetSummary.m
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "LoadTweetSummary.h"
#import "TwitterAccount.h"
#import "Tweet.h"

@interface LoadTweetSummary()

#pragma mark - Properties
@property (nonatomic,strong) NSString *notificationName;
@property (nonatomic,strong) TwitterAccount *account;

@end

@implementation LoadTweetSummary

#pragma mark - Initializer
- (id)initWithNotificationName:(NSString *)notificationName account:(TwitterAccount *)account
{
    if ( self = [super init] ) {
        _notificationName = notificationName;
        _account = account;
    }
    return self;
}

#pragma mark - NSOperation
- (void)main
{
    @autoreleasepool {
    
        // Count how many tweets in the db
        self.account.totalTweets = [Tweet MB_countAll];
        
        // Count the number of favorites
        self.account.totalFavorites = [Tweet MB_countLikeForeignKey:@"F"];
        
        // Count the number of replies
        self.account.totalReplies = [Tweet MB_countLikeForeignKey:@"R"];
        
        // Count the number of retweets
        self.account.totalRetweets = [Tweet MB_countLikeForeignKey:@"T"];
        
        // and save
        [self.account MB_save];
        
        // Now fire off the notification
        [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationName object:nil userInfo:nil];
    }
}

@end
