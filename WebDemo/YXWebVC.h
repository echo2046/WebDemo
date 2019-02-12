//
//  YXWebVC.h
//  YXP-iOS
//
//  Created by liyang on 14/11/11.
//  Copyright (c) 2014年 youxinpai. All rights reserved.
//

#import "YXUWebView.h"

#define kDef_Global_UserAgent       1   // 是否所有网站都设置uerAgent

#pragma mark - 接口

typedef void (^block_navigationBackBlock)();
typedef void (^block_getWebTitleBlock)(NSString *title);

@interface YXWebVC : UIViewController
<
UIScrollViewDelegate,
YXUWebViewDelegate,
//NSURLConnectionDataDelegate,
NSURLConnectionDelegate
>

//+ (void)setUserAgent:(NSString *)userAgent;
//+ (NSString *)userAgent;

@property (nonatomic, assign) BOOL hideRefreshButton;     // default NO
@property (nonatomic, strong) NSString *staticTitle;        // 固定title

@property (nonatomic, strong, readonly) YXUWebView *webView;
@property (nonatomic, strong) NSString *url;            // static URL for this web instance
@property (nonatomic, strong) NSDictionary *postParams; // POST request
@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, assign) BOOL isUIWeb;
- (void)creatRefreshBtn; // 创建刷新按钮

// 加载
- (BOOL)loadURL:(NSString *)url;
- (BOOL)loadRequest:(NSURLRequest *)request;

// 回退
@property (nonatomic, strong) block_navigationBackBlock navigationBackBlock;
- (void)onNavBack:(id)sender;
@property (nonatomic, copy) block_getWebTitleBlock block_getWebTitleBlock; //获取标题

- (void)reload;     // 重新加载

- (NSString *)getWebTitle;          // 获取web页的title，解析处理后
- (NSString *)getWebImageURL;       // 获取web页的图片链接
- (UIImage *)getWebImage;       // 获取web页的图片

// 成功、结束、失败的处理
- (BOOL)onWebStart:(NSURLRequest *)request navigationType:(NSInteger)navigationType;
- (void)onWebStart;
- (void)onWebFinished:(BOOL)finished;
- (void)onWebFailed:(BOOL)finished withError:(NSError *)error;

@end

#pragma mark - NSMutableURLRequest + Post

@interface NSMutableURLRequest (SetPostBody)

- (void)addPostBody:(NSDictionary *)postDictionary;

/**
 显示进度条
 */
- (void)showProgresss;

@end
