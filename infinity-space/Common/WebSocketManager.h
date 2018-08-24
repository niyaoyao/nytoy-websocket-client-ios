//
//  WebSocketManager.h
//  infinity-space
//
//  Created by niyao on 8/24/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebSocketConfiguration.h"

#ifdef DEBUG
#define ConsoleLog(...) NSLog(@"%s \n%@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]);

#else
#define ConsoleLog(...)

#endif

typedef NS_ENUM(NSInteger, WebSocketStatus) {
    WebSocketStatusOpen,
    WebSocketStatusClosed,
};

@interface WebSocketManager : NSObject
@property (nonatomic, assign, readonly) WebSocketStatus status;

+ (instancetype)shared;
+ (void)setup:(WebSocketConfiguration *)configuration;
+ (void)start;
+ (void)stop;
- (void)send:(NSString *)message;
- (void)reconnect;
- (void)close;
@end
