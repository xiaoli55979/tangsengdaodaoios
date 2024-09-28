//
//  WKMeAvatarCell.h
//  WuKongBase
//
//  Created by tt on 2020/6/23.
//

#import "WuKongBase.h"
#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKGroupAvatarModel : WKViewItemModel
@property(nonatomic,strong) WKChannel *channel;
@end

@interface WKGroupAvatarCell : WKViewItemCell

@end

NS_ASSUME_NONNULL_END
