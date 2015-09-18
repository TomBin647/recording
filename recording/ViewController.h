//
//  ViewController.h
//  recording
//
//  Created by 高彬 on 15/9/11.
//  Copyright (c) 2015年 erweimashengchengqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#import "transcribeView.h"

@interface ViewController : UIViewController <TranscribeDelegate> {
    transcribeView * transcribe;
    
     NSString* opPath;
}


@end

