//
//  ViewController.m
//  qmz
//
//  Created by Sharon on 16/3/20.
//  Copyright (c) 2016年 Baimei. All rights reserved.
//

#import "ViewController.h"
#import "WXApiObject.h"
#import "WXApi.h"
#import "Order.h"
#import "DataSigner.h"
#import <AlipaySDK/AlipaySDK.h>
#import <CoreLocation/CoreLocation.h>


@interface ViewController ()<UIWebViewDelegate,WXApiDelegate>

@end

#define QMZNETWORK @"http://123.56.194.23:8080"
//#define QMZNETWORK @"http://192.168.0.211:8080"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _webView.delegate = self;
    [_webView.scrollView setBounces:NO];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:QMZNETWORK]];
    [_webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *requestString = [[request URL] absoluteString];
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    if ([components count] > 7 && [(NSString *)[components objectAtIndex:0] isEqualToString:@"wxapppay"])
    {
        NSString* appid = [components objectAtIndex:1];
        NSString* partnerid = [components objectAtIndex:2];
        NSString* prepayid = [components objectAtIndex:3];
        NSString* packageval = [components objectAtIndex:4];
        NSString* noncestr = [components objectAtIndex:5];
        NSNumber* timestamp = [components objectAtIndex:6];
        NSString* sign = [components objectAtIndex:7];
        
        PayReq *request = [[PayReq alloc] init];
        request.openID = appid;
        request.partnerId = partnerid;
        request.prepayId = prepayid;
        request.package = packageval;
        request.nonceStr = noncestr;
        request.timeStamp = timestamp.unsignedIntValue;
        request.sign = sign;
        [WXApi sendReq:request];
        
        return NO;
    }
    else if ([components count] > 2 && [(NSString*)[components objectAtIndex:0] isEqualToString:@"aliapppay"])
    {
        NSString* orderNumber = [components objectAtIndex:1];
        NSNumber* totalPrice = [components objectAtIndex:2];
        NSString* privateKey = @"MIICXAIBAAKBgQCjBViVMpVwT+h49Bb0XF5nxBACfJWlcH6C/5XxeC2PsRxHJxOSPws36ww+y1r9K2hZI02hlR6jCrwbJ+nHghK3PfUCu6qrFY2OJXnbTlCbKDO3ckc5GepknT7e+EfAangs2j0vqaftIugwlEEMSp0Yx8wYOaHHqeaxqdkw1j9A5wIDAQABAoGAFVo16BTgDf3pbS5Lc2ZF10GO90RqNWkuqOnhMeeT0CZalddAcP9g8MoQqIjqOg7ddA9zs55cjO5zBPuNW1xmJvSWjLkJmFpl1VFMgx3e0KUbbePjL2TexZHo4IE3/9AOdK2gNAwOYrmNvqXP+nhJk1XDbfM5rFZy5U/7K0npRgECQQDXnngwW0L5iLf3quB/QnTPwVRD/vWMwzd8KZF1vwO7qwAYIhAa/3U6RyyjRMITWtGiC09hx+Gbp0jSCEWEfRYHAkEAwY0jP/fOGqQ4BiYraKU3pSYwnxmkaiLPG2dNr5yCOmylXBXTFWKZjP+6HO0DHC2m1tGc++N0fH7/x9EPbrrGIQJBAIHPxkxWpVvWE+vn1IDJYcoyeqj1NqAoZ58453ocJgM2UDg3Sbr3UXxknVsuail84/jLFl+oFwu/CvhoQnIhXMECQHp61dOk/MffI5TAkrel1ZCsmhgUIfcIEAdHV+HJKJ/QINQk+26M9p5DNYMYeN9cBDfsbWr4hL5Dn5jSsvFfQAECQCqzbldOZToki+E7EoPc3oP/gvqnKMTTrISd+k00DUihKLIY1EIbwBTnl8LpCafnHXyQC4OwXljNTyvrKxp6oZ0=";

        //将商品信息赋予AlixPayOrder的成员变量
        Order *order = [[Order alloc] init];
        order.partner = @"2088221263488473";
        order.seller = @"qmz_cq_888@126.com";
        order.tradeNO = orderNumber; //订单号
        order.productName = @"支付订单"; //商品标题
        order.productDescription = @"翘拇指社区额"; //商品描述
        order.amount = [NSString stringWithFormat:@"%.2f",totalPrice.floatValue]; //商品价格
        order.notifyURL =  @"http://123.56.194.23:8080/mobile/order/pay/result/ali"; //回调URL
        
        order.service = @"mobile.securitypay.pay";
        order.paymentType = @"1";
        order.inputCharset = @"utf-8";
        order.itBPay = @"30m";
        order.showUrl = @"m.alipay.com";
        
        //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
        NSString *appScheme = @"qmzalipay";
        
        //将商品信息拼接成字符串
        NSString *orderSpec = [order description];
        NSLog(@"orderSpec = %@",orderSpec);
        
        //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
        id<DataSigner> signer = CreateRSADataSigner(privateKey);
        NSString *signedString = [signer signString:orderSpec];
        
        //将签名成功字符串格式化为订单字符串,请严格按照该格式
        NSString *orderString = nil;
        if (signedString != nil) {
            orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                           orderSpec, signedString, @"RSA"];
            
            [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
                NSLog(@"支付宝pay reslut = %@",resultDic);
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
                        
                        [_webView loadRequest:request];
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
            }];
        }
    }
    return YES;
}

-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[PayResp class]])
    {
        //支付返回结果，实际支付结果需要去微信服务器端查询
        PayResp *response = (PayResp *)resp;
        
        switch (response.errCode)
        {
            case WXSuccess:
            {
                NSLog(@"支付成功");
            }
                break;
                
            case WXErrCodeUserCancel:
            {
                NSLog(@"用户取消");
            }
                break;
        }
        
    }
}

@end
