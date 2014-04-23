//
//  ViewController.m
//  MambaTweets
//
//  Created by David House on 4/12/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "ViewController.h"
#import "RefreshTimeline.h"
#import "TwitterAccount.h"

@interface ViewController ()

#pragma mark - Properties
@property (nonatomic,strong) TwitterAccount *account;
@property (nonatomic,assign) BOOL isRefreshing;

#pragma mark - IBOutlet
@property (weak, nonatomic) IBOutlet UIImageView *twitterIcon;
@property (weak, nonatomic) IBOutlet UILabel *twitterHandle;
@property (weak, nonatomic) IBOutlet UILabel *tweetCount;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *refreshActivity;
@property (weak, nonatomic) IBOutlet UILabel *favoriteCount;
@property (weak, nonatomic) IBOutlet UILabel *replyCount;
@property (weak, nonatomic) IBOutlet UILabel *retweetCount;

#pragma mark - IBAction
- (IBAction)refreshPressed:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:(NSString *)kTimelineNotAuthorizedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        NSLog(@"got a not authorized notification!");
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:(NSString *)kTimelineSummaryNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        [self reloadAccountData];
        
        NSLog(@"got a summary notification!");
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:(NSString *)kTimelineFinishedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    
        NSLog(@"refresh finished");
        self.isRefreshing = NO;
        [self.refreshActivity stopAnimating];
        [self.refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:(NSString *)kIconFinishedDownloadNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        [self refreshUI];
    }];

    // load any existing data that is already in the database
    [self reloadAccountData];
    
    // Kick off an initial refresh
    self.isRefreshing = YES;
    [self.refreshButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.refreshActivity startAnimating];
    [RefreshTimeline startRefresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods
- (void)reloadAccountData
{
    NSArray *accounts = [TwitterAccount MB_findAll];
    if ( accounts && [accounts count] > 0 ) {
        self.account = accounts[0];
    }
    
    // make sure UI updates are on the main thread
    [self refreshUI];
}

- (void)refreshUI
{
    if ( self.account ) {
        self.twitterHandle.text = self.account.userName;
        self.tweetCount.text = [NSString stringWithFormat:@"%@ tweet(s)",self.account.totalTweets];
        self.favoriteCount.text = [NSString stringWithFormat:@"%@ favorite(s)",self.account.totalFavorites];
        self.replyCount.text = [NSString stringWithFormat:@"%@ replies(s)",self.account.totalReplies];
        self.retweetCount.text = [NSString stringWithFormat:@"%@ retweets(s)",self.account.totalRetweets];

        if ( [self.account localIconFound] ) {
            self.twitterIcon.image = [UIImage imageWithContentsOfFile:[self.account localIconPath]];
        }
    }
}

- (IBAction)refreshPressed:(id)sender {
    
    if ( self.isRefreshing ) {
        // actually this is a cancel!
        self.isRefreshing = NO;
        [RefreshTimeline cancelOrchestration];
        [self.refreshActivity stopAnimating];
        [self.refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    }
    else {
        // now this is a refresh
        self.isRefreshing = YES;
        [self.refreshButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [self.refreshActivity startAnimating];
        [RefreshTimeline startRefresh];
    }
}

@end
