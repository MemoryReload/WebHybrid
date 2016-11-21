//
//  BCURLInterceptor.m
//  LocationTest
//
//  Created by Heping on 8/14/16.
//  Copyright © 2016 BONC. All rights reserved.
//

#import "BCWebViewURLInterceptor.h"
#import <CoreLocation/CoreLocation.h>
#import "BCCodeScannerController.h"

@interface BCWebViewURLInterceptor()<CLLocationManagerDelegate,BCCodeScannerControllerDelegate>
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
    NSString *object,*command;
    id param;
    NSArray* queryList=[url.query componentsSeparatedByString:@"&"];
    for (NSString* keyValuePairs in queryList) {
        NSArray* keyValueArray=[keyValuePairs componentsSeparatedByString:@"="];
        if (keyValueArray.count!=2) continue;
        if ([[keyValueArray firstObject] isEqualToString:@"object"]) {
            object=[keyValueArray lastObject];
        }
        else if([[keyValueArray firstObject] isEqualToString:@"command"]){
            command=[keyValueArray lastObject];
        }
        else if([[keyValueArray firstObject] isEqualToString:@"params"]){
            NSString* paramsStr=[keyValueArray lastObject];
            NSError* error;
            id jsonObject= [NSJSONSerialization JSONObjectWithData:[paramsStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                NSLog(@"JSONSerialization Error:%@",error);
            }
            param=jsonObject;
        }
    };
    
    if (object&&command) {
        [self performObject:object command:command withParam:param];
    }
}

-(void)performObject:(NSString*)object command:(NSString*)command withParam:(id)jsonObject
{
    NSLog(@"object=%@,command:%@,params=%@",object,command,jsonObject);
    //定位服务
    if ([object isEqualToString:@"locationManager"]) {
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
    else if ([object isEqualToString:@"codeScanner"]){
        if ([command isEqualToString:@"scan"]) {
            [self scanCode];
        }
    }
}

-(void)callbackObject:(NSString*)object withHandler:(NSString*)handler param:(id)param
{
    NSString* json;
    if (param) {
        NSError* error;
        NSData* jsonData=[NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"JSONSerialization Error:%@",error);
        }
        json=[[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }else{
        json=@"";
    }
    NSString* javaScriptStr=[NSString stringWithFormat:@"%@.%@(%@)",object,handler,json];
    NSLog(@"javaScriptStr=%@",javaScriptStr);
    if (self.webView) {
        [self.webView stringByEvaluatingJavaScriptFromString:javaScriptStr];
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

#pragma mark -  ScanCode    Handling  Method

- (void)scanCode
{
    if (self.viewController) {
        BCCodeScannerController* scannerVC=[[BCCodeScannerController alloc]init];
        scannerVC.delegate=self;
        if (self.viewController.navigationController) {
            [self.viewController.navigationController pushViewController:scannerVC animated:NO];
        }
        else{
            [self.viewController presentViewController:scannerVC animated:YES completion:NO];
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
    NSDictionary* param=@{@"longitude":[NSNumber numberWithFloat:location.coordinate.longitude],@"latitude":[NSNumber numberWithFloat:location.coordinate.latitude],@"speed":[NSNumber numberWithFloat:location.speed],@"timestamp":dateStr};
    [self callbackObject:@"window.boncAppEngine.locationManager" withHandler:@"successHandler" param:param];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSDictionary* param= @{@"description":error.description,@"code":[NSNumber numberWithInteger:error.code],@"domain":error.domain};
    [self callbackObject:@"window.boncAppEngine.locationManager" withHandler:@"errorHandler" param:param];
}

#pragma mark - BCCodeScannerControllerDelegate

-(void)viewController:(BCCodeScannerController*)viewController  didFinishScanWithInformation:(NSString*)qrCodeInfo
{
    NSDictionary* param=@{@"codeInfo":qrCodeInfo};
    [self callbackObject:@"window.boncAppEngine.codeScanner" withHandler:@"successHandler" param:param];
}

-(void)didCancleScanWithViewController:(BCCodeScannerController*)viewController
{
    [self callbackObject:@"window.boncAppEngine.codeScanner" withHandler:@"cancleHandler" param:nil];
}

-(void)viewController:(BCCodeScannerController*)viewController didFailedScanWithError:(NSError*)error
{
    NSDictionary* param= @{@"description":error.description,@"code":[NSNumber numberWithInteger:error.code],@"domain":error.domain};
    [self callbackObject:@"window.boncAppEngine.codeScanner" withHandler:@"errorHandler" param:param];
}
@end
