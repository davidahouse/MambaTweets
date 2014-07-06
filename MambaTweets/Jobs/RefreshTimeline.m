//
//  RefreshTimeline.m
//  MambaTweets
//
//  Created by David House on 4/12/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "RefreshTimeline.h"
#import "TwitterAuthorized.h"
#import "TwitterTimelineTweets.h"
#import "ParseAndStoreTweet.h"
#import "LoadOrCreateTwitterAccountModel.h"
#import "TwitterInitialUserInfo.h"
#import "TwitterAccount.h"
#import "Tweet.h"
#import "LoadTweetSummary.h"
#import "BackgroundLoadHistoricalTweets.h"
#import "DownloadTwitterProfileIcon.h"
#import "ParseTimelineTweets.h"

const NSString *kTimelineSummaryNotification = @"TIMELINESUMMARYNOTIFICATION";
const NSString *kIconFinishedDownloadNotification = @"ICONFINISHEDDOWNLOADNOTIFICATION";

@interface RefreshTimeline()

#pragma mark - Properties
@property (nonatomic,strong) ACAccountStore *accountStore;
@property (nonatomic,strong) TwitterAccount *twitterAccount;
@property (nonatomic,strong) NSOperationQueue *childQueue;
@property (nonatomic,strong) NSOperationQueue *parseQueue;

@property (nonatomic,assign,getter = isDone) BOOL done;
@property (nonatomic,assign,getter = isHistoryDone) BOOL historyDone;
@property (nonatomic,assign,getter = isIconDone) BOOL iconDone;

#pragma mark - Child Operations
@property (nonatomic,strong) TwitterAuthorized *twitterAuthorizedOperation;
@property (nonatomic,strong) LoadOrCreateTwitterAccountModel *loadAccountOperation;
@property (nonatomic,strong) TwitterInitialUserInfo *twitterInitialUserOperation;
@property (nonatomic,strong) TwitterTimelineTweets *twitterTimelineOperation;
@property (nonatomic,strong) ParseTimelineTweets *parseTweetsOperation;
@property (nonatomic,strong) LoadTweetSummary *finalSummaryOperation;
@property (nonatomic,strong) BackgroundLoadHistoricalTweets *historicalOperation;
@property (nonatomic,strong) DownloadTwitterProfileIcon *profileIconOperation;

@end

@implementation RefreshTimeline {
    BOOL _authorized;
}

#pragma mark - Class Methods
+ (RefreshTimeline *)startRefreshJob
{
    NSOperationQueue *refreshQueue = [[NSOperationQueue alloc] init];
    RefreshTimeline *refreshJob = [[RefreshTimeline alloc] init];
    [refreshQueue addOperation:refreshJob];
    return refreshJob;
}

#pragma mark - Properties
- (NSOperationQueue *)childQueue
{
    if ( !_childQueue ) {
        _childQueue = [[NSOperationQueue alloc] init];
    }
    return _childQueue;
}

- (NSOperationQueue *)parseQueue
{
    if ( !_parseQueue ) {
        _parseQueue = [[NSOperationQueue alloc] init];
    }
    return _parseQueue;
}

#pragma mark - NSOperation stuff
- (void)start
{
    if ( self.isCancelled ) {
        return;
    }
    
    self.done = NO;
    self.historyDone = NO;
    self.iconDone = NO;
    
    // Start with getting authorized to use twitter
    self.twitterAuthorizedOperation = [[TwitterAuthorized alloc] init];
    __weak typeof(self) weakself = self;
    [self.twitterAuthorizedOperation setCompletionBlock:^{
        [weakself authorizationFinished];
    }];
    [self.childQueue addOperation:self.twitterAuthorizedOperation];
}

- (BOOL)isFinished
{
    return self.done && self.historyDone && self.iconDone;
}

- (BOOL)isExecuting
{
    return !self.done || !self.historyDone || !self.iconDone;
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
    self.historyDone = YES;
    self.iconDone = YES;
    [self didChangeValueForKey:@"isFinished"];
}


#pragma mark - Private Methods
- (void)authorizationFinished
{
    if ( self.twitterAuthorizedOperation.authorizedState == TwitterAuthorizedStateGranted ) {
        _authorized = YES;
        NSLog(@"operation finished and we have twitter access!");
        
        // Save the account store, we will need it later
        self.accountStore = self.twitterAuthorizedOperation.accountStore;
        
        // Load the twitter account from our storage
        self.loadAccountOperation = [[LoadOrCreateTwitterAccountModel alloc] initWithAccountStore:self.accountStore];
        __weak typeof(self) weakself = self;
        [self.loadAccountOperation setCompletionBlock:^{
            [weakself accountLoaded];
        }];
        [self.childQueue addOperation:self.loadAccountOperation];
    }
    else {
        NSLog(@"uh oh, we aren't authorized for twitter");
        _authorized = NO;
    }
}

- (void)accountLoaded
{
    // If we didn't get an account, something bad happened
    if ( !self.loadAccountOperation.twitterAccount ) {
        NSLog(@"newAccount not found");
        _authorized = NO;
    }
    else {
        self.twitterAccount = self.loadAccountOperation.twitterAccount;
        
        // If a new account, we need to execute the TwitterInitialUserInfo task before continuing
        if ( self.loadAccountOperation.isNewAccount ) {
            NSLog(@"new account, starting the initial user info task");
            self.twitterInitialUserOperation = [[TwitterInitialUserInfo alloc] initWithAccountStore:self.accountStore];
            __weak typeof(self) weakself = self;
            [self.twitterInitialUserOperation setCompletionBlock:^{
                [weakself initialLoadFinished];
            }];
            [self.childQueue addOperation:self.twitterInitialUserOperation];
        }
        else {
            NSLog(@"not a new account, we can go ahead and start the loads");
            [self startTweetLoading];
        }
    }
}

- (void)startTweetLoading
{
    // Go ahead and build our first summary
    __weak typeof(self) weakself = self;
    LoadTweetSummary *loadTweetSummaryOperation = [[LoadTweetSummary alloc] initWithNotificationName:(NSString *)kTimelineSummaryNotification account:self.twitterAccount];
    [self.childQueue addOperation:loadTweetSummaryOperation];
    
    // start an operation to load the new tweets
    self.twitterTimelineOperation = [[TwitterTimelineTweets alloc] initWithAccountStore:self.accountStore forTwitterAccount:self.twitterAccount inDirection:@"new"];
    [self.twitterTimelineOperation setCompletionBlock:^{
        [weakself timelineFinished];
    }];
    [self.childQueue addOperation:self.twitterTimelineOperation];
    
    // start another orchestration for loading the old tweets (this could take a while!)
    self.historicalOperation = [[BackgroundLoadHistoricalTweets alloc] initWithAccountStore:self.accountStore account:self.twitterAccount];
    [self.historicalOperation setCompletionBlock:^{
        [weakself historyDone];
    }];
    [self.childQueue addOperation:self.historicalOperation];
    
    // Check to see if we have the twitter icon downloaded
    if ( ![self.twitterAccount localIconFound] ) {
        self.profileIconOperation = [[DownloadTwitterProfileIcon alloc] initWithTwitterAccount:self.twitterAccount notification:(NSString *)kIconFinishedDownloadNotification];
        [self.profileIconOperation setCompletionBlock:^{
            [weakself iconDone];
        }];
        [self.childQueue addOperation:self.profileIconOperation];
    }
    else {
        self.iconDone = YES;
    }
}

- (void)initialLoadFinished
{
    NSLog(@"initial info finished!");
    
    // save the user info to the account
    self.twitterAccount.iconURL = self.twitterInitialUserOperation.tweetResponse[@"user"][@"profile_image_url_https"];
    self.twitterAccount.maxID = self.twitterInitialUserOperation.tweetResponse[@"id_str"];
    self.twitterAccount.minID = self.twitterInitialUserOperation.tweetResponse[@"id_str"];
    [self.twitterAccount MB_save];
    
    // save the first tweet
    Tweet *existing = [Tweet MB_findWithKey:self.twitterInitialUserOperation.tweetResponse[@"id_str"]];
    if ( !existing ) {
        
        Tweet *newTweet = [[Tweet alloc] initWithJSON:self.twitterInitialUserOperation.tweetResponse];
        [newTweet MB_save];
    }
    
    [self startTweetLoading];
}

- (void)timelineFinished
{
    // For each of the tweets, parse it from the JSON
    // and load it into our local store. Also we want
    // to keep track of a summary of the tweets.
    __weak typeof(self) weakself = self;
    self.parseTweetsOperation = [[ParseTimelineTweets alloc] init];
    self.parseTweetsOperation.tweets = self.twitterTimelineOperation.tweets;
    [self.parseTweetsOperation setCompletionBlock:^{
        [weakself allTweetsParsed];
    }];
    [self.childQueue addOperation:self.parseTweetsOperation];
}

- (void)allTweetsParsed
{
    self.finalSummaryOperation = [[LoadTweetSummary alloc] initWithNotificationName:(NSString *)kTimelineSummaryNotification account:self.twitterAccount];
    __weak typeof(self) weakself = self;
    [self.finalSummaryOperation setCompletionBlock:^{
        [weakself operationDone];
    }];
    [self.childQueue addOperation:self.finalSummaryOperation];
}

- (void)operationDone
{
    NSLog(@"operationDone...");
    [self willChangeValueForKey:@"isFinished"];
    self.done = YES;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)historyDone
{
    NSLog(@"historyDone...");
    [self willChangeValueForKey:@"isFinished"];
    self.historyDone = YES;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)iconDone
{
    NSLog(@"iconDone...");
    [self willChangeValueForKey:@"isFinished"];
    self.iconDone = YES;
    [self didChangeValueForKey:@"isFinished"];
}

@end
