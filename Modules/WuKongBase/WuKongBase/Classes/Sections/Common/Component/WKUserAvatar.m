#import "WKUserAvatar.h"
#import "WKApp.h"
#import "UIView+WK.h"
#import "UILabel+WK.h"
#import "NSMutableAttributedString+WK.h"
#import <WuKongBase/WuKongBase-Swift.h>

@interface WKUserAvatar ()
@property(nonatomic,strong) UIView *avatarBox;
@end

@implementation WKUserAvatar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.borderWidth = 0.0f;
        self.showRole = NO; // 默认不显示角色
        [self setupUI];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0.0f, 0.0f, WKDefaultAvatarSize.width, WKDefaultAvatarSize.height)];
}

- (void)setupUI {
    [self addSubview:self.avatarBox];
    [self.avatarBox addSubview:self.avatarImgView];
}

- (UIImageView *)avatarImgView {
    if(!_avatarImgView) {
        _avatarImgView = [[WKImageView alloc] initWithFrame:CGRectMake(self.borderWidth/2.0f, self.borderWidth/2.0f, self.frame.size.width - self.borderWidth, self.frame.size.height - self.borderWidth)];
        _avatarImgView.layer.masksToBounds = YES;
        _avatarImgView.layer.cornerRadius = _avatarImgView.frame.size.width * 0.4;
    }
    return _avatarImgView;
}

- (void)setUrl:(NSString *)url {
    _url = url;
    [_avatarImgView loadImage:[NSURL URLWithString:url] placeholderImage:[WKApp shared].config.defaultAvatar];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    self.avatarImgView.frame = CGRectMake(borderWidth/2.0f, borderWidth/2.0f, self.frame.size.width - borderWidth, self.frame.size.height - borderWidth);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.avatarBox setBackgroundColor:[WKApp shared].config.cellBackgroundColor];

    if (self.showRole && self.roleView) {
        // 让 roleView 显示在头像的底部内部
        self.roleView.lim_bottom = self.avatarBox.lim_bottom - 0.5f; // 调整位置，略微上移，确保在内部
        self.roleView.lim_centerX_parent = self.avatarBox; // 居中
    } else {
        [self.roleView removeFromSuperview]; // 确保不显示
    }
}


- (UIView *)avatarBox {
    if(!_avatarBox) {
        _avatarBox = [[UIView alloc] initWithFrame:self.bounds];
        _avatarBox.layer.masksToBounds = YES;
        _avatarBox.layer.cornerRadius = _avatarBox.frame.size.width * 0.4;
    }
    return _avatarBox;
}

- (void)setRole:(WKMemberRole)role {
    if (!self.showRole) {
        [self.roleView removeFromSuperview];
        _roleView = nil;
        return;
    }

    [self.roleView removeFromSuperview]; // 先移除旧的

    NSString *roleName = @"";
    UIColor *roleColor = [UIColor clearColor];

    if (role == WKMemberRoleManager) {
        roleName = LLang(@"管理员");
        roleColor = WKApp.shared.config.themeColor;
    } else if (role == WKMemberRoleCreator) {
        roleName = LLang(@"群主");
        roleColor = [UIColor orangeColor];
    } else {
        return;
    }

    UIView *roleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 30.0f, 15.0f)];
    roleView.layer.masksToBounds = YES;
    roleView.backgroundColor = WKApp.shared.config.cellBackgroundColor;
    
    UILabel *roleNameLbl = [[UILabel alloc] init];
    roleNameLbl.font = [WKApp.shared.config appFontOfSize:8.0f];
    roleNameLbl.textColor = roleColor;
    roleNameLbl.text = roleName;
    
    [roleView addSubview:roleNameLbl];
    [roleNameLbl sizeToFit];
    
    CGFloat width = MAX(roleNameLbl.lim_width + 4.0f, roleView.lim_width);
    roleView.lim_width = width;
    roleView.layer.cornerRadius = roleView.lim_height / 2.0f;
    
    roleNameLbl.lim_centerX_parent = roleView;
    roleNameLbl.lim_centerY_parent = roleView;
    
    self.roleView = roleView;
    [self.avatarBox addSubview:self.roleView]; // 添加到 avatarBox
    [self setNeedsLayout]; // 触发布局更新
}


@end
