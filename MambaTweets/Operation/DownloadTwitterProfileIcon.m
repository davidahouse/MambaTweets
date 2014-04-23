//
//  DownloadTwitterProfileIcon.m
//  MambaTweets
//
//  Created by David House on 4/21/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "DownloadTwitterProfileIcon.h"
#import "TwitterAccount.h"

@interface DownloadTwitterProfileIcon()

#pragma mark - Properties
@property (nonatomic,strong) TwitterAccount *twitterAccount;
@property (nonatomic,strong) NSString *finishNotification;

@end

@implementation DownloadTwitterProfileIcon

#pragma mark - Public Methods
- (id)initWithTwitterAccount:(TwitterAccount *)account notification:(NSString *)notification
{
    if ( self = [super init] ) {
        _twitterAccount = account;
        _finishNotification = notification;
    }
    return self;
}

- (void)main
{
    @autoreleasepool {
        
        // Yeah, not ideal but it works (mostly).
        NSData *iconData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.twitterAccount.iconURL]];
        [iconData writeToFile:self.twitterAccount.localIconPath atomically:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:self.finishNotification object:nil];
    }
}

@end
