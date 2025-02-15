//
//  WKPanelDefaultFuncItem.m
//  WuKongBase
//
//  Created by tt on 2020/2/23.
//

#import "WKPanelDefaultFuncItem.h"
#import "WKResource.h"
#import "WKConstant.h"
#import "WKMoreItemClickEvent.h"
#import "WKFuncItemButton.h"
#import "WuKongBase.h"
#import "WKConversationContext.h"
#import "WKCardContent.h"
#import "WKFuncGroupEditVC.h"
@interface WKPanelDefaultFuncItem ()



@end

@implementation WKPanelDefaultFuncItem

-(NSString*) sid {
    return @"";
}

- (nonnull WKFuncItemButton *)itemButton:(WKConversationInputPanel*)inputPanel {
    self.inputPanel = inputPanel;
    WKFuncItemButton *btn = [[WKFuncItemButton alloc] init];
    [btn setImage:[self itemIcon] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onPressed:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:[self title] forState:UIControlStateNormal];
    return btn;
}

-(void) onPressed:(WKFuncItemButton*)btn {
    [self.inputPanel switchPanel:[self panelID]];
}

-(NSString*) title {
    return @"";
}

-(UIImage*) itemIcon {
    
    return nil;
}

-(NSString*) panelID {
    return @"";
}

- (BOOL)support:(id<WKConversationContext>)context {
    return true;
}

-(BOOL) allowEdit {
    return true;
}

-(UIImage*) getImageNameForBase:(NSString*)name {
    return [WKApp.shared loadImage:name moduleID:@"WuKongBase"];
    //    return [currentModule ImageForResource:name];
//    return  [[WKResource shared] resourceForImage:name podName:@"WuKongBase_images"];
}

@end

@implementation WKPanelEmojiFuncItem

-(BOOL) allowEdit {
    return false;
}
- (NSString *)sid {
    return @"apm.wukong.emoji";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/FaceNormal"];
}

- (NSString *)panelID {
    return WKPOINT_PANEL_EMOJI;
}

- (NSString *)title {
    return LLang(@"表情");
}

@end

@interface WKPanelMentionFuncItem ()


@end
@implementation WKPanelMentionFuncItem

- (NSString *)sid {
    return @"apm.wukong.mention";
}
- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/MentionNormal"];
}

- (BOOL)support:(id<WKConversationContext>)context {
    return context.channel.channelType != WK_PERSON;
}


-(void) onPressed:(UIButton*)btn {
    [self.inputPanel inputInsertText:@"@"];
    [self.inputPanel.conversationContext showMentionUsers];
   
}
- (NSString *)title {
    return LLang(@"@");
}

@end


@interface WKPanelVoiceFuncItem ()

@end
@implementation WKPanelVoiceFuncItem

-(BOOL) allowEdit {
    return false;
}


- (NSString *)sid {
    return @"apm.wukong.voice";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/VoiceNormal"];
}

- (NSString *)panelID {
    return WKPOINT_PANEL_VOICE;
}
- (NSString *)title {
    return LLang(@"语音");
}
@end



@interface WKPanelImageFuncItem ()

@end
@implementation WKPanelImageFuncItem

-(BOOL) allowEdit {
    return false;
}


- (NSString *)sid {
    return @"apm.wukong.image";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/ImageNormal"];
}

-(void) onPressed:(UIButton*)btn {
   
    // 图片点击
    [[WKMoreItemClickEvent shared] onPhotoItemPressed:self.inputPanel.conversationContext];
}
- (NSString *)title {
    return LLang(@"图片");
}

@end

@implementation WKPanelMoreFuncItem

- (NSString *)sid {
    return @"apm.wukong.more";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/MoreNormal"];
}

- (void)onPressed:(UIButton *)btn {
    WKFuncGroupEditVC *vc = [[WKFuncGroupEditVC alloc] init];
    vc.conversationContext = self.inputPanel.conversationContext;
    vc.modalPresentationStyle = UIModalPresentationPopover;

    UIPopoverPresentationController *popoverController = vc.popoverPresentationController;
    if (popoverController) {
        popoverController.sourceView = self.inputPanel; // 这里使用 self.inputPanel 作为 sourceView，确保它是一个 UIView 类型
        popoverController.sourceRect = CGRectMake(self.inputPanel.bounds.size.width / 2, self.inputPanel.bounds.size.height / 2, 1.0, 1.0); // 设置源区域
        popoverController.permittedArrowDirections = 0; // 设置箭头方向, 可根据需求调整
    }

    [[WKNavigationManager shared].topViewController presentViewController:vc animated:YES completion:nil];

}
- (NSString *)title {
    return LLang(@"更多");
}

- (WKFuncGroupEditItemType)type {
    return WKFuncGroupEditItemTypeMore;
}
@end


@implementation WKPanelCardFuncItem

- (NSString *)sid {
    return @"apm.wukong.card";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/CardNormal"];
}


- (void)onPressed:(UIButton *)btn {
    id<WKConversationContext> conversationContext =  self.inputPanel.conversationContext;
    NSMutableArray<NSString*> *hiddenUsers = [NSMutableArray array];
    if(conversationContext.channel.channelType == WK_PERSON) {
        [hiddenUsers addObject:conversationContext.channel.channelId];
    }
    
    /// 获取群信息
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:conversationContext.channel];
    /// 获取成员信息
    WKChannelMember *memberOfMy = [[WKSDK shared].channelManager getMember:conversationContext.channel uid:[WKApp shared].loginInfo.uid];
    BOOL status = [channelInfo.extra[@"allow_send_member_card"] boolValue];

    /// 获取用户角色
    NSString *role = [WKApp shared].loginInfo.extra[@"role"];

    /// 先判断是否允许发送名片
    BOOL allowSendMemberCard = (channelInfo.extra[@"allow_send_member_card"] != nil && status);

    /// 判断是否是普通成员且角色不是管理员
    BOOL isRestrictedUser = (memberOfMy.role == WKMemberRoleCommon) && ![role isEqualToString:@"admin"];

    if (!allowSendMemberCard || isRestrictedUser) {
        [WKAlertUtil alert:LLangW(@"当前无权限", self)];
        return;
    }

    
    [[WKApp shared] invoke:WKPOINT_CONTACTS_SELECT param:@{@"mode":@"single",@"on_finished":^(NSArray<NSString*>*uids){
        if(uids && [uids count]<=0) {
            return;
        }
        NSString *uid = uids[0];
        WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:[[WKChannel alloc] initWith:uid channelType:WK_PERSON]];
        if(!channelInfo) {
            WKLogDebug(@"没有查到频道信息！");
            return;
        }
        __weak typeof(self) weakSelf = self;
        id<WKConversationContext> context = self.inputPanel.conversationContext;


        [WKAlertUtil alert:[NSString stringWithFormat:LLangW(@"发送%@的名片到当前聊天",weakSelf),channelInfo.displayName] buttonsStatement:@[LLangW(@"取消",weakSelf),LLangW(@"确定",weakSelf)] chooseBlock:^(NSInteger buttonIdx) {
            btn.selected = false;
            if(buttonIdx == 1) {
                [[WKNavigationManager shared] popViewControllerAnimated:YES];
                
                [context sendMessage:[WKCardContent cardContent:[channelInfo extraValueForKey:WKChannelExtraKeyVercode] uid:uid name:channelInfo.name avatar:channelInfo.logo]];
            }
        }];
       
       
    },@"on_cancel":^{
        btn.selected = false;
    },@"hidden_users":hiddenUsers}];
}

- (NSString *)title {
    return LLang(@"名片");
}

@end

