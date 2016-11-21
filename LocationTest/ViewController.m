//
//  ViewController.m
//  LocationTest
//
//  Created by Heping on 8/14/16.
//  Copyright © 2016 BONC. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *privateWebView;
@property (nonatomic,strong) BCWebViewURLInterceptor* interceptor;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
// Do any additional setup after loading the view, typically from a nib.
    NSString* path=[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"locationSpeed"];
    path=[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* url=[NSURL URLWithString:path];
//    NSURL* url=[NSURL URLWithString:@"http://172.16.73.47:8080/gs/index.html"];
    NSURLRequest* request=[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    [self.privateWebView loadRequest:request];
    
    self.interceptor=[[BCWebViewURLInterceptor alloc]init];
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
    self.title=[self.privateWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSLog(@"finish web loading......");
}
@end
