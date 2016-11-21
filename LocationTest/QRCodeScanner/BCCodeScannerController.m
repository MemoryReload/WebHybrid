//
//  BCCodeScannerController.m
//
//  BCURLInterceptor.h
//  LocationTest
//
//  Created by Heping on 8/14/16.
//  Copyright © 2016 BONC. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "BCCodeScannerController.h"

@interface BCCodeScannerController () <AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

#define SCANNER_WIDTH    10
#define SCANN_MARGIN     5

@property (strong, nonatomic,readwrite) UIButton *backButton;
@property (strong, nonatomic,readwrite) UIButton *albumButton;
@property (strong, nonatomic,readwrite) UILabel  *titleView;

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;
@property (strong, nonatomic) UIImageView *focusView;
@property (strong, nonatomic) NSLayoutConstraint* scannerTopConstraint;
@property (strong, nonatomic) NSTimer  *timer;
@end

@implementation BCCodeScannerController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype)init
{
    self=[super init];
    if (self) {
        // prepare the  video session
        self.title=NSLocalizedString(@"QRCode Scanner", nil);
        [self setupSession];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self addBtnControls];
    // Preview
    [self setupPreviewLayer];
    // ScanView
    [self setupScanView];
    //start scanning
    [self startScan];
    
}

- (void)addBtnControls{
    //返回按钮
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.albumButton setTitle:NSLocalizedString(@"< Back", nil) forState:UIControlStateNormal];
    [self.albumButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.albumButton.titleLabel.font=[UIFont systemFontOfSize:16];
    self.albumButton.titleLabel.adjustsFontSizeToFitWidth=YES;
    [self.backButton addTarget:self action:@selector(clickBack) forControlEvents:UIControlEventTouchUpInside];
    
    //相册按钮
    self.albumButton= [UIButton buttonWithType:UIButtonTypeCustom];
    [self.albumButton setTitle:NSLocalizedString(@"Album", nil) forState:UIControlStateNormal];
    [self.albumButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.albumButton.titleLabel.font=[UIFont systemFontOfSize:16];
    self.albumButton.titleLabel.adjustsFontSizeToFitWidth=YES;
    [self.albumButton addTarget:self action:@selector(clickAlbum) forControlEvents:UIControlEventTouchUpInside];
    
    //标题视图
    self.titleView=[[UILabel alloc]init];
    self.titleView.textColor=[UIColor whiteColor];
    self.titleView.font=[UIFont systemFontOfSize:18];
    self.titleView.adjustsFontSizeToFitWidth=YES;
    self.titleView.textAlignment=NSTextAlignmentCenter;
    self.titleView.text=self.title;
    
    if (self.navigationController) {
        
        self.backButton.frame = CGRectMake(0, 0, 48, 32);
        UIBarButtonItem* item=[[UIBarButtonItem alloc]initWithCustomView:self.backButton];
        self.navigationItem.leftBarButtonItems=@[item];
        
        self.albumButton.frame=CGRectMake(0, 0, 48, 32);
        item=[[UIBarButtonItem alloc]initWithCustomView:self.albumButton];
        self.navigationItem.rightBarButtonItems=@[item];
        
        self.titleView.frame=CGRectMake(0, 0, 180, 32);
        self.navigationItem.titleView=self.titleView;
        
    }else{
        
        self.backButton.translatesAutoresizingMaskIntoConstraints=NO;
        self.albumButton.translatesAutoresizingMaskIntoConstraints=NO;
        self.titleView.translatesAutoresizingMaskIntoConstraints=NO;
        
        [self.view addSubview:self.backButton];
        [self.view addSubview:self.albumButton];
        [self.view addSubview:self.titleView];
        
        //返回按钮自动布局
        NSDictionary* viewDic=@{@"btn":self.backButton};
        NSArray* horizontalConstraints=[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leading-[btn(>=32)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"leading":@10} views:viewDic];
        
        NSArray* verticalConstraints=[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[btn(>=32)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"top":@20} views:viewDic];
        
        [self.view addConstraints:horizontalConstraints];
        [self.view addConstraints:verticalConstraints];
        
        //相册按钮自动布局
        viewDic=@{@"album":self.albumButton};
        horizontalConstraints=[NSLayoutConstraint constraintsWithVisualFormat:@"H:[album(>=48)]-trailing-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"trailing":@10} views:viewDic];
        verticalConstraints=[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[album(>=32)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"top":@20} views:viewDic];
        [self.view addConstraints:horizontalConstraints];
        [self.view addConstraints:verticalConstraints];
        
        
        //标题视图自动布局
        NSLayoutConstraint* centerX=[NSLayoutConstraint constraintWithItem:self.titleView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
        NSLayoutConstraint* width=[NSLayoutConstraint constraintWithItem:self.titleView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:180];
        NSLayoutConstraint* topConstraint=[NSLayoutConstraint constraintWithItem:self.titleView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:20];
        NSLayoutConstraint* height=[NSLayoutConstraint constraintWithItem:self.titleView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:32];
        [self.view addConstraints:@[centerX,width,topConstraint,height]];
    }
}

- (void)setupSession{
    NSError* error;
    // Device
    AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // Input
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error&&self.delegate&&[self.delegate respondsToSelector:@selector(viewController:didFailedScanWithError:)]) {
        [self.delegate viewController:self didFailedScanWithError:error];
    }
    // Output
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    // Create a new serial dispatch queue.
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //setup Output scan Region
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    UIImage* focus=[UIImage imageNamed:FOCUS_IMG_NAME];
    CGRect rect=CGRectMake((screenHeight - focus.size.height) / 2 /screenHeight,(screenWidth - focus.size.width) / 2 /screenWidth,focus.size.height/screenHeight,focus.size.width/screenWidth);
    output.rectOfInterest = rect;
    
    // Session
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }else{
        error=[[NSError alloc]initWithDomain:@"cn.com.bonc.QRScanner" code:1 userInfo:@{NSLocalizedDescriptionKey:@"AVCaptureSession add Input failed."}];
        if (error&&self.delegate&&[self.delegate respondsToSelector:@selector(viewController:didFailedScanWithError:)]) {
            [self.delegate viewController:self didFailedScanWithError:error];
        }
    }
    
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }else{
        error=[[NSError alloc]initWithDomain:@"cn.com.bonc.QRScanner" code:1 userInfo:@{NSLocalizedDescriptionKey:@"AVCaptureSession add Output failed."}];
        if (error&&self.delegate&&[self.delegate respondsToSelector:@selector(viewController:didFailedScanWithError:)]) {
            [self.delegate viewController:self didFailedScanWithError:error];
        }
    }
    output.metadataObjectTypes = [NSArray arrayWithObjects:AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode, nil];
}

- (void)setupPreviewLayer
{
    self.preview = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.bounds = self.view.bounds;
    self.preview.position=self.view.center;
    [self.view.layer insertSublayer:self.preview atIndex:0];
}

- (void)setupScanView{
    //扫描框
    UIImage* focus=[UIImage imageNamed:FOCUS_IMG_NAME];
    self.focusView = [[UIImageView alloc] initWithImage:focus];
    self.focusView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.focusView];

    //设置中心
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.focusView
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0
                                                           constant:0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.focusView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0]];
    
    //设置宽度
    [self.focusView addConstraint:[NSLayoutConstraint constraintWithItem:self.focusView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:focus.size.width]];
    
    //设置高度
    [self.focusView addConstraint:[NSLayoutConstraint constraintWithItem:self.focusView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:focus.size.height]];
    
    
    //提示语
    UILabel *promoteLabel=[[UILabel alloc]init];
    promoteLabel.translatesAutoresizingMaskIntoConstraints=NO;
    promoteLabel.textColor=[UIColor greenColor];
    promoteLabel.text=NSLocalizedString(@"Focus the QRCode image and wait for scanning to be finished.", nil);
    promoteLabel.numberOfLines=2;
    promoteLabel.textAlignment=NSTextAlignmentCenter;
    promoteLabel.font=[UIFont systemFontOfSize:16];
    promoteLabel.adjustsFontSizeToFitWidth=YES;
    [self.view addSubview:promoteLabel];
    
    NSLayoutConstraint* promoteWidth=[NSLayoutConstraint constraintWithItem:promoteLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.focusView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:80];
    NSLayoutConstraint* promoteHeight=[NSLayoutConstraint constraintWithItem:promoteLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:80];
    NSLayoutConstraint* promoteCenterX=[NSLayoutConstraint constraintWithItem:promoteLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.focusView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint* promoteTop=[NSLayoutConstraint constraintWithItem:promoteLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.focusView attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:0];
    [self.view addConstraints:@[promoteWidth,promoteHeight,promoteCenterX,promoteTop]];
    
    
    //扫描器
    UIImageView* scannerView=[[UIImageView alloc]init];
    scannerView.translatesAutoresizingMaskIntoConstraints=NO;
    UIImage* img=[UIImage imageNamed:SCANNER_IMG_NAME];
    if (img) {
        scannerView.image=img;
    }else{
    scannerView.backgroundColor=[UIColor greenColor];
    }
    [self.focusView addSubview:scannerView];
    
    NSLayoutConstraint* widthConstraint=[NSLayoutConstraint constraintWithItem:self.focusView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:scannerView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:SCANNER_WIDTH];
    
    NSLayoutConstraint* heightConstraint=[NSLayoutConstraint constraintWithItem:scannerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:10];
    
    NSLayoutConstraint* centerXConstraint=[NSLayoutConstraint constraintWithItem:scannerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.focusView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    
    self.scannerTopConstraint=[NSLayoutConstraint constraintWithItem:scannerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.focusView attribute:NSLayoutAttributeTop multiplier:1.0 constant:SCANN_MARGIN];
    
    [self.focusView addConstraints:@[widthConstraint,heightConstraint,centerXConstraint,self.scannerTopConstraint]];
    
    [self startScanAnimation];
}

#pragma mark - Scanner Animation Method
-(void)startScanAnimation
{
    if (!self.timer) {
        self.timer=[[NSTimer alloc]initWithFireDate:[NSDate distantFuture] interval:1.1 target:self selector:@selector(animateScanner) userInfo:nil repeats:YES];
        NSThread* thread=[[NSThread alloc]initWithTarget:self selector:@selector(setupTimer) object:nil];
        thread.name=@"cn.com.bonc.QRScannerThread";
        [thread start];
    }
}

-(void)setupTimer{
    NSRunLoop* loop=[NSRunLoop currentRunLoop];
    [loop addTimer:self.timer forMode:NSRunLoopCommonModes];
    [loop run];
}

-(void)animateScanner
{
    CGFloat maxDistance=self.focusView.bounds.size.height-SCANNER_WIDTH-SCANN_MARGIN;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.0 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            self.scannerTopConstraint.constant=maxDistance;
            [self.focusView layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.scannerTopConstraint.constant=SCANN_MARGIN;
        }];
    });
}
#pragma mark - Orientation Method

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self animateRotateLayerToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)animateRotateLayerToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    CGAffineTransform transform;
    switch (toInterfaceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI+ M_PI_2); // 270 degress
            break;
        case UIDeviceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(M_PI_2); // 90 degrees
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI); // 180 degrees
            break;
        default:
            transform= CGAffineTransformIdentity;
            break;
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:NO];
    [CATransaction setAnimationDuration:duration];
    self.preview.position=self.view.center;
    self.preview.affineTransform=transform;
    [CATransaction commit];
}

- (void)goBack{
    
    [self.timer invalidate];
    self.timer=nil;
    
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -  Toggle Method

-(void)clickBack
{
    //cancle handling
    if (self.delegate&&[self.delegate respondsToSelector:@selector(didCancleScanWithViewController:)]) {
        [self.delegate didCancleScanWithViewController:self];
    }
    [self goBack];
}

-(void)clickAlbum
{
    [self stopScan];
    
    UIImagePickerController* vc=[[UIImagePickerController alloc]init];
    vc.delegate=self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        vc.sourceType=UIImagePickerControllerSourceTypePhotoLibrary;
    }
    else{
        NSError *error=[[NSError alloc]initWithDomain:@"cn.com.bonc.QRScanner" code:1 userInfo:@{NSLocalizedDescriptionKey:@"PhotoLibrary Source is not available."}];
        if (error&&self.delegate&&[self.delegate respondsToSelector:@selector(viewController:didFailedScanWithError:)]) {
            [self.delegate viewController:self didFailedScanWithError:error];
        }
    }
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark -  Scan Manipulation Method

-(void)startScan
{
    [self.timer setFireDate:[NSDate date]];
    [self.session startRunning];
}

-(void)stopScan
{
    [self.timer setFireDate:[NSDate distantFuture]];
    [self.session stopRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate Method
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSString *stringValue;
    if ([metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
    }
//    NSLog(@"QRCodeInfo:%@",stringValue);
    [self stopScan];
    //success handling
    if (self.delegate&&[self.delegate respondsToSelector:@selector(viewController:didFinishScanWithInformation:)]) {
        [self.delegate viewController:self didFinishScanWithInformation:stringValue];
    }
    [self goBack];
}

#pragma mark - UIImagePickerControllerDelegate  Method
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSString* mediaType=(NSString*)[info valueForKey:UIImagePickerControllerMediaType];
    
    UIImage* qrCodeImage;
    if ([mediaType isEqualToString: (__bridge NSString*)kUTTypeImage]) {
        qrCodeImage=(UIImage*)[info valueForKey:UIImagePickerControllerOriginalImage];
    }
    
    NSString* qrCodeInfo;
    if (qrCodeImage) {
        qrCodeInfo=[self getQRCodeFromImage:qrCodeImage];
//        NSLog(@"QRCodeInfo:%@",qrCodeInfo);
    }
    
    if (qrCodeInfo) {
        //success handling
        if (self.delegate&&[self.delegate respondsToSelector:@selector(viewController:didFinishScanWithInformation:)]) {
            [self.delegate viewController:self didFinishScanWithInformation:qrCodeInfo];
        }
    }
    else{
        NSError *error=[[NSError alloc]initWithDomain:@"cn.com.bonc.QRScanner" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could not read QRCode from image."}];
        if (error&&self.delegate&&[self.delegate respondsToSelector:@selector(viewController:didFailedScanWithError:)]) {
            [self.delegate viewController:self didFailedScanWithError:error];
        }
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self goBack];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    __weak typeof(self) tempSelf=self;
    [picker dismissViewControllerAnimated:YES completion:^{
        [tempSelf startScan];
    }];
}

#pragma mark - Utils Method
- (NSString*)getQRCodeFromImage:(UIImage*)qrCodeImage
{
    //低于ios8不支持探测二维码，返回空;
    if ([[[UIDevice currentDevice] systemVersion] floatValue]<8.0) {
        NSError *error=[[NSError alloc]initWithDomain:@"cn.com.bonc.QRScanner" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could not read QRCode from image."}];
        if (error&&self.delegate&&[self.delegate respondsToSelector:@selector(viewController:didFailedScanWithError:)]) {
            [self.delegate viewController:self didFailedScanWithError:error];
        }
        return nil;
    }
    
    CIImage* cimg=[[CIImage alloc]initWithCGImage:qrCodeImage.CGImage];
    CIDetector* detector=[CIDetector detectorOfType:CIDetectorTypeQRCode context:[CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}] options:@{CIDetectorAccuracy:CIDetectorAccuracyLow}];
    
    CIQRCodeFeature*  qrCodeFeature;
    NSString* qrCodeInfo;
    NSArray* features=[detector featuresInImage:cimg];
    if (features&&features.count>0) {
        CIFeature* feature=[features firstObject];
        if ([feature isKindOfClass:[CIQRCodeFeature class]])
        {
            qrCodeFeature=(CIQRCodeFeature*)feature;
            qrCodeInfo=qrCodeFeature.messageString;
        }
    }
    return qrCodeInfo;
}
@end
