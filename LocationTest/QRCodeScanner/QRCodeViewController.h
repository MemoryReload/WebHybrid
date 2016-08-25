//
//  BCURLInterceptor.h
//  LocationTest
//
//  Created by Heping on 8/14/16.
//  Copyright © 2016 BONC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol  QRCodeViewControllerDelegate;

///QRCode扫码器实例控制器
@interface QRCodeViewController : UIViewController
@property (nonatomic,weak) id<QRCodeViewControllerDelegate> delegate;
@end

///QRCodeViewController的协议
@protocol QRCodeViewControllerDelegate <NSObject>
///QRCodeViewController扫描二维码成功是调用
-(void)viewController:(QRCodeViewController*)viewController  didFinishScanWithInformation:(NSString*)qrCodeInfo;
///QRCodeViewController被用户取消操作时调用
-(void)didCancleScanWithViewController:(QRCodeViewController*)viewController;
///QRCodeViewController在扫码过程中发生错误时调用
-(void)viewController:(QRCodeViewController*)viewController didFailedScanWithError:(NSError*)error;
@end