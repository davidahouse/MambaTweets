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

const NSString *kTimelineSummaryNotification = @"TIMELINESUMMARYNOTIFICATION";
const NSString *kIconFinishedDownloadNotification = @"ICONFINISHEDDOWNLOADNOTIFICATION";

@interface RefreshTimeline()

#pragma mark - Properties
@property (nonatomic,strong) ACAccountStore *accountStore;
@property (nonatomic,strong) TwitterAccount *twitterAccount;

@end

@implementation RefreshTimeline {
    BOOL _authorized;
}

#pragma mark - NSOperation stuff
- (void)main
{
    // Start with getting authorized to use twitter
    TwitterAuthorized *twitterAuthorized = [[TwitterAuthorized alloc] init];
    [self trackAndQueueTask:twitterAuthorized withCompletion:@selector(authorizationFinished:)];
}

#pragma mark - Private Methods
- (void)authorizationFinished:(TwitterAuthorized *)auth
{
    if ( auth.authorizedState == TwitterAuthorizedStateGranted ) {
        _authorized = YES;
        NSLog(@"operation finished and we have twitter access!");
        
        // Save the account store, we will need it later
        self.accountStore = auth.accountStore;
        
        // Load the twitter account from our storage
        LoadOrCreateTwitterAccountModel *loadOperation = [[LoadOrCreateTwitterAccountModel alloc] initWithAccountStore:auth.accountStore];
        [self trackAndQueueTask:loadOperation withCompletion:@selector(accountLoaded:)];
    }
    else {
        NSLog(@"uh oh, we aren't authorized for twitter");
        _authorized = NO;
    }
}

- (void)accountLoaded:(LoadOrCreateTwitterAccountModel *)loadOperation
{
    // If we didn't get an account, something bad happened
    if ( !loadOperation.twitterAccount ) {
        NSLog(@"newAccount not found");
        _authorized = NO;
    }
    else {
        self.twitterAccount = loadOperation.twitterAccount;
        
        // If a new account, we need to execute the TwitterInitialUserInfo task before continuing
        if ( loadOperation.isNewAccount ) {
            NSLog(@"new account, starting the initial user info task");
            TwitterInitialUserInfo *initialInfo = [[TwitterInitialUserInfo alloc] initWithAccountStore:self.accountStore];
            [self trackAndQueueTask:initialInfo withCompletion:@selector(initialLoadFinished:)];
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
    LoadTweetSummary *summaryOperation = [[LoadTweetSummary alloc] initWithNotificationName:(NSString *)kTimelineSummaryNotification account:self.twitterAccount];
    [self trackAndQueueTask:summaryOperation];
    
    // start an operation to load the new tweets
    TwitterTimelineTweets *timelineOperation = [[TwitterTimelineTweets alloc] initWithAccountStore:self.accountStore forTwitterAccount:self.twitterAccount inDirection:@"new"];
    [self trackAndQueueTask:timelineOperation withCompletion:@selector(timelineFinished:)];
    
    // start another orchestration for loading the old tweets (this could take a while!)
    BackgroundLoadHistoricalTweets *backgroundOrchestration = [[BackgroundLoadHistoricalTweets alloc] initWithAccountStore:self.accountStore account:self.twitterAccount];
    [self trackAndQueueTask:backgroundOrchestration];
    
    // Check to see if we have the twitter icon downloaded
    if ( ![self.twitterAccount localIconFound] ) {
        DownloadTwitterProfileIcon *downloadIcon = [[DownloadTwitterProfileIcon alloc] initWithTwitterAccount:self.twitterAccount notification:(NSString *)kIconFinishedDownloadNotification];
        [self trackAndQueueTask:downloadIcon];
    }
}

- (void)initialLoadFinished:(TwitterInitialUserInfo *)initialInfo
{
    NSLog(@"initial info finished!");
    
    // save the user info to the account
    self.twitterAccount.iconURL = initialInfo.tweetResponse[@"user"][@"profile_image_url_https"];
    self.twitterAccount.maxID = initialInfo.tweetResponse[@"id_str"];
    self.twitterAccount.minID = initialInfo.tweetResponse[@"id_str"];
    [self.twitterAccount MB_save];
    
    // save the first tweet
    Tweet *existing = [Tweet MB_findWithKey:initialInfo.tweetResponse[@"id_str"]];
    if ( !existing ) {
        
        Tweet *newTweet = [[Tweet alloc] initWithJSON:initialInfo.tweetResponse];
        [newTweet MB_save];
    }
    
    [self startTweetLoading];
}

- (void)timelineFinished:(TwitterTimelineTweets *)timeline
{
    // For each of the tweets, parse it from the JSON
    // and load it into our local store. Also we want
    // to keep track of a summary of the tweets.
    [self setCompletion:@selector(allTweetsParsed) group:[ParseAndStoreTweet class]];
    for ( NSDictionary *tweetDictionary in timeline.tweets ) {
        ParseAndStoreTweet *parseOp = [[ParseAndStoreTweet alloc] initWithTweetDictionary:tweetDictionary];
        [self trackAndQueueTask:parseOp];
    }
}

- (void)allTweetsParsed
{
    LoadTweetSummary *summaryOperation = [[LoadTweetSummary alloc] initWithNotificationName:(NSString *)kTimelineSummaryNotification account:self.twitterAccount];
    [self trackAndQueueTask:summaryOperation];
}

@end
