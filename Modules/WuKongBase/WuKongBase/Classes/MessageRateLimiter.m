#import "MessageRateLimiter.h"

@interface MessageRateLimiter ()

@property (nonatomic, strong) NSMutableDictionary<id, NSDate *> *lastMessageTimestamps;
@property (nonatomic, assign) NSTimeInterval messageInterval;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation MessageRateLimiter

- (instancetype)init {
    self = [super init];
    if (self) {
        _messageInterval = 1; // 默认时间间隔为10秒
        _lastMessageTimestamps = [NSMutableDictionary dictionary];
        _queue = dispatch_queue_create("com.wukongbase.messagelimiter", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// 设置每分钟允许的消息数量
- (void)setMessageLimitPerMinute:(NSInteger)count {
    if (count <= 0) {
        self.messageInterval = 60; // 确保最低限度为60秒一条消息
    } else {
        self.messageInterval = 60.0 / count; // 计算平均每条消息的发送间隔
    }
}

- (BOOL)canSendMessageForID:(id)identifier {
    __block BOOL canSend = NO;
    NSDate *currentTime = [NSDate date];
    
    dispatch_sync(self.queue, ^{
        NSDate *lastTimestamp = self.lastMessageTimestamps[identifier];
        
        // 判断是否满足消息发送间隔
        if (!lastTimestamp || [currentTime timeIntervalSinceDate:lastTimestamp] >= self.messageInterval) {
            // 更新最后发送时间戳
            self.lastMessageTimestamps[identifier] = currentTime;
            canSend = YES;
        }
    });
    
    return canSend;
}

@end
