
#import "UncaughtExceptionHandle.h"
#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#include <stdatomic.h>

// key
NSString * const kUncaughtExceptionHanderSignalKey = @"UncaughtExceptionHanderSignalKey";
NSString * const kUncaughtExceptionHanderAddressKey = @"UncaughtExceptionHanderAddressKey";
NSString * const kUncaughtExceptionHanderFileKey = @"UncaughtExceptionHanderFileKey";
NSString * const kUncaughtExceptionHanderCallStackSymbolsKey = @"UncaughtExceptionHanderCallStackSymbolsKey";

atomic_int      UncaughtExceptionCount = 0;
const int32_t   UncaughtExceptionMaximum = 8;
const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionhandlerReportAddressCount = 5;

@implementation UncaughtExceptionHandle

// 注册捕获崩溃回调
+ (void)installUncaughtSignalExceptionHandler {
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
}

void UncaughtExceptionHandler(NSException *exception) {
    NSLog(@"%s", __func__);
    
    int32_t exceptionCount = atomic_fetch_add_explicit(&UncaughtExceptionCount, 1, memory_order_relaxed);
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    
    // 获取堆栈信息
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    NSArray *callStack = [UncaughtExceptionHandle backtrace];
    [userInfo setObject:callStack forKey:kUncaughtExceptionHanderAddressKey];
    [userInfo setObject:exception.callStackSymbols forKey:kUncaughtExceptionHanderCallStackSymbolsKey];
    [userInfo setObject:@"WJException_RunloopCrash" forKey:kUncaughtExceptionHanderFileKey];
    [[[UncaughtExceptionHandle alloc] init] performSelectorOnMainThread:@selector(wj_handleException:) withObject:[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo] waitUntilDone:YES];
}

// 获取堆栈
+ (NSArray *)backtrace {
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = 0; i < frames; i++) {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}

- (void)wj_handleException:(NSException *)exception {
    
    NSLog(@"崩溃名称：%@", exception.name);
    NSLog(@"崩溃原因：%@", exception.reason);
    NSLog(@"崩溃堆栈信息：%@", [exception userInfo]);
    // 保存崩溃堆栈信息
    [self saveCrash:[exception userInfo] fileName:[[exception userInfo] objectForKey:kUncaughtExceptionHanderFileKey]];
    
    // ps:可以在这里做崩溃信息的UI提示语
    
    // 起死回生  事件item -> mode -> runloop
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runloop);

    while (true) {
        for (NSString *mode in (__bridge NSArray *)allModes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
}

// 保存Crash内容 - 等下一次启动app的时候上传到服务器
- (void)saveCrash:(NSDictionary *)userInfo fileName:(NSString *)fileName {
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingFormat:@"%@", fileName];
    NSLog(@"path: %@", filePath);
    NSData *fileContents = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:0];
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];
}


@end
