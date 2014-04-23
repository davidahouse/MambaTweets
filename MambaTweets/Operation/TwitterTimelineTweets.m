//
//  TwitterTimelineTweets.m
//  MambaTweets
//
//  Created by David House on 4/12/14.
//  Copyright (c) 2014 randomaccident. All rights reserved.
//

#import "TwitterTimelineTweets.h"
#import "TwitterAccount.h"

@interface TwitterTimelineTweets()

#pragma mark - Input Properties
@property (nonatomic,strong) ACAccountStore *accountStore;
@property (nonatomic,strong) TwitterAccount *account;
@property (nonatomic,assign) BOOL timelineFinished;

@end

@implementation TwitterTimelineTweets

#pragma mark - Initializer
- (id)initWithAccountStore:(ACAccountStore *)accountStore forTwitterAccount:(TwitterAccount *)account inDirection:(NSString *)direction
{
    if ( self = [super init] ) {
        _accountStore = accountStore;
        _account = account;
        _inDirection = direction;
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
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"screen_name" : self.account.userName,
                                 @"include_rts" : @"0",
                                 @"trim_user" : @"1",
                                 @"count" : @"50"}];
        
        if ( [self.inDirection isEqualToString:@"new"] ) {
            [params setValue:self.account.minID forKeyPath:@"since_id"];
        }
        else {
            [params setValue:self.account.maxID forKeyPath:@"max_id"];
        }
        
        NSLog(@"loading timeline with params: %@",params);
        
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
                         
                         NSLog(@"got the timeline!!!");
                         NSLog(@"timeline: %@",timelineData);
                         _tweets = (NSArray *)timelineData;
                     }
                     else {
                         // Our JSON deserialization went awry
                         NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
                     }
                 }
                 else {
                     // The server did not respond ... were we rate-limited?
                     NSLog(@"The response status code is %d",
                           urlResponse.statusCode);
                     NSLog(@"Error: %@",[error localizedDescription]);
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
