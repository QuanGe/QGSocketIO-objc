//
//  QGSocketIOClient.h
//  QGSocketIO
//
//  Created by QuanGe on 2017/9/1.
//  Copyright © 2017年 QuanGe. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QGSocketIOClientDelegate <NSObject>
@optional
- (void)onOpen;
- (void)onClose;
@required
- (void)onMessage:(NSString*)message;
@end

@interface QGSocketIOClient :NSObject
@property (nonatomic,readwrite,weak) id<QGSocketIOClientDelegate> delegate;
- (instancetype)initWithSocketURLStr:(NSString*)socketURLStr doubleEncodeUTF8:(BOOL)doubleEncodeUTF8;
- (void)connect;
- (void)disConnect;
- (void)emitWithMessage:(NSString*)message;
@end

