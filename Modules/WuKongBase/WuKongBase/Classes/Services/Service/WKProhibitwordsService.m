//
//  WKSensitivewordsService.m
//  WuKongBase
//
//  Created by tt on 2024/4/29.
//

#import "WKProhibitwordsService.h"
#import "WKAPIClient.h"
#import "WKJsonUtil.h"

@interface WKProhibitwordsService()

@property (nonatomic,strong) NSMutableDictionary *keywordChains;
@property (nonatomic,copy) NSString *delimit;

@end

@implementation WKProhibitwordsService


static WKProhibitwordsService *_instance = nil;
+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone ];
       
    });
    return _instance;
}

+(instancetype) shared{
    if (_instance == nil) {
        _instance = [[super alloc]init];
        _instance.delimit = @"\x00";
    }
    return _instance;
}

- (BOOL)needSync {
    return true;
}

- (void)sync:(void (^)(NSError *))callback {
    callback(nil); // 直接返回，因为成功与否 都不影响程序的逻辑
    [self load]; //  加载敏感词
    NSInteger lastVersion = 0;
    if(self.prohibitwords && self.prohibitwords.count>0) {
       NSDictionary *lastDict = self.prohibitwords[self.prohibitwords.count-1];
        if(lastDict[@"version"]) {
            lastVersion = [lastDict[@"version"] integerValue];
        }
        [self refresh];
    }
    
    __weak typeof(self) weakSelf = self;
    [WKAPIClient.sharedClient GET:@"message/prohibit_words/sync" parameters:@{@"version":@(lastVersion)}].then(^(NSArray<NSDictionary*> *results){
        if(results && results.count>0) {
            NSInteger version = 0;
            for (NSDictionary *result in results) {
                if(result[@"version"]) {
                    version = [result[@"version"] integerValue];
                }
                if(version>lastVersion) {
                    [weakSelf.prohibitwords addObject:result];
                }
            }
            [weakSelf save];
            [weakSelf refresh];
        }
       
    });
}

-(void) refresh {
        [self.keywordChains removeAllObjects];
        BOOL isDeleted = false;
        for (NSDictionary *resultDict in self.prohibitwords) {
            if(resultDict[@"is_deleted"]) {
                isDeleted = [resultDict[@"is_deleted"] boolValue];
            }
            if(!isDeleted) {
                NSString *word = resultDict[@"content"];
                if(word && ![word isEqualToString:@""]) {
                    [self addProhibitword:word];
                }
            }
        }
}

///// 敏感词处理
- (void)addProhibitword:(NSString *)keyword{
    keyword = keyword.lowercaseString;
    keyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSMutableDictionary *node = self.keywordChains;
    for (int i = 0; i < keyword.length; i ++) {
        NSString *word = [keyword substringWithRange:NSMakeRange(i, 1)];
        if (node[word] == nil) {
            node[word] = [NSMutableDictionary dictionary];
        }
        node = node[word];
    }
    //敏感词最后一个字符标识
    [node setValue:@0 forKey:self.delimit];
}

- (NSString *)filter:(NSString *)message {
    return [self filter:message replaceKey:nil];
}
      
- (NSString *)filter:(NSString *)message replaceKey:(NSString *)replaceKey {
    replaceKey = replaceKey == nil ? @"*" : replaceKey;
    
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    NSInteger start = 0;
    
    while (start < message.length) {
        NSMutableDictionary *level = self.keywordChains;
        NSInteger step_ins = 0;
        BOOL matched = NO;
        BOOL partialMatched = NO;  // 部分匹配标志
        
        // 处理剩余的消息字符
        NSString *message_chars = [message substringWithRange:NSMakeRange(start, message.length - start)];
        
        for (int i = 0; i < message_chars.length; i++) {
            NSString *chars_i = [[message_chars substringWithRange:NSMakeRange(i, 1)] lowercaseString];  // 不区分大小写
            
            if (level[chars_i]) {
                step_ins += 1;
                NSDictionary *level_char_dict = level[chars_i];
                
                // 完全匹配到敏感词
                if (level_char_dict[self.delimit]) {
                    NSMutableString *ret_str = [NSMutableString stringWithCapacity:step_ins];
                    for (int j = 0; j < step_ins; j++) {
                        [ret_str appendString:replaceKey];
                    }
                    [retArray addObject:ret_str];
                    start += step_ins - 1;  // 匹配到敏感词，跳过这些字符
                    matched = YES;
                    break;
                } else {
                    level = level_char_dict;  // 更新到下一级字典
                }

                // 部分匹配：至少连续匹配到 2 个字符
                if (step_ins >= 2) {
                    partialMatched = YES;
                }
            } else {
                // 当前字符没有匹配到敏感词，退出循环
                break;
            }
        }
        
        if (!matched && partialMatched) {
            // 部分匹配到两个或更多字符，进行替换
            NSMutableString *ret_str = [NSMutableString stringWithCapacity:step_ins];
            for (int j = 0; j < step_ins; j++) {
                [ret_str appendString:replaceKey];
            }
            [retArray addObject:ret_str];
            start += step_ins - 1;  // 跳过已替换的部分
        } else if (!matched) {
            // 没有匹配到任何敏感词，保留原始字符
            [retArray addObject:[NSString stringWithFormat:@"%C", [message characterAtIndex:start]]];
        }
        
        start++;
    }
    
    return [retArray componentsJoinedByString:@""];
}




- (NSMutableDictionary *)keywordChains{
    if(_keywordChains == nil){
        _keywordChains = [[NSMutableDictionary alloc] initWithDictionary:@{}];
    }
    return _keywordChains;
}


-(NSString*) savePath {
    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/prohibitwords.json"];
    return filePath;
}

-(void) load {
    NSString *filePath = [self savePath];
    NSMutableArray *prohibitwords = [NSMutableArray array];
    NSString *prohibitwordsJsonStr = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    if(prohibitwordsJsonStr && ![prohibitwordsJsonStr isEqualToString:@""]) {
        NSArray *items = [WKJsonUtil toArray:prohibitwordsJsonStr];
        prohibitwords = [NSMutableArray arrayWithArray:items];
    }
    self.prohibitwords = prohibitwords;
}

-(void) save {
    NSString *filePath = [self savePath];
    NSString *jsonStr = [WKJsonUtil toJson:self.prohibitwords];
    [jsonStr writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (NSString *)title {
    return nil;
}
@end
