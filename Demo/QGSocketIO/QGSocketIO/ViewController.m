//
//  ViewController.m
//  QGSocketIO
//
//  Created by 张汝泉 on 2017/9/1.
//  Copyright © 2017年 QuanGe. All rights reserved.
//

#define url @"http://localhost:3000/socket.io/?transport=polling&b64=1"

#import "ViewController.h"
#import <QGSocketIOClient.h>

@interface ViewController ()<QGSocketIOClientDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic,readwrite,strong) QGSocketIOClient *client;
@end

@implementation ViewController

-(void)dealloc{
    NSLog(@"dealloc");
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"chat example";
    
    self.client = [[QGSocketIOClient alloc] initWithSocketURLStr:url doubleEncodeUTF8:YES];
    self.client.delegate = self;
    [self.client connect];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.client emitWithMessage:@"hello word"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.client disConnect];
    });
    
}

- (void)onMessage:(NSString *)message{
    
    self.textView.text = [NSString stringWithFormat:@"%@ \n %@",self.textView.text,message];
}

- (void)onOpen{
    self.textView.text = [NSString stringWithFormat:@"%@ \n %@",self.textView.text,@"---------------websocket  open-----------------"];
}

- (void)onClose{
    self.textView.text = [NSString stringWithFormat:@"%@ \n %@",self.textView.text,@"---------------websocket  close-----------------"];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
