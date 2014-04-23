//
//  ParseAndStoreTweet.h
//  MambaTweets
//
//  Created by David House on 4/13/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParseAndStoreTweet : NSOperation

#pragma mark - Initialzer
- (id)initWithTweetDictionary:(NSDictionary *)tweetDictionary;

#pragma mark - Properties

@end
