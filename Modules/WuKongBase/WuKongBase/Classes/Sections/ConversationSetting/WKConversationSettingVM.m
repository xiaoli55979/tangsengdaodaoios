//
//  WKConversationSettingVM.m
//  WuKongBase
//
//  Created by tt on 2020/1/21.
//

#import "WKConversationSettingVM.h"
#import "WuKongBase.h"
#import "WKFormItemModel.h"
#import "WKFormSection.h"
#import "WKLabelItemCell.h"
#import "WKSwitchItemCell.h"
#import "WKIconItemCell.h"
#import "WKResource.h"
#import "WKGroupManager.h"
#import "WKButtonItemCell.h"
#import "WKMultiLabelItemCell.h"
#import "WKTableSectionUtil.h"
#import "WKGroupQRCodeVC.h"
#import "WKMeAvatarCell.h"
#import "WKGroupAvatarVC.h"
#import "WKGroupAvatarCell.h"
#import "InputDialog.h"

@interface WKConversationSettingVM ()<WKChannelManagerDelegate>

@property(nonatomic,strong) WKChannelInfo *_channelInfo;

@end

@implementation WKConversationSettingVM

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[WKSDK shared].channelManager addDelegate:self];
        
    }
    return self;
}

- (void)dealloc {
    [[WKSDK shared].channelManager removeDelegate:self];
}

-(void) syncMembersIfNeed{
    if(self.channel.channelType == WK_GROUP) {
        [[WKGroupManager shared] syncMemebers:self.channel.channelId];
    }
    
}


- (NSArray<NSDictionary *> *)tableSectionMaps {
    BOOL isCreatorOrManager = [self isManagerOrCreatorForMe];
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"channel"] = self.channel;
    param[@"is_creator_or_manager"] = @(isCreatorOrManager);
    if(self.channelInfo) {
        param[@"channel_info"] = self.channelInfo;
    }
    param[@"refresh"] = ^ {
        [self reloadData];
    };
    param[@"context"] = self.context;
    [self registerSections];
    NSArray *items = [WKApp.shared invokes:WKPOINT_CATEGORY_CHANNELSETTING param:param];
    return items;
}

- (WKChannelMember *)memberOfMe {
    if(!_memberOfMe) {
        _memberOfMe = [[WKSDK shared].channelManager getMember:self.channel uid:[WKApp shared].loginInfo.uid];
    }
    return _memberOfMe;
}

-(BOOL) isManagerForMe {
    return self.memberOfMe && self.memberOfMe.role == WKMemberRoleManager;
}

-(BOOL) isCreatorForMe {
    return self.memberOfMe && self.memberOfMe.role == WKMemberRoleCreator;
}

-(BOOL) isManagerOrCreatorForMe {
    return [self isManagerForMe] || [self isCreatorForMe];
}


- (NSInteger)memberCount {
    if(self.groupType == WKGroupTypeSuper) {
        return [self memberCount:self.channelInfo];
    }else {
        return [[WKSDK shared].channelManager getMemberCount:self.channel];
    }
    return 0;
}

-(NSInteger) memberCount:(WKChannelInfo*)channelInfo {
    if(channelInfo && channelInfo.extra[@"member_count"]) {
        return [channelInfo.extra[@"member_count"] integerValue];
    }
    return 0;
}

- (WKMemberRole)memberRole {
    if(self.groupType == WKGroupTypeSuper) {
        if(self.channelInfo && self.channelInfo.extra[@"role"]) {
            return [self.channelInfo.extra[@"role"] integerValue];
        }
    }else {
        WKChannelMember *memberOfMe = self.memberOfMe;
        if(memberOfMe) {
            return  memberOfMe.role;
        }
    }
    return WKMemberRoleCommon;
}

-(WKGroupType) groupType {
    
    return [self groupType:self.channelInfo];
}

-(WKGroupType) groupType:(WKChannelInfo*)channelInfo {
    return [WKChannelUtil groupType:channelInfo];
}

-(void) registerSections {
    __weak typeof(self) weakSelf = self;
    
    // 是否有公告
    BOOL hasNotice  = self.channelInfo && self.channelInfo.notice && ![self.channelInfo.notice isEqualToString:@""];
    
    // 在群内的名字
    NSString *nameInGroup = self.memberOfMe.memberName;
    if(self.memberOfMe.memberRemark && ![self.memberOfMe.memberRemark isEqualToString:@""]) {
        nameInGroup = self.memberOfMe.memberRemark;
    }

    
    /// 只有管理员才能设置
    [[WKApp shared] setMethod:@"channelsetting.groupavatar" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        /// 只有管理员和创建者可以设置
        if (![self isManagerOrCreatorForMe]) {
            return nil;
        }
        if(self.channel.channelType != WK_GROUP) {
            return nil;
        }
        return @{
            @"height":@(0.0f),
            @"items": @[
                @{
                    @"class":WKGroupAvatarModel.class,
                    @"label":LLang(@"群头像"),
                    @"showBottomLine":@(YES),
                    @"channel":weakSelf.channel,
                    @"onClick":^{
                        WKGroupAvatarVC *vc = [WKGroupAvatarVC new];
                        vc.channel = weakSelf.channel;
                        [[WKNavigationManager shared] pushViewController:vc animated:YES];
                        
                    }
                },
            ],
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:90100];
    
    [[WKApp shared] setMethod:@"channelsetting.groupname" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        if(channel.channelType != WK_GROUP) {
            return nil;
        }
        return @{
            @"height": @(0.0f),
            @"items": @[
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"群聊名称"),
                    @"value":self.channelInfo&&self.channelInfo.name?self.channelInfo.name:@"",
                    @"showBottomLine":@(YES),
                    @"showTopLine":@(NO),
                    @"onClick":^{
                        if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(settingOnGroupNameClick:)]) {
                            [weakSelf.delegate settingOnGroupNameClick:weakSelf];
                        }
                    }
                }
            ],
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:90000];

    [[WKApp shared] setMethod:@"channelsetting.groupqrcode" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        if(channel.channelType != WK_GROUP) {
            return nil;
        }
        return @{
            @"height": @(0.0f),
            @"items":@[
                @{
                    @"class":WKIconItemModel.class,
                    @"label":LLang(@"群二维码"),
                    @"icon":[self imageName:@"Conversation/Setting/IconQrcode"],
                    @"width":@(24.0f),@"height":@(24.0f),
                    @"showBottomLine":@(YES),
                    @"onClick":^{
                        WKGroupQRCodeVC *vc = [WKGroupQRCodeVC new];
                        vc.channel = weakSelf.channel;
                        [[WKNavigationManager shared] pushViewController:vc animated:YES];
                    }
                }
            ],
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89800];
    
    [[WKApp shared] setMethod:@"channelsetting.groupintro" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        BOOL isCreatorOrManager = [param[@"is_creator_or_manager"] boolValue];
        if(channel.channelType != WK_GROUP) {
            return nil;
        }
        return @{
            @"height":@(0.0f),
            @"items": @[
                @{
                    @"class": hasNotice?WKMultiLabelItemModel.class:WKLabelItemModel.class,
                    @"label":LLang(@"群公告"),
                    @"value": hasNotice?self.channelInfo.notice:LLang(@"未设置"),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace": isCreatorOrManager?[NSNull null]:@(0.0f),
                    @"onClick":^{
                        if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(settingOnGroupNoticeClick:)]) {
                            [weakSelf.delegate settingOnGroupNoticeClick:weakSelf];
                        }
                    }
                }
            ]
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89700];
    
    
    [[WKApp shared] setMethod:@"channelsetting.nameInGroup" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        if(channel.channelType != WK_GROUP) {
            return nil;
        }
        return  @{
            @"height":WKSectionHeight,
            @"items":@[
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"我在本群的昵称"),
                    @"value":nameInGroup?:@"",
                    @"showBottomLine":@(YES),
                    @"showTopLine":@(NO),
                    @"onClick":^{
                        if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(settingOnGroupNoticeClick:)]) {
                            [weakSelf.delegate settingOnNickNameInGroup:weakSelf];
                        }
                    }
                },
               ]

        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89600];
    
    [[WKApp shared] setMethod:@"channelsetting.mute" handler:^id _Nullable(id  _Nonnull param) {
        return @{
            @"height":@(0.0f),
            @"items":@[
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"消息免打扰"),
                    @"on":@(self.channelInfo?self.channelInfo.mute:false),
                    @"showBottomLine":@(YES),
                    @"showTopLine":@(NO),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] channel:self.channel mute:on];
                    }
                }
            ]
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89500];
    
    [[WKApp shared] setMethod:@"channelsetting.top" handler:^id _Nullable(id  _Nonnull param) {
        return @{
            @"height":@(0.0f),
            @"items":@[
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"置顶聊天"),
                    @"on":@(self.channelInfo?self.channelInfo.stick:false),
                    @"showBottomLine":@(YES),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] channel:self.channel stick:on];
                    }
                }
            ]
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89400];
    
    
    /// 聊天密码 - 基于用户
    [[WKApp shared] setMethod:@"channelsetting.chatpwd" handler:^id _Nullable(id  _Nonnull param) {
        return  @{
            @"height":@(0.0f),
            @"items":@[
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"聊天密码"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"chat_pwd_on"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] channel:self.channel chatPwdOn:on];
                    }
                },
               ]
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89361];
    
    /// 消息回执
    [[WKApp shared] setMethod:@"channelsetting.msgback" handler:^id _Nullable(id  _Nonnull param) {
        return  @{
            @"height":@(0.0f),
            @"items":@[
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"消息回执"),
                    @"on":@(self.channelInfo?self.channelInfo.receipt:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] channel:self.channel receipt:on];
                    }
                },
               ]
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89360];

    
    /// 是否显示昵称
    [[WKApp shared] setMethod:@"channelsetting.msgback" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        if(channel.channelType != WK_GROUP) {
            return nil;
        }
        return  @{
            @"height":@(0.0f),
            @"items":@[
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"是否显示昵称"),
                    @"on":@(self.channelInfo?self.channelInfo.showNick:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] group:self.channel.channelId nick:on];
                        [[WKNavigationManager shared] popToRootViewControllerAnimated:YES];
                    }
                },
               ]
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89359];
    
    [[WKApp shared] setMethod:@"channelsetting.groupsave" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        if(channel.channelType != WK_GROUP) {
            return nil;
        }
        return @{
            @"height":@(0.0f),
            @"items":@[
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"保存到通讯录"),
                    @"on":@(self.channelInfo?self.channelInfo.save:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] group:self.channel.channelId save:on];
                    }
                }
            ]
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89450];
    
    /// 添加管理员配置
    [self groupSettingList];

    
    [[WKApp shared] setMethod:@"channelsetting.balckname" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        if(channel.channelType != WK_PERSON) {
            return nil;
        }
        return  @{
            @"height":WKSectionHeight,
            @"items":@[
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":self.channelInfo && self.channelInfo.status == WKChannelStatusBlacklist?LLangW(@"拉出黑名单", weakSelf):LLangW(@"拉入黑名单", weakSelf),
                    @"value":@"",
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"showTopLine":@(NO),
                    @"onClick":^{
                        if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(settingOnBlacklist:action:)]) {
                           [weakSelf.delegate settingOnBlacklist:weakSelf action:self.channelInfo && self.channelInfo.status != WKChannelStatusBlacklist];
                       }
                    }},
               ]

        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:88950];
    
    [[WKApp shared] setMethod:@"channelsetting.report" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        CGFloat sectionHeight = 0.0f;
        if(channel.channelType == WK_GROUP) {
            sectionHeight = WKSectionHeight.floatValue;
        }
        return  @{
            @"height":@(sectionHeight),
            @"items":@[
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"投诉"),
                    @"value":@"",
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"showTopLine":@(NO),
                    @"onClick":^{
                       if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(settingOnReport:)]) {
                           [weakSelf.delegate settingOnReport:weakSelf];
                       }
                    }
                },
               ]

        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:88900];
    
    [[WKApp shared] setMethod:@"channelsetting.clearchat" handler:^id _Nullable(id  _Nonnull param) {
        return  @{
            @"height":WKSectionHeight,
            @"items":@[
                @{
                    @"class":WKButtonItemModel.class,
                    @"title":LLang(@"清空聊天记录"),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"showTopLine":@(NO),
                    @"onClick":^{
                        if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(settingOnClearMessages:)]) {
                            [weakSelf.delegate settingOnClearMessages:weakSelf];
                        }
                    }
                },
               ]

        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:88800];
    
    [[WKApp shared] setMethod:@"channelsetting.groupexit" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        if(channel.channelType != WK_GROUP) {
            return nil;
        }
        return  @{
            @"height":@(0.0f),
            @"items":@[
                @{
                    @"class":WKButtonItemModel.class,
                    @"title":LLang(@"删除并退出"),
                    @"showBottomLine":@(NO),
                    @"bottomLeftSpace":@(0.0f),
                    @"showTopLine":@(NO),
                    @"onClick":^{
                           if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(settingOnGroupExit:)]) {
                               [weakSelf.delegate settingOnGroupExit:weakSelf];
                           }
                    }
                },
               ]
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:88700];

}

/// 群管理设置
- (void)groupSettingList {
    
    __weak typeof(self) weakSelf = self;
    
    /// 群设置
    [[WKApp shared] setMethod:@"channelsetting.groupsetting" handler:^id _Nullable(id  _Nonnull param) {
        /// 只有管理员和创建者可以设置
        if (![self isManagerOrCreatorForMe]) {
            return nil;
        }
        if(self.channel.channelType != WK_GROUP) {
            return nil;
        }
        
        WKChannel *channel = param[@"channel"];
        CGFloat sectionHeight = 0.0f;
        if(channel.channelType == WK_GROUP) {
            sectionHeight = WKSectionHeight.floatValue;
        }
        return  @{
            @"height":@(sectionHeight),
            @"items":@[
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"群成员禁言"),
                    @"on":@(self.channelInfo?self.channelInfo.forbidden:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] group:self.channel.channelId forbidden:on];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"群聊邀请确认"),
                    @"on":@(self.channelInfo?self.channelInfo.invite:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] group:self.channel.channelId invite:on];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"截屏通知"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"screenshot"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] channel:self.channel screenshot:on];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"撤回消息提醒"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"revoke_remind"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] channel:self.channel revokeRemind:on];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"加群提醒"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"join_group_remind"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] channel:self.channel joinGroupRemind:on];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"禁止添加好友"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"forbidden_add_friend"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] channel:self.channel forbiddenAddFriend:on];
                    }
                },

                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"阅后即焚"),
                    @"on":@(self.channelInfo?self.channelInfo.flame:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        if (on) {
                            [InputDialog showWithTitle:LLang(@"阅后即焚")
                                               message:LLang(@"请输入阅后即焚时长(S)")
                                             inputType:InputTypeNumber
                                       completionBlock:^(NSString *inputText) {
                                [[WKChannelSettingManager shared] channel:self.channel flameSecond:[inputText integerValue]];
                                       }];

                        }
                        [[WKChannelSettingManager shared] channel:self.channel flame:on];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"允许查看历史消息"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"allow_view_history_msg"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] updateGroupManagerSetting:WKGroupSettingKeyAllowViewHistoryMsg on:on groupNo:self.channel.channelId];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"退群提醒"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"allow_member_quit_remind"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] updateGroupManagerSetting:WKGroupSettingKeyAllowMemberQuitRemind on:on groupNo:self.channel.channelId];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"查看成员信息"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"allow_view_member_info"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] updateGroupManagerSetting:WKGroupSettingKeyAllowViewMemberInfo on:on groupNo:self.channel.channelId];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"群成员是否可见"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"allow_members_visible"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] updateGroupManagerSetting:WKGroupSettingKeyAllowMembersVisible on:on groupNo:self.channel.channelId];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"允许消息撤回"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"allow_revoke_message"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] updateGroupManagerSetting:WKGroupSettingKeyAllowRevokeMessage on:on groupNo:self.channel.channelId];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"允许发送名片"),
                    @"on":@(self.channelInfo?[self.channelInfo.extra[@"allow_send_member_card"] boolValue]:false),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        [[WKChannelSettingManager shared] updateGroupManagerSetting:WKGroupSettingKeyAllowSendMemberCard on:on groupNo:self.channel.channelId];
                    }
                },
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"添加群管理员"),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onClick":^{
                       if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(settingMember:)]) {
                           [weakSelf.delegate settingMember:weakSelf];
                       }
                    }
                },
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"删除群管理员"),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onClick":^{
                       if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(removeMember:)]) {
                           [weakSelf.delegate removeMember:weakSelf];
                       }
                    }
                },
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"转让群主身份"),
                    @"showBottomLine":@(YES),
                    @"bottomLeftSpace":@(0.0f),
                    @"onClick":^{
                       if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(changeGroupMember:)]) {
                           [weakSelf.delegate changeGroupMember:weakSelf];
                       }
                    }
                },
               ]

        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89355];

}


-(AnyPromise*) addBlacklist {
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"user/blacklist/%@",self.channelInfo.channel.channelId?:@""] parameters:nil];
}
-(AnyPromise*) deleteBlacklist {
    return [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"user/blacklist/%@",self.channelInfo.channel.channelId?:@""] parameters:nil];
}


-(AnyPromise*) onlineMembers:(NSArray<NSString*>*)users {
    __weak typeof(self) weakSelf = self;
  return  [WKAPIClient.sharedClient POST:@"user/online" parameters:users model:WKUserOnlineResp.class].then(^(NSArray<WKUserOnlineResp*>*onlines){
      weakSelf.onlineMembers = onlines;
      return onlines;
    });
}

-(WKUserOnlineResp*) memberOnline:(NSString*)uid {
    if(!self.onlineMembers || self.onlineMembers.count == 0) {
        return nil;
    }
    for (WKUserOnlineResp *onlineResp in self.onlineMembers) {
        if([onlineResp.uid isEqualToString:uid]) {
            return onlineResp;
        }
    }
    return nil;
}


-(UIImage*) imageName:(NSString*)name {
    return [WKApp.shared loadImage:name moduleID:@"WuKongBase"];
}

- (WKChannelInfo *)channelInfo {
    if(!self._channelInfo) {
        self._channelInfo = [[WKSDK shared].channelManager getChannelInfo:self.channel];
    }
    return self._channelInfo;
}

-(AnyPromise*) requestGroupMemberInvite:(NSArray<NSString*>*)uids remark:(NSString*)remark {
   return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"groups/%@/member/invite",self.channel.channelId] parameters:@{@"uids":uids?:@[],@"remark":remark?:@""}];
}

#pragma mark - WKChannelManagerDelegate
- (void)channelInfoUpdate:(WKChannelInfo *)channelInfo oldChannelInfo:(WKChannelInfo * _Nullable)oldChannelInfo{
    if(![self.channel isEqual:channelInfo.channel]) {
        return;
    }
    self._channelInfo = [[WKSDK shared].channelManager getChannelInfo:self.channel];
    [self reloadData];
    if(_delegate && [_delegate respondsToSelector:@selector(settingOnChannelUpdate:)]) {
        [_delegate settingOnChannelUpdate:self];
    }
    WKGroupType groupType = [self groupType:channelInfo];
    if(groupType == WKGroupTypeSuper) {
        if(oldChannelInfo && [self memberCount:oldChannelInfo]!=[self memberCount:channelInfo]) {
            if(_delegate && [_delegate respondsToSelector:@selector(settingOnTopNMembersUpdate:)]) {
                [_delegate settingOnTopNMembersUpdate:self];
            }
        }
     
    }
}
@end


