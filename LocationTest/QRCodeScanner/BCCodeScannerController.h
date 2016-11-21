//
//  BCURLInterceptor.h
//  LocationTest
//
//  Created by Heping on 8/14/16.
//  Copyright © 2016 BONC. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FOCUS_IMG_NAME       @"focus.png"
#define SCANNER_IMG_NAME     @"qrcode_scanner"

@protocol  BCCodeScannerControllerDelegate;

///QRCode扫码器实例控制器
@interface BCCodeScannerController : UIViewController
///返回按钮，用户可以通过属性自定义按钮外观
@property (strong, nonatomic,readonly) UIButton *backButton;
///相册按钮，用户可以通过属性自定义按钮外观
@property (strong, nonatomic,readonly) UIButton *albumButton;
///控制器标题视图，用户可以通过属性自定义title字体颜色等
@property (strong, nonatomic,readonly) UILabel  *titleView;
///扫描二维码操作的代理对象
@property (nonatomic,weak) id<BCCodeScannerControllerDelegate> delegate;
@end

///BCCodeScannerController的协议
@protocol BCCodeScannerControllerDelegate <NSObject>
///BCCodeScannerController扫描二维码成功时调用
-(void)viewController:(BCCodeScannerController*)viewController  didFinishScanWithInformation:(NSString*)qrCodeInfo;
///BCCodeScannerController被用户取消操作时调用
-(void)didCancleScanWithViewController:(BCCodeScannerController*)viewController;
///BCCodeScannerController在扫码过程中发生错误时调用
-(void)viewController:(BCCodeScannerController*)viewController didFailedScanWithError:(NSError*)error;
@end
