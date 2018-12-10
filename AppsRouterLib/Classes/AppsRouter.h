//
//  AppsRouter.h
//  Player1013
//
//  Created by guotonglin on 2018/10/17.
//  Copyright © 2018年 appscomm. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <objc/runtime.h>


#import <Foundation/Foundation.h>

#define regirsterPage(pageName,cls) ({ [AppsRouter registerVcWithName:pageName targetClass:cls];})

#define regirsterAction(ModuleName,ClassName,...)  [AppsRouter registerModuleAndActionsWith:ModuleName className:ClassName,##__VA_ARGS__]


@interface AppsRouterRequest : NSObject

@property(nonatomic,strong)NSString *routeUrl;

@property(nonatomic,strong)NSArray  *paramArray;

@property(nonatomic,copy)void (^ actionCallBack)(id);

-(instancetype)initWithRouteUrl:(NSString *)url params:(NSArray *)array callBack:(void(^)(id))callBack;

@end


@interface AppsRouter : NSObject

#pragma mark url 获取控制器实例
+(UIViewController *)toPage:(NSString *)pageUrl;

#pragma mark url 获取控制器实例 并传递参数，必须有对应的属性
+(UIViewController *)toPage:(NSString *)pageUrl params:(NSDictionary *)paramDict;

#pragma mark url 执行对应函数
+(id)handleAction:(NSString *)actionUrl;

#pragma mark url 执行对应函数 且带有回调函数
+(id)handleAction:(NSString *)actionUrl callback:(void(^)(id))callBack;

#pragma mark 执行的函数封装成 request
+(id)handleActionRequest:(AppsRouterRequest *)request;

#pragma mark 注册控制器
+(void)registerVcWithName:(NSString *)vcName targetClass:(NSString *)className;

#pragma mark 注册模块 并 模块中提供的函数
+(void)registerModuleAndActionsWith:(NSString *)moduleName className:(NSString *)className,...;

@end



