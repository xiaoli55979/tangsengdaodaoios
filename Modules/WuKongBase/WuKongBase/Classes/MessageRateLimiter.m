#import "MessageRateLimiter.h"

@interface MessageRateLimiter ()

@property (nonatomic, strong) NSMutableDictionary<id, NSMutableArray<NSDate *> *> *messageTimestamps;
@property (nonatomic, assign) NSTimeInterval timeLimit;
@property (nonatomic, assign) NSInteger maxMessages;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation MessageRateLimiter

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeLimit = 10; // 时间限制10秒
        _maxMessages = 1; // 最大消息数量限制为1条
        _messageTimestamps = [NSMutableDictionary dictionary];
        _queue = dispatch_queue_create("com.wukongbase.messagelimiter", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (BOOL)canSendMessageForID:(id)identifier {
    __block BOOL canSend = NO;
    NSDate *currentTime = [NSDate date];
    
    dispatch_sync(self.queue, ^{
        // 获取当前标识符的时间戳数组，如果没有则创建新的
        NSMutableArray<NSDate *> *timestamps = self.messageTimestamps[identifier];
        if (!timestamps) {
            timestamps = [NSMutableArray array];
            self.messageTimestamps[identifier] = timestamps;
        }
        
        // 移除超过时间限制的时间戳
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDate *timestamp, NSDictionary *bindings) {
            return [currentTime timeIntervalSinceDate:timestamp] < self.timeLimit;
        }];
        [timestamps filterUsingPredicate:predicate];
        
        // 检查当前消息数量是否超过限制
        if (timestamps.count < self.maxMessages) {
            // 添加当前消息的时间戳
            [timestamps addObject:currentTime];
            canSend = YES;
        }
    });
    
    return canSend;
}

@end
