//
//  WebSocketConfiguration.h
//  infinity-space
//
//  Created by niyao on 8/24/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebSocketConfiguration : NSObject

@property (nonatomic, strong) NSString *hostUrl;
@property (nonatomic, strong) NSDictionary *customRequestHeaders;

@end
