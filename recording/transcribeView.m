//
//  transcribeView.m
//  recording
//
//  Created by 高彬 on 15/9/14.
//  Copyright (c) 2015年 erweimashengchengqi. All rights reserved.
//

#import "transcribeView.h"
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#define sizeWidth 480
#define sizeHeight 640

CG_INLINE void runDispatchGetGlobalQueue(void (^block)(void)) {
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dispatchQueue, block);
}
CG_INLINE void KS_DISPATCH_GLOBAL_QUEUE(void (^block)(void)) {
    runDispatchGetGlobalQueue(block);
}


static NSString* const kFileName=@"output.mov";

@interface transcribeView ()

//配置录制环境
-(BOOL)setUpWrite;
//清理录制环境
-(void)cleanupWrite;
//完成录制工作
-(void)completeRecordingSession;
//录制每一帧
-(void)drawFrame;

@end

@implementation transcribeView
@synthesize frameRate=_frameRate;
@synthesize captureLayer = _captureLayer;


-(id)init {
    self = [super init];
    if (self) {
        _frameRate = 10;//默认的帧率为10 可以调整
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(thumImageGet:)
                                                     name:@"MPMoviePlayerThumbnailImageRequestDidFinishNotification"//视频缩略图截取成功时调用
                                                   object:nil];
    }
    return  self;
}
- (void)thumImageGet:(NSNotification *)noti
{
    self.thumbImage = [[noti userInfo] objectForKey:@"Image"];
    //UIImageWriteToSavedPhotosAlbum(self.thumbImage, nil, nil, nil);
}
-(void)dealloc {
    [self cleanUpWrite];
}

-(bool)startRecording1 {
    bool result = NO;
    if (!_recording && _captureLayer) {
        result = [self setUpWrite];
        if (result) {
            startedAt = [NSDate date];
            _spaceDate = 0;
            _recording = true;
            _writing = false;
            
            //绘制屏幕定时器
            NSDate * nowDate = [NSDate date];
            timer = [[NSTimer alloc]initWithFireDate:nowDate interval:1.0/_frameRate target:self selector:@selector(drawFrame) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
        }
    }
    return result;
    
}
-(void)stopRecording {
    if (_recording) {
        _recording = false;
        [timer invalidate];
        timer = nil;
        [self completeRecordingSession];
        [self cleanUpWrite];
    }
}

-(BOOL)setUpWrite {
    CGSize size = CGSizeMake(sizeWidth, sizeHeight);
    //Clear Old TempFile
    NSError  *error = nil;
    NSString *filePath=[self tempFilePath];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath])
    {
        if ([fileManager removeItemAtPath:filePath error:&error] == NO)
        {
            NSLog(@"Could not delete old recording file at path:  %@", filePath);
            return NO;
        }
    }
    
    //Configure videoWriter
    NSURL   *fileUrl=[NSURL fileURLWithPath:filePath];
    videoWriter = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    //Configure videoWriterInput
    NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:sizeWidth*sizeHeight], AVVideoAverageBitRateKey,
                                           nil ];
    
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:sizeWidth], AVVideoWidthKey,
                                   [NSNumber numberWithInt:sizeHeight], AVVideoHeightKey,
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   nil];
    
    videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSParameterAssert(videoWriterInput);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
    
    //add input
    [videoWriter addInput:videoWriterInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
    
    
    //create context
    if (context== NULL)
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate (nil,
                                         sizeWidth,
                                         sizeHeight,
                                         8,//bits per component
                                         sizeWidth * 4,
                                         colorSpace,
                                         kCGImageAlphaNoneSkipFirst);
        CGColorSpaceRelease(colorSpace);
        CGContextSetAllowsAntialiasing(context,NO);
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0,-1, 0, sizeHeight);
        CGContextConcatCTM(context, flipVertical);
    }
    if (context== NULL)
    {
        fprintf (stderr, "Context not created!");
        return NO;
    }
    
    return YES;
}

-(void) drawFrame {
    if (!_writing) {
        [self performSelectorInBackground:@selector(getFrame) withObject:nil];
    }
}
-(void)getFrame {
    if (!_writing) {
        _writing = YES;
        size_t width = CGBitmapContextGetWidth(context);
        size_t hight = CGBitmapContextGetWidth(context);
        @try {
            CGContextClearRect(context, CGRectMake(0, 0, width, hight));
            [self.captureLayer renderInContext:context];
            self.captureLayer.contents = nil;
            CGImageRef cgImage = CGBitmapContextCreateImage(context);
            
            
            UIImage * nextImage =[UIImage imageWithCGImage:cgImage];
            
            //拼接图片
            
            UIImage * resultingImage = [self addImageview:nextImage toImage:self.thumbImage];
            
            CGImageRef nowImage = resultingImage.CGImage;
            
            //执行代理方法
            
            
//            //保存到
//            UIImage * nextImage = [UIImage imageWithCGImage:cgImage];
//            NSData * data = UIImagePNGRepresentation(nextImage);
//            //NSData * data2 =UIImageJPEGRepresentation(nextImage, 1.0);
//            
//            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//            NSString *documentsDirectory = [paths objectAtIndex:0];
//            NSString * path = [documentsDirectory stringByAppendingPathComponent:
//                    @"test.png"];
//            //data = UIImagePNGRepresentation(nextImage);
//            [data writeToFile:path atomically:YES];
//            NSLog(@"图片地址是:%@",path);
            
            if (_recording) {
                double millisElapsed = [[NSDate date]timeIntervalSinceDate:startedAt]* 1000.0-_spaceDate*1000.0;
                [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000) addImage:nowImage];
                
            }
            CGImageRelease(cgImage);
        }
        @catch (NSException *exception) {
            
        }
        _writing = false;
    }
}


- (UIImage *)addImageview:(UIImage *)image1 toImage:(UIImage *)image2 {
    CGSize size= CGSizeMake( image1.size.width,image1.size.height);
    UIGraphicsBeginImageContext(size);
    // Draw image1
    [image1 drawInRect:CGRectMake(0, 0, image1.size.width, image1.size.height)];
    [image2 drawInRect:CGRectMake(4.5, 6, 77, 77)];
    // Draw image2
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultingImage;
    
}




- (CVPixelBufferRef) newPixelBufferFromCGImage: (CGImageRef) image
{
    //Configure videoWriterInput
    NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:sizeWidth*sizeHeight], AVVideoAverageBitRateKey,
                                           nil ];
    
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:sizeWidth], AVVideoWidthKey,
                                   [NSNumber numberWithInt:sizeHeight], AVVideoHeightKey,
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CFDictionaryRef option = (__bridge_retained CFDictionaryRef)videoSettings;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          sizeWidth,
                                          sizeHeight,
                                          kCVPixelFormatType_32ARGB,
                                          option,
                                          &pxbuffer
                                          );
    
    CFRelease(option);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    int bitmapInfo = (CGBitmapInfo)kCGImageAlphaNoneSkipFirst;
#else
    int bitmapInfo = kCGImageAlphaNoneSkipFirst;
#endif
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 sizeWidth,
                                                 sizeHeight,
                                                 8,
                                                 4*sizeWidth,
                                                 rgbColorSpace,
                                                 bitmapInfo
                                                 );
    
    //    CGContextRef context = CGBitmapContextCreate(pxdata, self.size.width, self.size.height, 8, 4*self.size.width, rgbColorSpace,kCGImageAlphaNoneSkipFirst);
    
    NSParameterAssert(context);
    
    //    CGFloat iw = CGImageGetWidth(image);
    
    CGContextDrawImage(context, CGRectMake(0, 0, sizeWidth, sizeHeight), image);
    //    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
    //                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


-(void) writeVideoFrameAtTime:(CMTime)time addImage:(CGImageRef )newImage
{
    if (![videoWriterInput isReadyForMoreMediaData]) {
        NSLog(@"Not ready for video data");
    }
    else {
        [avAdaptor appendPixelBuffer:[self newPixelBufferFromCGImage:newImage] withPresentationTime:time];
//        @synchronized (self) {
//            CVPixelBufferRef pixelBuffer = NULL;
//            CGImageRef cgImage = CGImageCreateCopy(newImage);
//            CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
//            
//            int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, avAdaptor.pixelBufferPool, &pixelBuffer);
//            if(status != 0){
//                //could not get a buffer from the pool
//                NSLog(@"Error creating pixel buffer:  status=%d", status);
//            }
//            // set image data into pixel buffer
//            CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
//            uint8_t* destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
//            CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);  //XXX:  will work if the pixel buffer is contiguous and has the same bytesPerRow as the input data
//            
//            if(status == 0){
//                BOOL success = [avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
//                if (!success)
//                    NSLog(@"Warning:  Unable to write buffer to video");
//            }
//            
//            //clean up
//            CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
//            CVPixelBufferRelease( pixelBuffer );
//            CFRelease(image);
//            CGImageRelease(cgImage);
//        }
    }
}
-(void) completeRecordingSession {
    [videoWriterInput markAsFinished];
    
    int status = videoWriter.status;
    while (status == AVAssetWriterStatusUnknown) {
        NSLog(@"Waiting..");
        [NSThread sleepForTimeInterval:0.5f];
        status = videoWriter.status;
    }
    
    
    
    KS_DISPATCH_GLOBAL_QUEUE(^{
        
    });
    BOOL success = [videoWriter finishWriting];
    if (!success)
    {
        NSLog(@"finishWriting returned NO");
        if ([_delegate respondsToSelector:@selector(recordingFaild:)]) {
            [_delegate recordingFaild:nil];
        }
        return ;
    }
    
    NSLog(@"Completed recording, file is stored at:  %@", [self tempFilePath]);
    if ([_delegate respondsToSelector:@selector(recordingFinished:)]) {
        [_delegate recordingFinished:[self tempFilePath]];
    }

    

}




-(NSString *) tempFilePath {
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString * filePath = [[paths objectAtIndex:0]stringByAppendingString:kFileName];
    return filePath;
}

-(void)cleanUpWrite {
    
    avAdaptor = nil;
    videoWriterInput = nil;
    videoWriter = nil;
    startedAt = nil;
    
}

@end
