//
//  QGSocketIOClient.m
//  QGSocketIO
//
//  Created by QuanGe on 2017/9/1.
//  Copyright © 2017年 QuanGe. All rights reserved.
//

#import "QGSocketIOClient.h"

@interface QGSocketIOClient()
@property (nonatomic,readwrite,strong) NSString* socketURLStr;
@property (nonatomic,readwrite,assign) BOOL doubleEncodeUTF8;
@property (nonatomic,readwrite,strong) NSString *sid;
@property (nonatomic,readwrite,assign) BOOL connected;
@property (nonatomic,readwrite,assign) BOOL waitingForPost;
@property (nonatomic,readwrite,assign) BOOL waitingForPoll;
@property (nonatomic,readwrite,assign) BOOL reconnects;
@end


@implementation QGSocketIOClient

- (instancetype)initWithSocketURLStr:(NSString*)socketURLStr doubleEncodeUTF8:(BOOL)doubleEncodeUTF8
{
    self = [self init];
    if (self) {
        self.socketURLStr = socketURLStr;
        self.doubleEncodeUTF8 = doubleEncodeUTF8;
        self.connected = NO;
        self.waitingForPoll = NO;
        self.reconnects = YES;
    }
    return self;
}
- (void)connect{
    self.waitingForPost = NO;
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.socketURLStr]];
    request.HTTPMethod=@"GET";
    [self doLongPoll:request];
}

- (void)disConnect {
    self.reconnects = NO;
    [self disconnectPolling];
    
}

- (void)emitWithMessage:(NSString*)message {
    if (!self.connected) {
        return;
    }
    NSString *tempMessage = [NSString stringWithFormat:@"42[\"message\",\"%@\"]",message];
    NSString *sendMessage = [NSString stringWithFormat:@"%@:%@",@(tempMessage.length),tempMessage];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@&sid=%@",self.socketURLStr,self.sid]]];
    request.HTTPMethod=@"POST";
    request.HTTPBody = [sendMessage dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@(sendMessage.length).stringValue forHTTPHeaderField:@"Content-Length"];
    
    NSURLSession *session=[NSURLSession sharedSession];
    __weak __typeof__(self) weakSelf = self;
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        strongSelf.waitingForPost = NO;
    }];
    
    [task resume];
}


-(void)doPoll{
    if (self.waitingForPoll)
        return;
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@&sid=%@",self.socketURLStr,self.sid]]];
    request.HTTPMethod=@"GET";
    self.waitingForPoll = YES;
    [self doLongPoll:request];
}


- (void)doLongPoll:(NSMutableURLRequest*)request{
    __weak __typeof__(self) weakSelf = self;
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if(error && self.reconnects) {
            [strongSelf connect];
        }
        else {
            NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if(strongSelf.waitingForPoll)
                strongSelf.waitingForPoll = NO;
            [strongSelf parsePollingMessage:result];
            if (strongSelf.connected) {
                [strongSelf doPoll];
            }
        }
        
    }];
    
    [task resume];
}


- (void)sendPing{
    if(!self.connected)
        return;
    [self sendPollMessage];
    __weak __typeof__(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        [strongSelf sendPing];
    });
}

- (void)sendPollMessage{
    if (!self.waitingForPost) {
        [self flushWaitingForPost];
    }
    
}

- (void)flushWaitingForPost{
    if (!self.connected) {
        return;
    }
    self.waitingForPost = YES;
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@&sid=%@",self.socketURLStr,self.sid]]];
    request.HTTPMethod=@"POST";
    request.HTTPBody = [@"1:2" dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@(@"1:2".length).stringValue forHTTPHeaderField:@"Content-Length"];
    
    NSURLSession *session=[NSURLSession sharedSession];
    __weak __typeof__(self) weakSelf = self;
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        strongSelf.waitingForPost = NO;
    }];
    
    [task resume];
}

- (void)parsePollingMessage:(NSString*)message{
    NSRange tempRange = [message rangeOfString:@":"];
    if (tempRange.location !=NSNotFound && ![[message substringToIndex:1] isEqualToString:@"{"]){
        NSString *tempMessage = [message substringFromIndex:tempRange.location+1];
        NSInteger messageType = [[tempMessage substringToIndex:1] integerValue];
        
        switch (messageType) {
                //open
            case 0:
            {
                
                self.connected = YES;
                tempMessage = [tempMessage substringToIndex:[message substringToIndex:tempRange.location].integerValue];
                NSDictionary *result = [NSJSONSerialization  JSONObjectWithData:[[tempMessage substringFromIndex:1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                self.sid = result[@"sid"];
                [self sendPing];
                [self doPoll];
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(self.delegate && [self.delegate respondsToSelector:@selector(onOpen)])
                            [self.delegate onOpen];
                    });
                }
                break;
            }
                //noop
            case 6:
                //close
            case 1:
            {
                self.connected = NO;
                if(self.reconnects){
                    [self connect];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self.delegate && [self.delegate respondsToSelector:@selector(onClose)])
                        [self.delegate onClose];
                });
            }
                break;
                //ping
            case 2:
                break;
                //pong
            case 3:
                break;
                //message
            case 4:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self.delegate && [self.delegate respondsToSelector:@selector(onMessage:)])
                    {
                        NSString *resultMessage = [tempMessage substringFromIndex:2];
                        
                        if(self.doubleEncodeUTF8){
                            resultMessage = [[NSString alloc] initWithData:[resultMessage dataUsingEncoding:NSISOLatin1StringEncoding] encoding:NSUTF8StringEncoding];
                        }
                        [self.delegate onMessage:resultMessage];
                    }
                    
                    
                    
                });
            }
                break;
                //upgrade
            case 5:
                break;
            default:
                break;
        }
    }
}

- (void)disconnectPolling{
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@&sid=%@",self.socketURLStr,self.sid]]];
    request.HTTPMethod=@"POST";
    request.HTTPBody = [@"1:1" dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@(@"1:1".length).stringValue forHTTPHeaderField:@"Content-Length"];
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request];
    [task resume];
}

@end
