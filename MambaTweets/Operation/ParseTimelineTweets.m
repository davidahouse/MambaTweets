//
//  ParseTimelineTweets.m
//  MambaTweets
//
//  Created by David House on 7/4/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "ParseTimelineTweets.h"
#import "ParseAndStoreTweet.h"

@interface ParseTimelineTweets()

#pragma mark - Properties
@property (nonatomic,strong) NSOperationQueue *parseQueue;

@end

@implementation ParseTimelineTweets

#pragma mark - Properties
- (NSOperationQueue *)parseQueue
{
    if ( !_parseQueue ) {
        _parseQueue = [[NSOperationQueue alloc] init];
    }
    return _parseQueue;
}

#pragma mark - NSOperation
- (void)main
{
    @autoreleasepool {
        
        if ( self.isCancelled ) {
            return;
        }
        
        NSMutableArray *parseOperations = [[NSMutableArray alloc] init];
        for ( NSDictionary *tweetDictionary in self.tweets ) {
            ParseAndStoreTweet *parseOp = [[ParseAndStoreTweet alloc] initWithTweetDictionary:tweetDictionary];
            [parseOperations addObject:parseOp];
        }
        
        [self.parseQueue addOperations:parseOperations waitUntilFinished:YES];
    }
}

- (void)cancel
{
    [self.parseQueue cancelAllOperations];
    [super cancel];
}

@end
