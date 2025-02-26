#import <UIKit/UIKit.h>
#import "WKImageView.h"
#import "WKResource.h"
#import "WKConversationInputPanel.h"
#import "WKAvatarUtil.h"
#import "WKCircularProgressView.h"
#import "WKReactionBaseView.h"
#import "UILabel+WK.h"
#import "NSMutableAttributedString+WK.h"
#import "WKTapLongTapOrDoubleTapGestureRecognizerEvent.h"

#define WKDefaultAvatarSize CGSizeMake(50.0f,50.0f)

NS_ASSUME_NONNULL_BEGIN

@interface WKUserAvatar : UIView

@property(nonatomic,copy) NSString *url;
@property(nonatomic,copy) NSString *uid;
@property(nonatomic,assign) CGFloat borderWidth;
@property(nonatomic,strong) WKImageView *avatarImgView;
@property(nonatomic,strong) UIView *roleView;
@property(nonatomic,assign) BOOL showRole; // 是否显示角色（默认 NO）

- (void)setRole:(WKMemberRole)role;

@end

NS_ASSUME_NONNULL_END
