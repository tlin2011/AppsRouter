//
//  AppsRouter.m
//  Player1013
//
//  Created by guotonglin on 2018/10/17.
//  Copyright © 2018年 appscomm. All rights reserved.
//
#import "AppsRouter.h"

@implementation AppsRouter

+(void)registerVcWithName:(NSString *)vcName targetClass:(NSString *)className{
    NSMutableDictionary* viewConrollersDict = globalVcDict();
    NSString *tempClassName =  viewConrollersDict[vcName];
    if (!tempClassName) {
        [viewConrollersDict setObject:className forKey:vcName];
    }
}
+(UIViewController *)toPage:(NSString *)pageUrl{
    
    UIViewController *result = nil;
    NSArray *urlArray = [pageUrl componentsSeparatedByString:@"?"];
    
    if (urlArray.count == 0) {
        return result;
    }
    Class cls = NSClassFromString(globalVcDict()[[urlArray firstObject]]);
    result =  [[cls alloc] init];
    if (urlArray && urlArray.count > 1) {
        NSArray *paramArray = [[urlArray lastObject] componentsSeparatedByString:@"&"];
        for (NSString *paramKeyValue in paramArray) {
            NSArray *tempKeyValues = [paramKeyValue componentsSeparatedByString:@"="];
            NSString *setMethodName = [NSString stringWithFormat:@"set%@%@:",[[[tempKeyValues firstObject] substringToIndex:1] uppercaseString],[[tempKeyValues firstObject] substringFromIndex:1]];
            Method resultMethod = [self findMethodWithCls:cls methodName:setMethodName];
            if (resultMethod) {
                [result performSelector:method_getName(resultMethod) withObject:[tempKeyValues lastObject]];
            }
        }
    }
    return result;
}

+(UIViewController *)toPage:(NSString *)pageUrl params:(NSDictionary *)paramDict{
    
    UIViewController *result = nil;
    NSArray *urlArray = [pageUrl componentsSeparatedByString:@"?"];
    
    if (urlArray.count == 0) {
        return result;
    }
    Class cls = NSClassFromString(globalVcDict()[[urlArray firstObject]]);
    result =  [[cls alloc] init];
    
    NSArray *keys =  [paramDict allKeys];
    for (id tempKey in keys) {
        
        NSString *setMethodName = [NSString stringWithFormat:@"set%@%@:",[[tempKey substringToIndex:1] uppercaseString],[tempKey substringFromIndex:1]];
        
        Method resultMethod = [self findMethodWithCls:cls methodName:setMethodName];
        if (resultMethod) {
            [result performSelector:method_getName(resultMethod) withObject:paramDict[tempKey]];
        }
    }
    return result;
}

+(Method)findMethodWithCls:(Class)cls methodName:(NSString *)methodName{
    BOOL classMethod = NO;
    return [self findMethodWithCls:cls methodName:methodName classMethod:&classMethod];
}

+(Method)findMethodWithCls:(Class)cls methodName:(NSString *)methodName classMethod:(BOOL *)classMethod{
    
    *classMethod = NO;
    unsigned int count = 0;
    Method *memberFuncs = class_copyMethodList(cls, &count);//所有在.m文件显式实现的方法都会被找到
    
    Method result = nil;
    for (int i = 0; i < count; i++) {
        Method tempMethod = memberFuncs[i];
        SEL name = method_getName(tempMethod);
        NSString *tempMethodName = [NSString stringWithCString:sel_getName(name) encoding:NSUTF8StringEncoding];
        if ([tempMethodName isEqualToString:methodName]) {
            result = tempMethod;
        }
    }
    
    if (!result) {
        *classMethod = YES;
        unsigned int staticMethodCount = 0;
        Method *staticMemberFuncs =  class_copyMethodList(object_getClass(cls), &staticMethodCount);
        
        for (int i = 0; i < staticMethodCount; i++) {
            Method tempMethod = staticMemberFuncs[i];
            SEL name = method_getName(tempMethod);
            NSString *tempMethodName = [NSString stringWithCString:sel_getName(name) encoding:NSUTF8StringEncoding];
            if ([tempMethodName isEqualToString:methodName]) {
                result = tempMethod;
            }
        }
    }
    
    return result;
}

+(void)registerModuleAndActionsWith:(NSString *)moduleName className:(NSString *)className,...{
    NSMutableArray *array = [NSMutableArray array];
    va_list list;
    va_start(list, className);
    while (YES)
    {
        NSString *string = va_arg(list, NSString*);
        if (!string) {
            break;
        }
        [array addObject:string];
        NSLog(@"%@",string);
    }
    va_end(list);
    
    NSMutableDictionary* viewModuleDict = globalModuleActionsDict();
    NSMutableDictionary *tempMuduleDict =  viewModuleDict[moduleName];
    
    if (!tempMuduleDict) {
        tempMuduleDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [tempMuduleDict setObject:array forKey:@"actions"];
        [tempMuduleDict setObject:className forKey:@"classname"];
        [viewModuleDict setObject:tempMuduleDict forKey:moduleName];
    }
}

+(id)handleAction:(NSString *)actionUrl{
    return [self handleAction:actionUrl callback:nil];
}

+(id)handleAction:(NSString *)actionUrl callback:(void(^)(id))callBack{
    // 解析URL
    NSArray *moduleCompment = [actionUrl componentsSeparatedByString:@"/"];
    if (moduleCompment.count < 2) {
        return nil;
    }
    NSArray *actionCompment = [[moduleCompment lastObject] componentsSeparatedByString:@"?"];
    NSMutableArray *resultParamArray = [NSMutableArray array];
    // 有参数
    if (actionCompment.count > 1) {
        NSArray *paramArray = [[actionCompment lastObject] componentsSeparatedByString:@"&"];
        for (NSString *perParam in paramArray) {
            [resultParamArray addObject:[[perParam componentsSeparatedByString:@"="] lastObject]];
        }
    }
    AppsRouterRequest  *request = [[AppsRouterRequest alloc] initWithRouteUrl:actionUrl params:resultParamArray callBack:callBack];
    return [self handleActionRequest:request];
}


+(id)handleActionRequest:(AppsRouterRequest *)request{
    
    NSString *actionUrl = request.routeUrl;
    void (^ actionCallBack)(id) = request.actionCallBack;
    NSArray *resultParamArray = request.paramArray;
    
    // 解析URL
    NSArray *moduleCompment = [actionUrl componentsSeparatedByString:@"/"];
    if (moduleCompment.count < 2) {
        return nil;
    }
    
    NSArray *actionCompment = [[moduleCompment lastObject] componentsSeparatedByString:@"?"];
    NSString *methodName = [actionCompment firstObject];
    
    NSString *moduleName = [moduleCompment firstObject];
    NSDictionary *moduleDict = globalModuleActionsDict()[moduleName];
    
    if (moduleDict == nil) {
        @throw [NSException exceptionWithName:@"抛异常错误" reason:[NSString stringWithFormat:@"没有找到模块:%@",moduleName] userInfo:nil];
    }
    // 获取到 module信息 执行对应的 method
    NSString *moduleClassName = moduleDict[@"classname"];
    
    Class actionClass = NSClassFromString(moduleClassName);
    id actionInstance = [[actionClass alloc] init];
    
    
    BOOL isClassMethod = NO;
    
    Method resultMethod = [self findMethodWithCls:actionClass methodName:methodName classMethod:&isClassMethod];
    if (resultMethod == nil) {
        @throw [NSException exceptionWithName:@"抛异常错误" reason:[NSString stringWithFormat:@"没有找到方法%@",methodName] userInfo:nil];
    }
    
    SEL methodSelector = method_getName(resultMethod);
    
    NSMethodSignature *methodSignature = nil;
    
    if (isClassMethod) {
        methodSignature = [actionClass methodSignatureForSelector:methodSelector];
    }else{
        methodSignature = [actionClass instanceMethodSignatureForSelector:methodSelector];
    }
    
    if(methodSignature == nil){
        @throw [NSException exceptionWithName:@"抛异常错误" reason:[NSString stringWithFormat:@"方法%@签名失败",methodName] userInfo:nil];
    }else{
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        
        if (isClassMethod) {
            [invocation setTarget:actionClass];
        }else{
            [invocation setTarget:actionInstance];
        }
        
        [invocation setSelector:methodSelector];
        //签名中方法参数的个数，内部包含了self和_cmd，所以参数从第3个开始
        NSInteger  signatureParamCount = methodSignature.numberOfArguments - 2;

        NSInteger requireParamCount = resultParamArray.count;
        NSInteger resultParamCount = MIN(signatureParamCount, requireParamCount);

        for (NSInteger i = 0; i < resultParamCount; i++) {
            id  obj = resultParamArray[i];
            [invocation setArgument:&obj atIndex:i+2];
        }

        if (actionCallBack) {
            [invocation setArgument:&actionCallBack atIndex:resultParamCount+2];
        }
        [invocation invoke];// 执行函数
        //返回值处理
        // getReturnValue只是值拷贝， 此处如果直接用 id,会被认为是 strong，当离开作用域时callBackObject 被释放，所以直接用了C ，最后再转换为id
        void *callBackObject;
        if(methodSignature.methodReturnLength)
        {
            [invocation getReturnValue:&callBackObject];
            id resultreturn = (__bridge id)callBackObject;
            return resultreturn; // 返回返回值
        }
        return nil;
    }
}

NSMutableDictionary* globalVcDict() {
    static NSMutableDictionary* globalVcDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalVcDict = [NSMutableDictionary dictionary];
    });
    return globalVcDict;
}

NSMutableDictionary* globalModuleActionsDict() {
    static NSMutableDictionary* globalModuleActionsDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalModuleActionsDict = [NSMutableDictionary dictionary];
    });
    return globalModuleActionsDict;
}

@end

@implementation AppsRouterRequest : NSObject

-(instancetype)initWithRouteUrl:(NSString *)url params:(NSArray *)array callBack:(void(^)(id))callBack{
    self = [super init];
    if (self) {
        self.routeUrl = url;
        self.paramArray = array;
        self.actionCallBack = callBack;
    }
    return self;
}

@end
