//
//  TwitterAccount.m
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "TwitterAccount.h"

@implementation TwitterAccount

#pragma mark - MambaObjectProperties
- (NSString *)mambaObjectKey
{
    return self.userName;
}

#pragma mark - Public Methods
- (BOOL)localIconFound
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self localIconPath]];
}

- (NSString *)localIconPath
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:@"twitter_icon.jpg"];
}

@end
