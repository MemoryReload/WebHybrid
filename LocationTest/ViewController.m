//
//  ViewController.m
//  LocationTest
//
//  Created by Heping on 8/14/16.
//  Copyright © 2016 BONC. All rights reserved.
//

#import "ViewController.h"

#import "QRCodeViewController.h"

@interface ViewController ()<UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *privateWebView;
@property (nonatomic,strong) BCWebViewURLInterceptor* interceptor;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title=NSLocalizedString(@"WebTest", nil);
    // Do any additional setup after loading the view, typically from a nib.
    NSString* path=[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"locationSpeed"];
    path=[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* url=[NSURL URLWithString:path];
//    NSURL* url=[NSURL URLWithString:@"http://172.16.73.149:8080/gansu/index.html"];
    NSURLRequest* request=[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    [self.privateWebView loadRequest:request];
    
    self.interceptor=[[BCWebViewURLInterceptor alloc]initWithInterceptedURLScheme:@"mobile-service"];
    self.interceptor.webView=self.privateWebView;
    self.interceptor.viewController=self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([self.interceptor canHandleURL:request.URL]) {
        [self.interceptor handlerURL:request.URL];
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"start web loading......");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"finish web loading......");

}
@end
