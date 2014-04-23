//
//  ParseAndStoreTweet.m
//  MambaTweets
//
//  Created by David House on 4/13/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "ParseAndStoreTweet.h"
#import "Tweet.h"

@interface ParseAndStoreTweet()

#pragma mark - Properties
@property (nonatomic,strong) NSDictionary *tweetDictionary;

@end

@implementation ParseAndStoreTweet

#pragma mark - Initialzer
- (id)initWithTweetDictionary:(NSDictionary *)tweetDictionary
{
    if ( self = [super init] ) {
        _tweetDictionary = tweetDictionary;
    }
    return self;
}

#pragma mark - NSOperation
- (void)main
{
    @autoreleasepool {
        
        if ( self.isCancelled ) {
            return;
        }
        
        Tweet *existing = [Tweet MB_findWithKey:self.tweetDictionary[@"id_str"]];
        if ( !existing ) {

            Tweet *newTweet = [[Tweet alloc] initWithJSON:self.tweetDictionary];
            [newTweet MB_save];
        }
    }
}

@end
