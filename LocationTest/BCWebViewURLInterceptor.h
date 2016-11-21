//
//  BCURLInterceptor.h
//  LocationTest
//
//  Created by Heping on 8/14/16.
//  Copyright © 2016 BONC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface BCWebViewURLInterceptor : NSObject
///对哪个webView进行地址拦截
@property (nonatomic,weak) UIWebView* webView;
///在哪个控制器中
@property (nonatomic,weak) UIViewController* viewController;
///默认初始化，拦截“mobile-service”
-(instancetype)init;
///能否拦截url
-(BOOL)canHandleURL:(NSURL*)url;
///拦截处理。注意：handlerURL:将会调用performAction:command:withParams:进行具体的处理。
-(void)handlerURL:(NSURL*)url;
///具体的拦截处理操作。用户可以重写这个函数，根据参数做出自己的个性化处理。
-(void)performObject:(NSString*)object command:(NSString*)command withParam:(id)jsonObject;
@end
