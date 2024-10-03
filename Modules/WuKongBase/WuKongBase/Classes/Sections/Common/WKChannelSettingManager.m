//
//  WKChannelSettingManager.m
//  WuKongBase
//
//  Created by tt on 2021/8/10.
//

#import "WKChannelSettingManager.h"
#import "WuKongBase.h"
@implementation WKChannelSettingManager


+ (instancetype)shared{
    static WKChannelSettingManager *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[WKChannelSettingManager alloc] init];
    });
    
    return _shared;
}
// 更新群设置
-(void) updateGroupManager:(WKGroupSettingKey)key on:(BOOL)on groupNo:(NSString*)groupNo{
    [[WKGroupManager shared] groupSetting:groupNo settingKey:key on:on];
}

// 更新群设置
-(void) updateGroupSetting:(WKGroupSettingKey)key on:(BOOL)on groupNo:(NSString*)groupNo{
    [[WKGroupManager shared] groupSetting:groupNo settingKey:key on:on];
}

// 更新群管理设置
-(void) updateGroupManagerSetting:(WKGroupSettingKey)key on:(BOOL)on groupNo:(NSString*)groupNo {
    NSString *keyStr = [[WKGroupManager shared] getKeyString:key];
    [[WKGroupManager shared] groupManagerSetting:groupNo key:keyStr value:@(on)];
}

// 更新用户设置-免打扰
-(void) channel:(WKChannel*)channel mute:(BOOL) on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{@"mute":@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyMute on:on groupNo:channel.channelId];
    }
}

// 设置-置顶
-(void) channel:(WKChannel*)channel stick:(BOOL) on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{@"top":@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyStick on:on groupNo:channel.channelId];
    }
    
}
// 设置-消息回执
-(void) channel:(WKChannel*)channel receipt:(BOOL) on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{@"receipt":@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyReceipt on:on groupNo:channel.channelId];
    }
}
// 阅后即焚
-(void) channel:(WKChannel*)channel flame:(BOOL) on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{@"flame":@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyFlame on:on groupNo:channel.channelId];
    }
}
-(void) channel:(WKChannel*)channel flameSecond:(NSInteger) flameSecond {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{@"flame_second":@(flameSecond)}];
    }else {
        [[WKGroupManager shared] groupSetting:channel.channelId key:@"flame_second" value:@(flameSecond)];
    }
}
// 设置-聊天密码开启
-(void) channel:(WKChannel*)channel chatPwdOn:(BOOL)on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{@"chat_pwd_on":@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyChatPwdOn on:on groupNo:channel.channelId];
    }
}
// 更新设置-截屏通知
-(void) channel:(WKChannel*)channel screenshot:(BOOL) on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{@"screenshot":@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyScreenshot on:on groupNo:channel.channelId];
    }
}

// 更新历史消息查看
-(void) channel:(WKChannel*)channel allowViewHistoryMsg:(BOOL) on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{@"allow_view_history_msg":@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyAllowViewHistoryMsg on:on groupNo:channel.channelId];
    }
}


-(void) group:(NSString*)groupNo viewMemberInfo:(BOOL) on {
    [self updateGroupSetting:WKGroupSettingKeyAllowViewMemberInfo on:on groupNo:groupNo];
}

-(void) group:(NSString*)groupNo sendMemberCard:(BOOL) on {
    [self updateGroupSetting:WKGroupSettingKeyAllowSendMemberCard on:on groupNo:groupNo];
}

-(void) group:(NSString*)groupNo revokeMessage:(BOOL) on {
    [self updateGroupSetting:WKGroupSettingKeyAllowRevokeMessage on:on groupNo:groupNo];
}

-(void) group:(NSString*)groupNo membersVisible:(BOOL) on {
    [self updateGroupSetting:WKGroupSettingKeyAllowMembersVisible on:on groupNo:groupNo];
}

-(void) group:(NSString*)groupNo quitRemind:(BOOL) on {
    [self updateGroupSetting:WKGroupSettingKeyAllowMemberQuitRemind on:on groupNo:groupNo];
}

-(void) group:(NSString*)groupNo save:(BOOL) on {
    [self updateGroupSetting:WKGroupSettingKeySave on:on groupNo:groupNo];
}


-(void) group:(NSString*)groupNo nick:(BOOL) on {
    [self updateGroupSetting:WKGroupSettingKeyShowNick on:on groupNo:groupNo];
}

/// 群禁言
-(void) group:(NSString*)groupNo forbidden:(BOOL) on {
    [self updateGroupSetting:WKGroupSettingKeyForbidden on:on groupNo:groupNo];
}


/// 禁止邀请好友
-(void) group:(NSString*)groupNo invite:(BOOL) on {
    [self updateGroupSetting:WKGroupSettingKeyInvite on:on groupNo:groupNo];
}

// 更新用户设置
-(AnyPromise*) updateUserSetting:(NSString*)uid settingDict:(NSDictionary*)settingDict{
//    __weak typeof(self) weakSelf = self;
   return [[WKAPIClient sharedClient] PUT:[NSString stringWithFormat:@"users/%@/setting",uid] parameters:settingDict].then(^{
        // TODO 更新用户设置服务器会发出 channelUpdate命令 所以这里无需再进行更新操作
    }).catch(^(NSError *error){
        [[WKNavigationManager shared].topViewController.view showMsg:error.domain];
    });
}

-(BOOL) mute:(WKChannel*)channel hasChannelInfo:(BOOL*)hasChannelInfo {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        if(hasChannelInfo) {
            *hasChannelInfo = true;
        }
        return channelInfo.mute;
    }
    if(hasChannelInfo) {
        *hasChannelInfo = false;
    }
    return false;
}

-(BOOL) mute:(WKChannel*)channel {
   
    return [self mute:channel hasChannelInfo:nil];
}

-(BOOL) stick:(WKChannel*) channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return channelInfo.stick;
    }
    return false;
}

-(BOOL) receipt:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return channelInfo.receipt;
    }
    return false;
}

-(BOOL)chatPwdOn:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return [channelInfo settingForKey:WKChannelExtraKeyChatPwd defaultValue:false];
    }
    return false;
}

-(BOOL)screenshot:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return [channelInfo settingForKey:WKChannelExtraKeyScreenshot defaultValue:false];
    }
    return false;
}

-(BOOL) save:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return channelInfo.save;
    }
    return false;
}

-(BOOL) showNickName:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return channelInfo.showNick;
    }
    return false;
}

-(BOOL) forbidden:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return channelInfo.forbidden;
    }
    return false;
}

-(BOOL) invite:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return channelInfo.invite;
    }
    return false;
}

-(BOOL) flame:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return channelInfo.flame;
    }
    return false;
}

-(void) channel:(WKChannel*)channel revokeRemind:(BOOL)on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{WKChannelExtraKeyRevokeRemind:@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyRevokeRemind on:on groupNo:channel.channelId];
    }
}

-(BOOL)revokeRemind:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return [channelInfo settingForKey:WKChannelExtraKeyRevokeRemind defaultValue:false];
    }
    return false;
}

-(void) channel:(WKChannel*)channel joinGroupRemind:(BOOL)on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{WKChannelExtraKeyJoinGroupRemind:@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyJoinGroupRemind on:on groupNo:channel.channelId];
    }
}

-(void) channel:(WKChannel*)channel forbiddenAddFriend:(BOOL)on {
    if(channel.channelType == WK_PERSON) {
        [self updateUserSetting:channel.channelId settingDict:@{WKChannelExtraKeyJoinGroupRemind:@(on?1:0)}];
    }else {
        [self updateGroupSetting:WKGroupSettingKeyForbiddenAddFriend on:on groupNo:channel.channelId];
    }
}

-(BOOL) joinGroupRemind:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return [channelInfo settingForKey:WKChannelExtraKeyJoinGroupRemind defaultValue:false];
    }
    return false;
}

-(AnyPromise*) channel:(WKChannel*)channel remark:(NSString*)remark {
    if(channel.channelType == WK_PERSON) {
       return [self updateUserSetting:channel.channelId settingDict:@{WKChannelExtraKeyRemark:remark?:@""}];
    }else if(channel.channelType == WK_GROUP) {
       return [[WKGroupManager shared] groupRemark:channel.channelId remark:remark?:@""];
    }
    return nil;
}

-(NSString*) remark:(WKChannel*)channel {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(channelInfo) {
        return channelInfo.remark;
    }
    return nil;
}


@end
