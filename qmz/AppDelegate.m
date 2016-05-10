//
//  AppDelegate.m
//  qmz
//
//  Created by Sharon on 16/3/20.
//  Copyright (c) 2016年 Baimei. All rights reserved.
//

#import "AppDelegate.h"
#import "WXApiObject.h"
#import "ViewController.h"
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>
#import <CoreLocation/CoreLocation.h>


#define AppID @"wx9598f60c95b2621f"
#define Description @"翘拇指社区 1.0"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    BOOL isRegistered = [WXApi registerApp:AppID withDescription:Description];
    
    if (isRegistered)
    {
        NSLog(@"微信注册成功");
    }
    else
    {
        NSLog(@"微信注册失败");
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >=8.0)
    {
        CLLocationManager* location = [CLLocationManager new];
        [location requestAlwaysAuthorization];
    }

    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    if ([url.host isEqualToString:@"safepay"]) {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSNumber* resultStatus = [resultDic objectForKey:@"resultStatus"];
            
            // 成功
            if (9000 == resultStatus.intValue)
            {
                NSString* result =[resultDic objectForKey:@"result"];
                NSArray *components = [result componentsSeparatedByString:@"&"];
                
                if ([components count] > 2)
                {
                    NSString* trade_no = [components objectAtIndex:2];
                    
                    if (nil != trade_no)
                    {
                        trade_no = [trade_no stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        trade_no = [trade_no stringByReplacingOccurrencesOfString:@"out_trade_no=" withString:@""];
                    }
                    
                    NSString* url = [NSString stringWithFormat:@"http://123.56.194.23:8080/mobile/order/pay/success?orderNumber=%@", trade_no];
                    
                    NSLog(@"支付宝结果发送 url = %@", url);
                    
                    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
                    
                    
                    ViewController *view = [[ViewController alloc] init];
                    [view.webView loadRequest:request];
                }
            }
            // 用户取消
            else if (6001 == resultStatus.intValue)
            {
                
            }
            // 网络连接错误
            else if (6002 == resultStatus.intValue)
            {
                
            }
            NSLog(@"支付宝 result = %@",resultDic);
        }];
    }
    return YES;
}

@end
