//
//  WebSocketManager.m
//  infinity-space
//
//  Created by niyao on 8/24/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import "WebSocketManager.h"
#import "SocketRocket.h"

static WebSocketManager *manager = nil;
static const uint64_t heartBeatInterval = 60 * 3;

@interface WebSocketManager() <SRWebSocketDelegate>

@property (nonatomic, strong) NSURL *hostURL;
@property (nonatomic, strong) SRWebSocket *wsClient;
@property (nonatomic, strong) NSDictionary *requestHeaders;
@property (nonatomic, assign) NSInteger reconnectCount;

@end

@implementation WebSocketManager {
    dispatch_source_t _heart_beat_timer;
    dispatch_queue_t _heart_beat_timer_queue;
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WebSocketManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _heart_beat_timer_queue = dispatch_queue_create("websocket.timer.queue", DISPATCH_QUEUE_SERIAL);
        _reconnectCount = 0;
    }
    return self;
}

#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    ConsoleLog(@"WebSocketDidOpen: %@", self.hostURL);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    ConsoleLog(@"WebSocket didReceivePong: %@", pongPayload);
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    ConsoleLog(@"WebSocket didFailWithError: %@", error);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    ConsoleLog(@"WebSocket didReceiveMessage: %@", message);
}

- (BOOL)webSocketShouldConvertTextFrameToString:(SRWebSocket *)webSocket {
    return YES;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    ConsoleLog(@"WebSocket didCloseWithCode: %ld \nreason:%@ \nwasClean:%d", (long)code, reason, wasClean);
}

#pragma mark - Private
+ (NSURLRequest *)webSocketRequestWith:(NSURL *)wsURL headers:(NSDictionary *)headers {
    NSURLRequest *request = nil;
    if (wsURL != nil) {
        request = [[NSURLRequest alloc] initWithURL:wsURL];
    } else {
        NSAssert(wsURL, @"Web Socket Host URL is nil");
    }
    
    for (NSString *key in headers.allKeys) {
        [request setValue:headers[key] forKey:key];
    }

    return request;
}

- (void)startHeartBeat {
    if (_heart_beat_timer) {
        dispatch_source_cancel(_heart_beat_timer);
        _heart_beat_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _heart_beat_timer_queue);
        dispatch_source_set_timer(_heart_beat_timer, DISPATCH_TIME_NOW, heartBeatInterval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        __weak typeof (self) weakSelf = self;
        dispatch_source_set_event_handler(_heart_beat_timer, ^{
            [weakSelf sendHeartBeat];
        });
        dispatch_resume(_heart_beat_timer);
    }
}

- (void)stopHeartBeat {
    if (_heart_beat_timer) {
        dispatch_source_cancel(_heart_beat_timer);
        _heart_beat_timer = nil;
    }
}

- (void)sendHeartBeat {
    if (self.wsClient.readyState == SR_OPEN) {
        [self.wsClient sendPing:nil];
    }
}

#pragma mark - Public
+ (void)setup:(WebSocketConfiguration *)configuration {
    WebSocketManager.shared.hostURL = [[NSURL alloc] initWithString:configuration.hostUrl];
    WebSocketManager.shared.requestHeaders = configuration.customRequestHeaders;
}

+ (void)start {
    [WebSocketManager.shared reconnect];
}

+ (void)stop {
    [WebSocketManager.shared close];
}

- (void)send:(NSString *)message {
    ConsoleLog(@"Send: %@", message);
    if (self.wsClient.readyState == SR_OPEN) {
        [self.wsClient send:message];
    }
}

- (void)sendData:(NSData *)jsonData; {
    ConsoleLog(@"Send: %@", jsonData);
    if (self.wsClient.readyState == SR_OPEN) {
        [self.wsClient send:jsonData];
    }
}

- (void)reconnect {
    self.wsClient.delegate = nil;
    [self.wsClient close];
    if (self.hostURL == nil) {
        NSAssert(self.hostURL, @"WebSocket URL is nil");
        return ;
    }
    
    __weak typeof (self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.reconnectCount * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURLRequest *request = [WebSocketManager webSocketRequestWith:weakSelf.hostURL headers:weakSelf.requestHeaders];
        weakSelf.wsClient = [[SRWebSocket alloc] initWithURLRequest:request];
        weakSelf.wsClient.delegate = weakSelf;
        [weakSelf.wsClient open];
        if (weakSelf.reconnectCount == 0) {
            weakSelf.reconnectCount = 2;
        } else {
            weakSelf.reconnectCount *= 2;
        }
    });
    
}

- (void)close {
    [self.wsClient close];
    self.wsClient = nil;
    [self stopHeartBeat];
}

@end
