//
//  TwitterInitialUserInfo.m
//  MambaTweets
//
//  Created by David House on 4/14/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "TwitterInitialUserInfo.h"

@interface TwitterInitialUserInfo()

#pragma mark - Properties
@property (nonatomic,strong) ACAccountStore *accountStore;
@property (nonatomic,assign) BOOL timelineFinished;

@end

@implementation TwitterInitialUserInfo {
    NSDictionary *_tweetResponse;
    NSError *_error;
}

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore
{
    if ( self = [super init] ) {
        _accountStore = accountStore;
        _timelineFinished = NO;
    }
    return self;
}

#pragma mark - NSOperation
- (void)main
{
    @autoreleasepool {
        
        // Don't bother if we are cancelled
        if ( self.isCancelled ) {
            return;
        }

        
        NSLog(@"getting the tweet timeline...");
        
        ACAccountType *twitterAccountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        NSArray *twitterAccounts =
        [self.accountStore accountsWithAccountType:twitterAccountType];
        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                      @"/1.1/statuses/user_timeline.json"];
        ACAccount *account = self.accountStore.accounts[0];
        NSDictionary *params = @{@"screen_name" : account.username,
                                 @"include_rts" : @"0",
                                 @"trim_user" : @"0",
                                 @"count" : @"1"};
        SLRequest *request =
        [SLRequest requestForServiceType:SLServiceTypeTwitter
                           requestMethod:SLRequestMethodGET
                                     URL:url
                              parameters:params];
        
        //  Attach an account to the request
        [request setAccount:[twitterAccounts lastObject]];
        
        //  Step 3:  Execute the request
        [request performRequestWithHandler:
         ^(NSData *responseData,
           NSHTTPURLResponse *urlResponse,
           NSError *error) {
             
             if (responseData) {
                 if (urlResponse.statusCode >= 200 &&
                     urlResponse.statusCode < 300) {
                     
                     NSError *jsonError;
                     NSArray *timelineData =
                     [NSJSONSerialization
                      JSONObjectWithData:responseData
                      options:NSJSONReadingAllowFragments error:&jsonError];
                     if (timelineData) {
                         
                         NSLog(@"got the initial user data: %@",timelineData);
                         
                         _tweetResponse = timelineData[0];
                     }
                     else {
                         // Our JSON deserialization went awry
                         NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
                         _error = jsonError;
                     }
                 }
                 else {
                     // The server did not respond ... were we rate-limited?
                     NSLog(@"The response status code is %d",
                           urlResponse.statusCode);
                     _error = error;
                 }
             }
             
             [self willChangeValueForKey:@"isFinished"];
             self.timelineFinished = YES;
             [self didChangeValueForKey:@"isFinished"];
         }];
    }
}

- (BOOL)isFinished
{
    return self.timelineFinished;
}


@end
