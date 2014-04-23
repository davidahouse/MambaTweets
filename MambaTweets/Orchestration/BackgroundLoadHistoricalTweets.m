//
//  BackgroundLoadHistoricalTweets.m
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "BackgroundLoadHistoricalTweets.h"
#import "TwitterTimelineTweets.h"
#import "ParseAndStoreTweet.h"
#import "LoadTweetSummary.h"
#import "TwitterAccount.h"

@interface BackgroundLoadHistoricalTweets()

#pragma mark - Properties
@property (nonatomic,strong) ACAccountStore *accountStore;
@property (nonatomic,strong) TwitterAccount *twitterAccount;
@property (nonatomic,assign) NSUInteger parsedTweets;

@end

@implementation BackgroundLoadHistoricalTweets

#pragma mark - Class Methods
+ (void)startWithAccountStore:(ACAccountStore *)accountStore account:(TwitterAccount *)twitterAccount;
{
    BackgroundLoadHistoricalTweets *historyOperation = [[BackgroundLoadHistoricalTweets alloc] initWithAccountStore:accountStore account:twitterAccount];
    [[BackgroundLoadHistoricalTweets defaultOrchestrationQueue] addOperation:historyOperation];
}

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore account:(TwitterAccount *)twitterAccount
{
    if ( self = [super init] ) {
        _accountStore = accountStore;
        _twitterAccount = twitterAccount;
    }
    return self;
}

#pragma mark - NSOperation stuff
- (void)main
{
    @autoreleasepool {
    
        NSLog(@"Starting background load historical tweets...");
        
        // If we are cancelled, nothing to do
        if ( self.isCancelled ) {
            return;
        }
        
        // Start the first instance of loading past tweets based on our Max ID
        // start an operation to load the new tweets
        self.parsedTweets = 0;
        TwitterTimelineTweets *timelineOperation = [[TwitterTimelineTweets alloc] initWithAccountStore:self.accountStore forTwitterAccount:self.twitterAccount inDirection:@"old"];
        [self trackAndQueueOperation:timelineOperation withCompletion:@selector(timelineFinished:)];
    }
}

- (void)timelineFinished:(TwitterTimelineTweets *)timeline
{
    // If we had tweets, save the MaxID so we know where to start from the next call
    if ( timeline.tweets && [timeline.tweets count] > 0 ) {
        NSDictionary *lastTweet = [timeline.tweets lastObject];
        self.twitterAccount.maxID = lastTweet[@"id_str"];
        [self.twitterAccount MB_save];
    }
    
    // For each of the tweets, parse it from the JSON
    // and load it into our local store. Also we want
    // to keep track of a summary of the tweets.
    [self setCompletion:@selector(allTweetsParsed) group:[ParseAndStoreTweet class]];
    for ( NSDictionary *tweetDictionary in timeline.tweets ) {
        self.parsedTweets++;
        ParseAndStoreTweet *parseOp = [[ParseAndStoreTweet alloc] initWithTweetDictionary:tweetDictionary];
        [self trackAndQueueOperation:parseOp];
    }
}

- (void)allTweetsParsed
{
    // If we had received tweets on the last call
    if ( self.parsedTweets > 0 ) {
    
        // Fire off a summary
        LoadTweetSummary *summaryOperation = [[LoadTweetSummary alloc] initWithNotificationName:@"TIMELINESUMMARYNOTIFICATION" account:self.twitterAccount];
        [self trackAndQueueOperation:summaryOperation];

        // Also load more tweets!
        self.parsedTweets = 0;
        TwitterTimelineTweets *timelineOperation = [[TwitterTimelineTweets alloc] initWithAccountStore:self.accountStore forTwitterAccount:self.twitterAccount inDirection:@"old"];
        [self trackAndQueueOperation:timelineOperation withCompletion:@selector(timelineFinished:)];
    }
    else {
        // Assume we hit the end so we are done
    }
}


@end
