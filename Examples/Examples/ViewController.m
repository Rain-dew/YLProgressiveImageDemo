//
//  ViewController.m
//  Examples
//
//  Created by 张雨露 on 2017/7/28.
//  Copyright © 2017年 张雨露. All rights reserved.
//

#import "ViewController.h"
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>
@interface ViewController ()<NSURLSessionDelegate> {
    
    NSMutableData * _recieveData;//当前下载date
    long long _expectedLeght;//预估大小
    CGImageSourceRef _incrementallyImgSource;
}
@property(nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 150, self.view.frame.size.width, 400)];
        _imageView.backgroundColor = [UIColor grayColor];
    }
    return _imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadImage];
}
/**
 渐进式加载图片
 */
- (void)loadImage {
    
    _incrementallyImgSource = CGImageSourceCreateIncremental(NULL);
    
    _recieveData = [[NSMutableData alloc] init];
    
    [self.view addSubview:self.imageView];
    
    NSURL *url = [NSURL URLWithString:@"http://og3u5glro.bkt.clouddn.com/%E6%B8%90%E8%BF%9B%E5%BC%8F%E5%9B%BE%E7%89%87.jpg"];
    
    NSURLSession *session=[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLRequest *request=[NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    [task resume];
    
}

// 1.接收到服务器的响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
    
    _expectedLeght = response.expectedContentLength;
    NSLog(@"_expectedLeght   %lld",_expectedLeght);
    
}

// 2.接收到服务器的数据（可能调用多次）
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        [_recieveData appendBytes:bytes length:byteRange.length];
    }];
    
    BOOL isloadFinish = NO;
    if (_expectedLeght == _recieveData.length) {
        isloadFinish = YES;
    }
    //不希望出现下拉效果 同时避免数据太少毛玻璃绘制crash
//    if (_recieveData.length <= _expectedLeght*0.12) {
//        return;
//    }
    CGImageSourceUpdateData(_incrementallyImgSource, (CFDataRef)_recieveData, isloadFinish);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_incrementallyImgSource, 0, NULL);
    UIImage *imageaa = [UIImage imageWithCGImage:imageRef];
    
    CGFloat length = _expectedLeght;
    CGFloat dataLength = _recieveData.length;
    NSLog(@"....%f",dataLength/length);
    
    self.imageView.image = [self filterWith:imageaa andRadius:(1-dataLength/length)*10];

    CGImageRelease(imageRef);
    
    NSLog(@"_recieveData  %lu",(unsigned long)_recieveData.length);
    
}


// 3.请求成功或者失败（如果失败，error有值）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // 请求完成,成功或者失败的处理
}
- (UIImage *)filterWith:(UIImage *)image andRadius:(CGFloat)radius {
    
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    
    CIFilter *affineClampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    CGAffineTransform xform = CGAffineTransformMakeScale(1.0, 1.0);
    [affineClampFilter setValue:inputImage forKey:kCIInputImageKey];
    [affineClampFilter setValue:[NSValue valueWithBytes:&xform
                                               objCType:@encode(CGAffineTransform)]
                         forKey:@"inputTransform"];
    
    CIImage *extendedImage = [affineClampFilter valueForKey:kCIOutputImageKey];
    
    CIFilter *blurFilter =
    [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:extendedImage forKey:kCIInputImageKey];
    [blurFilter setValue:@(radius) forKey:@"inputRadius"];
    
    CIImage *result = [blurFilter valueForKey:kCIOutputImageKey];
    
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    
    CGImageRef cgImage = [ciContext createCGImage:result fromRect:inputImage.extent];
    
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return uiImage;
}

@end
