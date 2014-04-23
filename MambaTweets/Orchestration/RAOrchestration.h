//
//  RAOrchestration.h
//  MambaTweets
//
//  Created by David House on 4/13/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RAOrchestration : NSOperation

#pragma mark - Properties
@property (nonatomic,readonly) NSOperationQueue *defaultOperationQueue;

#pragma mark - Class Methods
+ (NSOperationQueue *)defaultOrchestrationQueue;
+ (void)cancelOrchestration;

#pragma mark - Public Methods
- (void)operationFinished:(id)operation;
- (void)operationGroupFinished:(NSString *)group;

#pragma mark - Track Operations
- (void)trackOperation:(id)operation;
- (void)trackAndQueueOperation:(id)operation;
- (void)trackOperation:(id)operation withCompletion:(SEL)completionSelector;
- (void)trackAndQueueOperation:(id)operation withCompletion:(SEL)completionSelector;
- (void)setCompletion:(SEL)completionSelector group:(Class)groupClass;

@end
