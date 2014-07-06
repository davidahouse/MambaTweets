//
//  RefreshTimeline.h
//  MambaTweets
//
//  Created by David House on 4/12/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT const NSString *kTimelineSummaryNotification;
FOUNDATION_EXPORT const NSString *kIconFinishedDownloadNotification;

@interface RefreshTimeline : NSOperation

#pragma mark - Properties
@property (nonatomic,readonly) BOOL authorized;

#pragma mark - Class Methods
+ (RefreshTimeline *)startRefreshJob;

@end


