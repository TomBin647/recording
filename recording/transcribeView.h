//
//  transcribeView.h
//  recording
//
//  Created by 高彬 on 15/9/14.
//  Copyright (c) 2015年 erweimashengchengqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol TranscribeDelegate <NSObject>

- (void)recordingFinished:(NSString*)outputPath;
- (void)recordingFaild:(NSError *)error;

@end

@interface transcribeView : NSObject {
    BOOL           _recording;     //正在录制中
    BOOL           _writing;       //正在将帧写入文件
    AVAssetWriter *videoWriter;
    AVAssetWriterInput *videoWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
    CGContextRef   context;        //绘制layer的context
    NSDate         *startedAt;     //录制的开始时间
    NSTimer        *timer;         //按帧率写屏的定时器
    
    
    CALayer *_captureLayer;              //要绘制的目标layer
    NSUInteger _frameRate;
    
    
    
}

@property(nonatomic, strong) CALayer *captureLayer;

@property(assign) float spaceDate;//秒

@property(assign) NSUInteger frameRate;

@property (nonatomic,strong)UIImage * thumbImage;

@property (nonatomic,assign)id<TranscribeDelegate> delegate;


//开始录制
- (bool)startRecording1;
//结束录制
- (void)stopRecording;



@end
