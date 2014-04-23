//
//  RAOrchestration.m
//  MambaTweets
//
//  Created by David House on 4/13/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "RAOrchestration.h"
#import <Objc/runtime.h>


static char const * const OrchestrationQueueKey = "MambaObjectID";

//
//
//
@interface RAOrchestrationOperation : NSObject

@property (nonatomic,strong) NSString *operationID;
@property (nonatomic,strong) NSOperation *operation;
@property (nonatomic,assign) SEL completionSelector;

@end

@implementation RAOrchestrationOperation
@end


//
//
//
@interface RAOrchestrationOperationGroup : NSObject

@property (nonatomic,strong) NSString *groupName;
@property (nonatomic,assign) NSUInteger operationCount;
@property (nonatomic,assign) SEL groupCompletionSelector;

@end

@implementation RAOrchestrationOperationGroup
@end

//
//
//
@interface RAOrchestration()

#pragma mark - Properties
@property (nonatomic,strong) NSMutableDictionary *currentOperations;
@property (nonatomic,strong) NSMutableDictionary *groupedOperations;

@end


//
//
//
@implementation RAOrchestration {
    NSOperationQueue *_defaultOperationQueue;
    dispatch_queue_t _completionQueue;
    NSOperationQueue *_concurrentQueue;
}

#pragma mark - Initilizer
- (id)init
{
    if ( self = [super init] ) {
        _currentOperations = [[NSMutableDictionary alloc] init];
        _groupedOperations = [[NSMutableDictionary alloc] init];
        _completionQueue = dispatch_queue_create([[[NSUUID UUID] UUIDString] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Properties
- (NSOperationQueue *)defaultOperationQueue
{
    if ( !_defaultOperationQueue ) {
        _defaultOperationQueue = [[NSOperationQueue alloc] init];
    }
    return _defaultOperationQueue;
}

#pragma mark - NSOperation
- (BOOL)isFinished
{
    return [[self.currentOperations allKeys] count] == 0;
}

- (void)cancel
{
    NSLog(@">>> ORCHESTATION CANCELLED !!! <<<");
    for ( RAOrchestrationOperation *trackedOperation in [self.currentOperations allValues] ) {
        [trackedOperation.operation cancel];
    }
    [self.currentOperations removeAllObjects];
    [self willChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isFinished"];

    [super cancel];
}

#pragma mark - Public Methods
+ (NSOperationQueue *)defaultOrchestrationQueue
{
    // if we already have a default queue for this class, go ahead
    // and return it
    NSOperationQueue *operationQueue = objc_getAssociatedObject([self class], OrchestrationQueueKey);
    if ( operationQueue ) {
        return operationQueue;
    }
    else {
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        operationQueue.maxConcurrentOperationCount = 1;
        objc_setAssociatedObject([self class], OrchestrationQueueKey, operationQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operationQueue;
    }
}

+ (void)cancelOrchestration
{
    [[self defaultOrchestrationQueue] cancelAllOperations];
}

#pragma mark - Private Methods
- (void)operationFinished:(id)operation
{
}

- (void)operationGroupFinished:(NSString *)group
{
}

- (void)allOperationsFinished
{
}

#pragma mark - Track Operations
- (void)trackOperation:(id)operation
{
    RAOrchestrationOperation *trackedOperation = [self orchestrationOperationFromOperation:operation];
    [self addTrackedOperation:trackedOperation];
    
    
//    NSString *operationID = [NSString stringWithFormat:@"%@_%@",NSStringFromClass([operation class]),[[NSUUID UUID] UUIDString]];
//    
//    RAOrchestrationOperation *trackedOperation = [[RAOrchestrationOperation alloc] init];
//    trackedOperation.operation = operation;
//    [self.currentOperations setObject:trackedOperation forKey:operationID];
//    NSOperation *op = (NSOperation *)operation;
//    __weak id weakself = self;
//    [op setCompletionBlock:^{
//        dispatch_async(_completionQueue, ^{
//            [weakself operationDone:operationID];
//        });
//    }];
}

- (void)trackAndQueueOperation:(id)operation
{
    [self trackOperation:operation];
    [self.defaultOperationQueue addOperation:operation];
}

- (void)trackOperation:(id)operation withCompletion:(SEL)completionSelector
{
    RAOrchestrationOperation *trackedOperation = [self orchestrationOperationFromOperation:operation withCompletion:completionSelector];
    [self addTrackedOperation:trackedOperation];
    
//    
//    NSString *operationID = [NSString stringWithFormat:@"%@_%@",NSStringFromClass([operation class]),[[NSUUID UUID] UUIDString]];
//
//    RAOrchestrationOperation *trackedOperation = [[RAOrchestrationOperation alloc] init];
//    trackedOperation.operation = operation;
//    trackedOperation.completionSelector = completionSelector;
//    [self.currentOperations setObject:trackedOperation forKey:operationID];
//
//    [self.currentOperations setObject:trackedOperation forKey:operationID];
//    NSOperation *op = (NSOperation *)operation;
//    __weak id weakself = self;
//    [op setCompletionBlock:^{
//        [weakself operationDone:operationID];
//    }];
}

- (void)trackAndQueueOperation:(id)operation withCompletion:(SEL)completionSelector
{
    [self trackOperation:operation withCompletion:completionSelector];
    [self.defaultOperationQueue addOperation:operation];
}

- (void)setCompletion:(SEL)completionSelector group:(Class)groupClass
{
    NSString *groupKey = NSStringFromClass(groupClass);

    // If we are already tracking this group, append this
    // operation to the list, otherwise we need to create it
    if ( [self.groupedOperations objectForKey:groupKey] ) {
        
        RAOrchestrationOperationGroup *group = [self.groupedOperations objectForKey:groupKey];
        group.groupCompletionSelector = completionSelector;
    }
    else {
        
        RAOrchestrationOperationGroup *group = [[RAOrchestrationOperationGroup alloc] init];
        group.groupName = groupKey;
        group.operationCount = 0;
        group.groupCompletionSelector = completionSelector;
        [self.groupedOperations setObject:group forKey:groupKey];
    }
}

#pragma mark - Private Methods
- (void)operationDone:(NSString *)operationID
{
    RAOrchestrationOperation *trackedOperation = [self.currentOperations objectForKey:operationID];
    NSString *groupKey = NSStringFromClass([trackedOperation.operation class]);

    NSLog(@"DONE >> %@ (%@)",groupKey,trackedOperation.operationID);
    
    for ( NSString *key in self.groupedOperations ) {
        RAOrchestrationOperationGroup *group = [self.groupedOperations objectForKey:key];
        NSLog(@"GROUP: %@ count = %d SELECTOR: %@",key,group.operationCount,group.groupCompletionSelector ? @"YES":@"NO");
    }
    
    
    // Remove operation from our dictionary
    [self.currentOperations removeObjectForKey:operationID];
    if ( !self.isCancelled ) {
        if ( trackedOperation.completionSelector ) {
            IMP imp = [self methodForSelector:trackedOperation.completionSelector];
            void (*func)(id,SEL,NSOperation *) = (void *)imp;
            func(self,trackedOperation.completionSelector,trackedOperation.operation);
        }
        else {
            [self operationFinished:trackedOperation.operation];
        }
    }
    
    // Now lets check the group as well
    if ( [self.groupedOperations objectForKey:groupKey] ) {
        RAOrchestrationOperationGroup *group = [self.groupedOperations objectForKey:groupKey];
        group.operationCount--;
        NSLog(@"group %@ operationCount = %d",groupKey,group.operationCount);
        if ( group.operationCount == 0 ) {
            
            if ( !self.isCancelled ) {
                if ( group.groupCompletionSelector ) {
                    IMP imp = [self methodForSelector:group.groupCompletionSelector];
                    void (*func)(id,SEL) = (void *)imp;
                    func(self,group.groupCompletionSelector);
                }
                else {
                    [self operationGroupFinished:groupKey];
                }
            }
        }
    }
    
    if ( [self.currentOperations count] == 0 ) {
        NSLog(@"Orchestration has finished");
        [self allOperationsFinished];
    }
    
    // do the KVO stuff
    [self willChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isFinished"];
}

- (RAOrchestrationOperation *)orchestrationOperationFromOperation:(id)operation
{
    NSString *operationID = [NSString stringWithFormat:@"%@_%@",NSStringFromClass([operation class]),[[NSUUID UUID] UUIDString]];

    RAOrchestrationOperation *trackedOperation = [[RAOrchestrationOperation alloc] init];
    trackedOperation.operation = operation;
    trackedOperation.operationID = operationID;
    return trackedOperation;
}

- (RAOrchestrationOperation *)orchestrationOperationFromOperation:(id)operation withCompletion:(SEL)completionSelector
{
    NSString *operationID = [NSString stringWithFormat:@"%@_%@",NSStringFromClass([operation class]),[[NSUUID UUID] UUIDString]];

    RAOrchestrationOperation *trackedOperation = [[RAOrchestrationOperation alloc] init];
    trackedOperation.operationID = operationID;
    trackedOperation.operation = operation;
    trackedOperation.completionSelector = completionSelector;
    return trackedOperation;
}

- (void)addTrackedOperation:(RAOrchestrationOperation *)trackedOperation
{
    NSString *groupKey = NSStringFromClass([trackedOperation.operation class]);

    // Setup the correct completed block
    NSOperation *op = (NSOperation *)trackedOperation.operation;
    __weak id weakself = self;
    [op setCompletionBlock:^{
        dispatch_async(_completionQueue, ^{
            [weakself operationDone:trackedOperation.operationID];
        });
    }];
    
    // Add to our tracked operations
    [self.currentOperations setObject:trackedOperation forKey:trackedOperation.operationID];
    
    // If we are already tracking this group, append this
    // operation to the list, otherwise we need to create it
    if ( [self.groupedOperations objectForKey:groupKey] ) {
        
        NSLog(@"incrementing operation count for group: %@",groupKey);
        RAOrchestrationOperationGroup *group = [self.groupedOperations objectForKey:groupKey];
        group.operationCount++;
    }
    else {
        
        NSLog(@"group not found, adding: %@",groupKey);
        RAOrchestrationOperationGroup *group = [[RAOrchestrationOperationGroup alloc] init];
        group.groupName = groupKey;
        group.operationCount = 1;
        [self.groupedOperations setObject:group forKey:groupKey];
    }
    
    NSLog(@"TRACKING >> %@ (%@)",groupKey,trackedOperation.operationID);
}

@end
