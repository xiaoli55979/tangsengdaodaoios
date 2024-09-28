//
//  InputDialog.m
//  WuKongBase
//
//  Created by 阿浩 on 28/9/2024.
//

#import "InputDialog.h"
#import "WuKongBase.h"

@implementation InputDialog

+ (void)showWithTitle:(NSString *)title
              message:(NSString *)message
            inputType:(InputType)inputType
      completionBlock:(InputCompletion)completion {
    
    // 获取当前的根视图控制器
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    // 创建 UIAlertController 弹框
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加一个文本输入框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = message;
        // 根据输入类型设置键盘
        textField.keyboardType = (inputType == InputTypeNumber) ? UIKeyboardTypeNumberPad : UIKeyboardTypeDefault;
    }];
    
    // 确定按钮
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:LLang(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alertController.textFields.firstObject;
        if (completion) {
            completion(textField.text);  // 将输入内容通过回调返回
        }
    }];
    
    // 取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil];
    
    // 添加按钮到弹框
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];
    
    // 显示弹框
    [rootViewController presentViewController:alertController animated:YES completion:nil];
}

@end
