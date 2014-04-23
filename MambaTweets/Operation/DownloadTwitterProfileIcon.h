//
//  DownloadTwitterProfileIcon.h
//  MambaTweets
//
//  Created by David House on 4/21/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TwitterAccount;

@interface DownloadTwitterProfileIcon : NSOperation

#pragma mark - Public Methods
- (id)initWithTwitterAccount:(TwitterAccount *)account notification:(NSString *)notification;

@end
