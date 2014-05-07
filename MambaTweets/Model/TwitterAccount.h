//
//  TwitterAccount.h
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+DHMambaObject.h"

@interface TwitterAccount : NSObject<DHMambaObjectProperties>

#pragma mark - Properties
@property (nonatomic,strong) NSString *userName;
@property (nonatomic,strong) NSNumber *totalTweets;
@property (nonatomic,strong) NSNumber *totalFavorites;
@property (nonatomic,strong) NSNumber *totalReplies;
@property (nonatomic,strong) NSNumber *totalRetweets;
@property (nonatomic,strong) NSString *minID;
@property (nonatomic,strong) NSString *maxID;
@property (nonatomic,strong) NSNumber *maxLoaded;
@property (nonatomic,strong) NSString *iconURL;

#pragma mark - Public Methods
- (BOOL)localIconFound;
- (NSString *)localIconPath;

@end
