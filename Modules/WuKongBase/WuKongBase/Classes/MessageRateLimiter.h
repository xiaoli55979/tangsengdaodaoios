//
//  MessageRateLimiter.h
//  WuKongBase
//
//  Created by 阿浩 on 29/10/2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MessageRateLimiter : NSObject
- (BOOL)canSendMessageForID:(id)identifier;
@end

NS_ASSUME_NONNULL_END
