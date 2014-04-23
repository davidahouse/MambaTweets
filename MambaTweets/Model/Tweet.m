//
//  Tweet.m
//  MambaTweets
//
//  Created by David House on 4/12/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "Tweet.h"

@implementation Tweet

#pragma mark - Initializer
- (id)initWithJSON:(id)jsonObject
{
    if ( self = [super init] ) {
        _tweetID = jsonObject[@"id_str"];
        _source = jsonObject[@"source"];
        _text = jsonObject[@"text"];
        _createdAt = jsonObject[@"created_at"];
        _category = @"";
        if ( [jsonObject[@"favorite_count"] intValue] > 0 ) {
            _category = [_category stringByAppendingString:@"F"];
        }
        if ( jsonObject[@"in_reply_to_user_id_str"] && (jsonObject[@"in_reply_to_user_id_str"] != [NSNull null]) && ![jsonObject[@"in_reply_to_user_id_str"] isEqualToString:@""] ) {
            _category = [_category stringByAppendingString:@"R"];
        }
        if ( [jsonObject[@"retweet_count"] intValue] > 0 ) {
            _category = [_category stringByAppendingString:@"T"];
        }
    }
    return self;
}

#pragma mark - MambaObjectProperties protocol
- (NSString *)mambaObjectKey
{
    return self.tweetID;
}

- (NSString *)mambaObjectTitle
{
    return self.text;
}

- (NSString *)mambaObjectForeignKey
{
    return self.category;
}

@end
