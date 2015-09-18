//
//  ViewController.m
//  recording
//
//  Created by 高彬 on 15/9/11.
//  Copyright (c) 2015年 erweimashengchengqi. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "THCaptureUtilities.h"


#define VEDIOPATH @"vedioPath"
CG_INLINE void runDispatchGetGlobalQueue(void (^block)(void)) {
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dispatchQueue, block);
}
CG_INLINE void KS_DISPATCH_GLOBAL_QUEUE(void (^block)(void)) {
    runDispatchGetGlobalQueue(block);
}


@interface ViewController ()<AVAudioRecorderDelegate> {
    BOOL toggle;
    
    NSString * fraqText;;
    NSString * valueText;
    
     NSURL *recordedTmpFile;
    
    AVAudioRecorder *recorder;
    NSTimer * timer;
    NSTimer * Videotimer;
    
    NSString * AudioStr;//音频地址
    
}

@property (nonatomic,strong) UIActivityIndicatorView * actSpinner;

@property (nonatomic,strong) UIButton * Recordingbutton;

@property (nonatomic,strong) UIButton * Startbutton;

@property (nonatomic,strong) UIImageView * imageView;

@property (nonatomic,strong) MPMoviePlayerController * videoPlayer;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"录音软件";
    
    toggle = YES;
    fraqText = @"8000";
    valueText = @"2";
    self.view.layer.backgroundColor = [UIColor whiteColor].CGColor;
    UILabel * frequencyLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 84, 200, 30)];
    frequencyLabel.text = [NSString stringWithFormat:@"采样频率是:%@",fraqText];
    [self.view addSubview:frequencyLabel];
    
    UILabel * volumeLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 120, 200, 30)];
    volumeLabel.text  = [NSString stringWithFormat:@"音量是:%@",valueText];
    [self.view addSubview:volumeLabel];
    

    
    self.Recordingbutton = [[UIButton alloc]initWithFrame:CGRectMake(20, 180, 100, 30)];
    [self.Recordingbutton setTitle:@"录音" forState:UIControlStateNormal];
    [self.Recordingbutton addTarget:self action:@selector(clickRecording:) forControlEvents:UIControlEventTouchUpInside];
    self.Recordingbutton.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.Recordingbutton];
    
    self.Startbutton = [[UIButton alloc]initWithFrame:CGRectMake(160, 180, 100, 30)];
    [self.Startbutton setTitle:@"播放" forState:UIControlStateNormal];
    [self.Startbutton addTarget:self action:@selector(StartRecording:) forControlEvents:UIControlEventTouchUpInside];
    self.Startbutton.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.Startbutton];
    
    
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(150, 300, 107, 128)];
    [self.view addSubview:self.imageView];
    
    //添加视频窗口
    
//    self.videoPlayer = [MPMoviePlayerController new];
//    self.videoPlayer.view.frame = CGRectMake(0, 300, 200, 120);
//    self.videoPlayer.contentURL = [NSURL URLWithString:@"http://cdn.eee114.com/H2014/2014tongbugaiban/renjiaogzphxx33/10.1.mp4"];
//    self.videoPlayer.controlStyle=MPMovieControlStyleNone;
//    [self.view addSubview:self.videoPlayer.view];
//    [self.videoPlayer play];
    
    
    
//    //录制音频
//    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
//    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
//    [audioSession setActive:YES error:nil];
//    
//    OSStatus error = AudioSessionInitialize(NULL, NULL, NULL, NULL);
//    UInt32 category = kAudioSessionCategory_PlayAndRecord;
//    error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
//    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, NULL, (__bridge void *)(self));
//    UInt32 inputAvailabel = 0;
//    UInt32 size = sizeof(inputAvailabel);
//    
//    AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailabel);
//    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, NULL, (__bridge void *)(self));
//    AudioSessionSetActive(true);
    
    
}

-(void) clickRecording:(UIButton *) sender{
    if (toggle) {
        toggle = NO;
        
        [self.Recordingbutton setTitle:@"停止" forState:UIControlStateNormal];
        
        
        //这个时候是开始录制界面信息
        if (transcribe == nil) {
            transcribe = [transcribeView new];
        }
        transcribe.frameRate = 10;
        UIWindow * window = [[UIApplication sharedApplication].delegate window];
        transcribe.captureLayer = window.layer;
        transcribe.delegate = self;
        [transcribe performSelector:@selector(startRecording1)];
       
//        NSString * path = [self getPathByFileName:VEDIOPATH ofType:@"wav"];
//        NSFileManager * fileManger = [NSFileManager defaultManager];
//        if ([fileManger fileExistsAtPath:path]) {
//            [fileManger removeItemAtPath:path error:nil];
//        }
//        [self toStartAudioRecord];
        
        
        //同事截取视频的图片
        
       
    //KS_DISPATCH_GLOBAL_QUEUE(^{
//        Videotimer = [NSTimer scheduledTimerWithTimeInterval:1/35 target:self selector:@selector(changeImageAndCreat) userInfo:nil repeats:YES];
//        [[NSRunLoop currentRunLoop]addTimer:Videotimer forMode:NSRunLoopCommonModes];
    //});
        
    } else {
        toggle = YES;
        [self.Recordingbutton setTitle:@"录制" forState:UIControlStateNormal];
        [recorder stop];
        [timer invalidate];
        [Videotimer invalidate];
        [transcribe performSelector:@selector(stopRecording)];
    }
    
}

-(void) changeImageAndCreat {
    NSTimeInterval  timeUse = self.videoPlayer.playableDuration;
    NSLog(@"现在的时间是:%f",timeUse);
    UIImage *thumbImage=[self.videoPlayer thumbnailImageAtTime:timeUse timeOption:MPMovieTimeOptionNearestKeyFrame];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithCapacity:1];
    [dic setObject:thumbImage forKey:@"Image"];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"MPMoviePlayerThumbnailImageRequestDidFinishNotification" object:nil userInfo:dic];
    //transcribe.thumbImage = thumbImage;
}
                           
                           


-(void) toStartAudioRecord {
    //录音
    UInt32 category = kAudioSessionCategory_PlayAndRecord;

    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);

    NSMutableDictionary * recordSetting = [[NSMutableDictionary alloc]init];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:[fraqText floatValue]] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: [valueText intValue]] forKey:AVNumberOfChannelsKey];

    //Now that we have our settings we are going to instanciate an instance of our recorder instance.
    //Generate a temp file for use by the recording.
    //This sample was one I found online and seems to be a good choice for making a tmp file that
    //will not overwrite an existing one.
    //I know this is a mess of collapsed things into 1 call.  I can break it out if need be.
    
    
    AudioStr = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"caf"]];
    recordedTmpFile = [NSURL fileURLWithPath:AudioStr];
    NSLog(@"Using File called: %@",recordedTmpFile);

    recorder = [[AVAudioRecorder alloc]initWithURL:recordedTmpFile settings:recordSetting error:nil];
    [recorder setDelegate:self];
    [recorder prepareToRecord];
    [recorder record];

    //设置定时检测
    //timer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(detectionVoice) userInfo:nil repeats:YES];
}

- (void)recordingFinished:(NSString*)outputPath {
    opPath = outputPath;
    
    [THCaptureUtilities mergeVideo:opPath andAudio:AudioStr andTarget:self andAction:@selector(mergedidFinish:WithError:)];
    
    
}
- (void)recordingFaild:(NSError *)error {
    
}
- (void)detectionVoice
{
    [recorder updateMeters];//刷新音量数据
    //获取音量的平均值  [recorder averagePowerForChannel:0];
    //音量的最大值  [recorder peakPowerForChannel:0];
    
    double lowPassResults = pow(10, (0.05 * [recorder peakPowerForChannel:0]));
    //NSLog(@"%lf",lowPassResults);
    //最大50  0
    //图片 小-》大
    if (0<lowPassResults<=0.06) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_01.png"]];
    }else if (0.06<lowPassResults<=0.13) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_02.png"]];
    }else if (0.13<lowPassResults<=0.20) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_03.png"]];
    }else if (0.20<lowPassResults<=0.27) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_04.png"]];
    }else if (0.27<lowPassResults<=0.34) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_05.png"]];
    }else if (0.34<lowPassResults<=0.41) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_06.png"]];
    }else if (0.41<lowPassResults<=0.48) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_07.png"]];
    }else if (0.48<lowPassResults<=0.55) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_08.png"]];
    }else if (0.55<lowPassResults<=0.62) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_09.png"]];
    }else if (0.62<lowPassResults<=0.69) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_10.png"]];
    }else if (0.69<lowPassResults<=0.76) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_11.png"]];
    }else if (0.76<lowPassResults<=0.83) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_12.png"]];
    }else if (0.83<lowPassResults<=0.9) {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_13.png"]];
    }else {
        [self.imageView setImage:[UIImage imageNamed:@"record_animate_14.png"]];
    }
}


-(NSString *)getPathByFileName:(NSString *)_fileName ofType:(NSString *)_type {
    NSString * fileDirectory = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingString:_fileName]stringByAppendingString:_type];
    return fileDirectory;
}

-(void) StartRecording:(UIButton *) sender {
    AVAudioPlayer * fm = [[AVAudioPlayer alloc]initWithContentsOfURL:recordedTmpFile error:nil];
    [fm prepareToPlay];
    [fm play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)video: (NSString *)videoPath didFinishSavingWithError:(NSError *) error contextInfo: (void *)contextInfo{
    if (error) {
        NSLog(@"---%@",[error localizedDescription]);
    }
}

- (void)mergedidFinish:(NSString *)videoPath WithError:(NSError *)error
{
    NSDateFormatter* dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:SS"];
    NSString* currentDateStr=[dateFormatter stringFromDate:[NSDate date]];
    
    NSString* fileName=[NSString stringWithFormat:@"白板录制,%@.mov",currentDateStr];
    
    NSString* path=[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",fileName]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath])
    {
        NSError *err=nil;
        [[NSFileManager defaultManager] moveItemAtPath:videoPath toPath:path error:&err];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"allVideoInfo"]) {
        NSMutableArray* allFileArr=[[NSMutableArray alloc] init];
        [allFileArr addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"allVideoInfo"]];
        [allFileArr insertObject:fileName atIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:allFileArr forKey:@"allVideoInfo"];
    }
    else{
        NSMutableArray* allFileArr=[[NSMutableArray alloc] init];
        [allFileArr addObject:fileName];
        [[NSUserDefaults standardUserDefaults] setObject:allFileArr forKey:@"allVideoInfo"];
    }
    
    //音频与视频合并结束，存入相册中
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

@end
