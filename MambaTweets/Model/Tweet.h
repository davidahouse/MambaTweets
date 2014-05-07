//
//  Tweet.h
//  MambaTweets
//
//  Created by David House on 4/12/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+DHMambaObject.h"

@interface Tweet : NSObject<DHMambaObjectProperties>

#pragma mark - Properties
@property (nonatomic,strong) NSString *tweetID;
@property (nonatomic,strong) NSString *source;
@property (nonatomic,strong) NSString *text;
@property (nonatomic,strong) NSString *createdAt;
@property (nonatomic,strong) NSString *category;

#pragma mark - Initializer
- (id)initWithJSON:(id)jsonObject;

@end
