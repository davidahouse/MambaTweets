//
//  TwitterAuthorized.h
//  MambaTweets
//
//  Created by David House on 4/12/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

typedef NS_ENUM(NSUInteger,TwitterAuthorizedState) {
  
    TwitterAuthorizedStateGranted = 0,
    TwitterAuthorizedStateError = 1
};

@interface TwitterAuthorized : NSOperation

#pragma mark - Properties
@property (nonatomic,readonly) ACAccountStore *accountStore;
@property (nonatomic,readonly) TwitterAuthorizedState authorizedState;

@end
