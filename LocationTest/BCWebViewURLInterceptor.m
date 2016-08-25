//
//  BCURLInterceptor.m
//  LocationTest
//
//  Created by Heping on 8/14/16.
//  Copyright © 2016 BONC. All rights reserved.
//

#import "BCWebViewURLInterceptor.h"
#import <CoreLocation/CoreLocation.h>
#import "QRCodeViewController.h"

@interface BCWebViewURLInterceptor()<CLLocationManagerDelegate,QRCodeViewControllerDelegate>
@property (nonatomic,retain) NSString* interceptedScheme;
@property (nonatomic,strong) CLLocationManager* locationManager;
@end

@implementation BCWebViewURLInterceptor

#pragma mark - Initialization  Method

-(instancetype)init
{
    self=[super init];
    if (self) {
        self.interceptedScheme=@"mobile-service";
    }
    return self;
}

-(instancetype)initWithInterceptedURLScheme:(NSString*)scheme
{
    self=[super init];
    if (self) {
        self.interceptedScheme=scheme;
    }
    return self;
}


#pragma mark - URL Handling Method

-(BOOL)canHandleURL:(NSURL*)url
{
    if (url.scheme&&self.interceptedScheme&&[url.scheme isEqualToString:self.interceptedScheme]) {
        return YES;
    }
    return NO;
}

-(void)handlerURL:(NSURL*)url
{
    if (!([self canHandleURL:url]&&url.query)) {
        return ;
    }
    NSString *action,*command;
    NSArray* paramsList;
    NSArray* queryList=[url.query componentsSeparatedByString:@"&"];
    for (NSString* keyValuePairs in queryList) {
        NSArray* keyValueArray=[keyValuePairs componentsSeparatedByString:@"="];
        if (keyValueArray.count!=2) continue;
        if ([[keyValueArray firstObject] isEqualToString:@"action"]) {
            action=[keyValueArray lastObject];
        }
        else if([[keyValueArray firstObject] isEqualToString:@"command"]){
            command=[keyValueArray lastObject];
        }
        else if([[keyValueArray firstObject] isEqualToString:@"params"]){
            NSString* paramsStr=[keyValueArray lastObject];
            NSError* error;
            NSArray *params= [NSJSONSerialization JSONObjectWithData:[paramsStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                NSLog(@"params can not serialized with json formmat,Error:%@",error);
            }
            paramsList=params;
        }
    };
    
    if (action&&command) {
        [self performAction:action command:command withParams:paramsList];
    }
}

-(void)performAction:(NSString*)action command:(NSString*)command withParams:(NSArray*)params
{
    NSLog(@"action=%@,command:%@,params=%@",action,command,params);
    //定位服务
    if ([action isEqualToString:@"location"]) {
        //启动定位
        if ([command isEqualToString:@"start"]) {
            [self startLocationManager];
        }
        //关闭定位
        else if ([command isEqualToString:@"stop"]){
            [self stopLocationManager];
        }
    }
    //QR二维码扫描
    else if ([action isEqualToString:@"scanQRCode"]){
        if ([command isEqualToString:@"scan"]) {
            [self scanQRCode];
        }
    }
}

#pragma mark -  Location  Handling  Method

- (void)startLocationManager
{
    if (!self.locationManager) {
        self.locationManager=[[CLLocationManager alloc]init];
        self.locationManager.delegate=self;
        self.locationManager.pausesLocationUpdatesAutomatically=NO;
        if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusNotDetermined&&[self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
    }
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocationManager
{
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
        self.locationManager=nil;
    }
}

#pragma mark -  QRCode    Handling  Method

- (void)scanQRCode
{
    if (self.viewController) {
        QRCodeViewController* scannerVC=[[QRCodeViewController alloc]init];
        scannerVC.delegate=self;
        if (self.viewController.navigationController) {
            [self.viewController.navigationController pushViewController:scannerVC animated:YES];
        }
        else{
            [self.viewController presentViewController:scannerVC animated:YES completion:nil];
        }
    }
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation* location=[locations lastObject];
    NSDate* date=location.timestamp;
    NSDateFormatter* fmt=[[NSDateFormatter alloc]init];
    fmt.dateStyle=kCFDateFormatterShortStyle;
    fmt.timeStyle=kCFDateFormatterLongStyle;
    NSString* dateStr=[fmt stringFromDate:date];
    NSString* jsString=[NSString stringWithFormat:@"window.locationManager.successHandler({\"longitude\":\"%g\",\"latitude\":\"%g\",\"speed\":\"%g\",\"timestamp\":\"%@\"})",location.coordinate.longitude,location.coordinate.latitude,location.speed,dateStr];
    if (self.webView) {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSString* jsString=[NSString stringWithFormat:@"window.locationManager.errorHandler(\"%@\")",error.description];
    if (self.webView) {
         [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    }
}

#pragma mark - QRCodeViewControllerDelegate

-(void)viewController:(QRCodeViewController*)viewController  didFinishScanWithInformation:(NSString*)qrCodeInfo
{
    NSString *jsString=[NSString stringWithFormat:@"window.qrcodeScanner.successHandler(\"%@\")",qrCodeInfo];
    if (self.webView) {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    }
}

-(void)didCancleScanWithViewController:(QRCodeViewController*)viewController
{
    NSString* jsString=@"window.qrcodeScanner.errorHandler(\"QRCodeScanner operation cancled.\")";
    if (self.webView) {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    }
}

-(void)viewController:(QRCodeViewController*)viewController didFailedScanWithError:(NSError*)error
{
    NSString* jsString=[NSString stringWithFormat:@"window.qrcodeScanner.errorHandler(\"%@\")",error.localizedDescription];
    if (self.webView) {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    }
}
@end
