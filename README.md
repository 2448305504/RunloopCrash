# RunloopCrash
iOS崩溃起死回生

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [UncaughtExceptionHandle installUncaughtSignalExceptionHandler];
    return YES;
}
```

控制台会打印崩溃路径-那是崩溃日志内容
