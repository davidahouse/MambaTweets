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
#import "ParseTimelineTweets.h"

@interface BackgroundLoadHistoricalTweets()

#pragma mark - Properties
@property (nonatomic,strong) ACAccountStore *accountStore;
@property (nonatomic,strong) TwitterAccount *twitterAccount;
@property (nonatomic,assign) NSUInteger parsedTweets;

@property (nonatomic,assign,getter = isDone) BOOL done;
@property (nonatomic,strong) TwitterTimelineTweets *timelineOperation;
@property (nonatomic,strong) NSOperationQueue *childQueue;
@property (nonatomic,strong) ParseTimelineTweets *parseTweetsOperation;

@end

@implementation BackgroundLoadHistoricalTweets

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore account:(TwitterAccount *)twitterAccount
{
    if ( self = [super init] ) {
        _accountStore = accountStore;
        _twitterAccount = twitterAccount;
    }
    return self;
}

#pragma mark - Properties
- (NSOperationQueue *)childQueue
{
    if ( !_childQueue ) {
        _childQueue = [[NSOperationQueue alloc] init];
    }
    return _childQueue;
}

#pragma mark - NSOperation stuff
- (void)start
{
    @autoreleasepool {
        
        NSLog(@"Starting background load historical tweets...");
        
        // If we are cancelled, nothing to do
        if ( self.isCancelled ) {
            return;
        }
        
        self.done = NO;
        
        // Start the first instance of loading past tweets based on our Max ID
        // start an operation to load the new tweets
        self.parsedTweets = 0;
        self.timelineOperation = [[TwitterTimelineTweets alloc] initWithAccountStore:self.accountStore forTwitterAccount:self.twitterAccount inDirection:@"old"];
        __weak typeof(self) weakself = self;
        [self.timelineOperation setCompletionBlock:^{
            [weakself timelineFinished];
        }];
        [self.childQueue addOperation:self.timelineOperation];
    }
}

- (BOOL)isFinished
{
    return self.done;
}

- (BOOL)isExecuting
{
    return !self.done;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (void)cancel
{
    [super cancel];
    
    [self.childQueue cancelAllOperations];
    
    [self willChangeValueForKey:@"isFinished"];
    self.done = YES;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)timelineFinished
{
    // If we had tweets, save the MaxID so we know where to start from the next call
    if ( self.timelineOperation.tweets && [self.timelineOperation.tweets count] > 0 ) {
        NSDictionary *lastTweet = [self.timelineOperation.tweets lastObject];
        
        // If the maxID is already the same, we have reached the end, so we should just stop anyway
        if ( [self.twitterAccount.maxID isEqualToString:lastTweet[@"id_str"]] ) {
            [self willChangeValueForKey:@"isFinished"];
            self.done = YES;
            [self didChangeValueForKey:@"isFinished"];
            return;
        }
        
        self.twitterAccount.maxID = lastTweet[@"id_str"];
        [self.twitterAccount MB_save];
    }
    
    // For each of the tweets, parse it from the JSON
    // and load it into our local store. Also we want
    // to keep track of a summary of the tweets.
    __weak typeof(self) weakself = self;
    self.parseTweetsOperation = [[ParseTimelineTweets alloc] init];
    self.parseTweetsOperation.tweets = self.timelineOperation.tweets;
    self.parsedTweets = [self.timelineOperation.tweets count];
    [self.parseTweetsOperation setCompletionBlock:^{
        [weakself allTweetsParsed];
    }];
    [self.childQueue addOperation:self.parseTweetsOperation];
}

- (void)allTweetsParsed
{
    // If we had received tweets on the last call
    if ( self.parsedTweets > 0 ) {
    
        // Fire off a summary
        LoadTweetSummary *summaryOperation = [[LoadTweetSummary alloc] initWithNotificationName:@"TIMELINESUMMARYNOTIFICATION" account:self.twitterAccount];
        [self.childQueue addOperation:summaryOperation];

        // Also load more tweets!
        self.parsedTweets = 0;
        self.timelineOperation = [[TwitterTimelineTweets alloc] initWithAccountStore:self.accountStore forTwitterAccount:self.twitterAccount inDirection:@"old"];
        __weak typeof(self) weakself = self;
        [self.timelineOperation setCompletionBlock:^{
            [weakself timelineFinished];
        }];
        [self.childQueue addOperation:self.timelineOperation];
    }
    else {
        // Assume we hit the end so we are done
        [self willChangeValueForKey:@"isFinished"];
        self.done = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
}


@end
