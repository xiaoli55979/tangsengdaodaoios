//
//  WKChannelSettingManager.h
//  WuKongBase
//
//  Created by tt on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import <WuKongIMSDK/WuKongIMSDK.h>
#import <PromiseKit/PromiseKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface WKChannelSettingManager : NSObject

+ (instancetype _Nonnull )shared;

// 免打扰
-(void) channel:(WKChannel*)channel mute:(BOOL) on;
-(BOOL) mute:(WKChannel*)channel;

// 置顶
-(void) channel:(WKChannel*)channel stick:(BOOL) on;
-(BOOL) stick:(WKChannel*) channel;

// 消息回执
-(void) channel:(WKChannel*)channel receipt:(BOOL) on;
-(BOOL) receipt:(WKChannel*)channel;

// 聊天密码开关
-(void) channel:(WKChannel*)channel chatPwdOn:(BOOL)on;
-(BOOL)chatPwdOn:(WKChannel*)channel;

// 截屏通知
-(void) channel:(WKChannel*)uid screenshot:(BOOL) on;
-(BOOL)screenshot:(WKChannel*)channel;

// 保存到通讯录
-(void) group:(NSString*)groupNo save:(BOOL) on;
-(BOOL) save:(WKChannel*)channel;


// 撤回提醒
-(void) channel:(WKChannel*)channel revokeRemind:(BOOL)on;
-(BOOL)revokeRemind:(WKChannel*)channel;

// 进群提醒
-(void) channel:(WKChannel*)channel joinGroupRemind:(BOOL)on;
-(BOOL) joinGroupRemind:(WKChannel*)channel;

// 更新历史消息查看
-(void) channel:(WKChannel*)channel allowViewHistoryMsg:(BOOL) on;

/// 禁止添加好友
-(void) channel:(WKChannel*)channel forbiddenAddFriend:(BOOL)on;

// 是否显示昵称
-(void) group:(NSString*)groupNo nick:(BOOL) on;
-(BOOL) showNickName:(WKChannel*)channel;

/// 群禁言
-(void) group:(NSString*)groupNo forbidden:(BOOL) on;
-(BOOL) forbidden:(WKChannel*)channel;


/// 禁止邀请好友
-(void) group:(NSString*)groupNo invite:(BOOL) on;
-(BOOL) invite:(WKChannel*)channel;

/// 焚烧模式
-(void) group:(NSString*)groupNo flame:(BOOL) on;
-(BOOL) flame:(WKChannel*)channel;

// 备注设置
-(AnyPromise*) channel:(WKChannel*)channel remark:(NSString*)remark;

// 阅后即焚
-(void) channel:(WKChannel*)channel flame:(BOOL) on;

// 阅后即焚时间
-(void) channel:(WKChannel*)channel flameSecond:(NSInteger) flameSecond;

-(NSString*) remark:(WKChannel*)channel;
@end

NS_ASSUME_NONNULL_END
