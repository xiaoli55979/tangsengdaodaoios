//
//  InputDialog.h
//  WuKongBase
//
//  Created by 阿浩 on 28/9/2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^InputCompletion)(NSString *inputText);

// 输入类型的枚举：数字或文本
typedef NS_ENUM(NSUInteger, InputType) {
    InputTypeNumber, // 数字输入
    InputTypeText    // 文本输入
};

@interface InputDialog : NSObject

// 弹出输入框的方法，输入类型由 inputType 控制
+ (void)showWithTitle:(NSString *)title
              message:(NSString *)message
            inputType:(InputType)inputType
      completionBlock:(InputCompletion)completion;

@end

NS_ASSUME_NONNULL_END
