//
//  YXUWebView.h
//  Pods
//
//  Created by 赵贵莲 on 16/2/20.
//
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>


#define kDef_Use_WKWebView      1   // webKit有些问题


@class YXUWebView;
@protocol YXUWebViewDelegate <NSObject>
@optional

- (void)webViewDidStartLoad:(YXUWebView *)webView;
- (void)webViewDidFinishLoad:(YXUWebView *)webView;
- (void)webView:(YXUWebView *)webView didFailLoadWithError:(NSError *)error;
- (BOOL)webView:(YXUWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType;
@end

@interface YXUWebView : UIView
<
UIWebViewDelegate,
WKNavigationDelegate,
WKUIDelegate
>

@property(weak,nonatomic)id<YXUWebViewDelegate> delegate;

///内部使用的webView
@property (nonatomic, readonly) id realWebView;
///是否正在使用 UIWebView
@property (nonatomic, readonly) BOOL usingUIWebView;

///---- UI 或者 WK 的API
@property (nonatomic, readonly) UIScrollView *scrollView;
//@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly) NSURLRequest *originRequest;
@property (nonatomic, readonly) NSURLRequest *currentRequest;
@property (nonatomic, readonly) NSURL *URL;

@property (nonatomic, readonly, getter=isLoading) BOOL loading;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;
@property (nonatomic) BOOL scalesPageToFit;//是否根据视图大小来缩放页面  默认为YES

// 创建，是否使用WKWebView
- (instancetype)initWithFrame:(CGRect)frame usingWebKit:(BOOL)webkit;

// 加载请求
- (id)loadRequest:(NSURLRequest *)request;
- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

- (id)goBack;
- (id)goForward;
- (id)reload;
- (id)reloadFromOrigin;
- (void)stopLoading;

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString; //__deprecated_msg("Method deprecated. Use [evaluateJavaScript:completionHandler:]");

- (NSString *)getWebTitle;
//config useragent
- (NSString *)configUserAgent:(NSString *)newUserAgent;
@end
