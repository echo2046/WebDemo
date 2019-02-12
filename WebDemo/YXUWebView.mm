//
//  YXUWebView.m
//  Pods
//
//  Created by 赵贵莲 on 16/2/20.
//
//

#import "YXUWebView.h"

@interface YXUWebView(){
    NSDate *webDate1;
    NSDate *wkDate1;
}
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSURLRequest *originRequest;
@property (nonatomic, strong) NSURLRequest *currentRequest;

@end

@implementation YXUWebView
@synthesize scalesPageToFit = _scalesPageToFit;

- (NSString *)configUserAgent:(NSString *)newUserAgent
{
    __block NSString *oldAgent = @"";
    if (!_usingUIWebView)//默认iOS8使用wkwebview
    {
        WKWebView *web = self.realWebView;
        [web evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result,NSError *error){
            oldAgent = result;
        }];
    }
    else
    {
        UIWebView *webView = self.realWebView;
        oldAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    }
    //add my info to the new agent
    NSString *newAgent = newUserAgent;
    if (oldAgent.length > 0) {
        newAgent = [oldAgent stringByAppendingFormat:@" %@", newUserAgent];
    }
    
    //regist the new agent
    NSDictionary *dictionnary = @{@"UserAgent": newAgent?:@""};
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
    
    return newUserAgent;
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _initMyself];
    }
    return self;
}
- (instancetype)init
{
    return [self initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64)];
}
- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame usingWebKit:YES];
}
- (instancetype)initWithFrame:(CGRect)frame usingWebKit:(BOOL)webkit;
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _usingUIWebView = !webkit;
        [self _initMyself];
    }
    return self;
}
-(void)_initMyself
{
    if (![NSThread isMainThread])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _initMyself];
        });
        return;
    }
    Class wkWebView = NSClassFromString(@"WKWebView");
    if(wkWebView && !_usingUIWebView)
    {
        [self initWKWebView];
        _usingUIWebView = NO;
    } else {
        [self initUIWebView];
        _usingUIWebView = YES;
    }
    self.scalesPageToFit = YES;
    
    [self.realWebView setFrame:self.bounds];
    [self.realWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self addSubview:self.realWebView];
}
-(void)initWKWebView
{
    WKPreferences *preferences = [WKPreferences new];
    preferences.javaScriptEnabled = YES;
    preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.preferences = preferences;
    configuration.userContentController = [WKUserContentController new];
    configuration.allowsInlineMediaPlayback = YES;
    
    WKWebView* webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    webView.allowsBackForwardNavigationGestures = NO;
    
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    _realWebView = webView;
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"title"]) {
        self.title = change[NSKeyValueChangeNewKey];
    }
}
-(void)initUIWebView
{
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.bounds];
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    webView.scalesPageToFit = YES;
    webView.allowsInlineMediaPlayback = YES;
    for (UIView *subview in [webView.scrollView subviews])
    {
        if ([subview isKindOfClass:[UIImageView class]])
        {
            ((UIImageView *) subview).image = nil;
            subview.backgroundColor = [UIColor clearColor];
        }
    }
    webView.delegate = self;
    _realWebView = webView;
}
- (NSString *)getWebTitle
{
    NSString *title = [self stringByEvaluatingJavaScriptFromString:@"document.getElementById('app_title').innerHTML"];
    if (title.length > 0) {
        return title;
    }else{
        title = [self stringByEvaluatingJavaScriptFromString:@"document.title"];
        if (title.length > 0) {
            // 正则表达式解析
            NSString *str = @"";//[title matchFirstStringWithRegular:@"【\\w{2,}】"];
            if (str.length > 2)
            {
                str = [str substringWithRange:NSMakeRange(1, str.length - 2)];
                return str;
            }
            NSArray *arr = [title componentsSeparatedByString:@"_"];
            for (NSString *str in arr)
            {
               // LOG(@"cc: %ld, %@", (unsigned long)str.length, str);
                if (str.length > 0)
                {
                    return str;
                }
            }
        }
    }
    return title;
}

#pragma mark- UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.title = [self getWebTitle];
    
    if(self.originRequest == nil)
    {
        self.originRequest = webView.request;
    }
#if !CLIENT_DBM
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
#endif

    NSLog(@"uiweb time internal is %f",[[NSDate date]timeIntervalSinceDate:webDate1]);
    [self callback_webViewDidFinishLoad];
}
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    webDate1 = [NSDate date];
    [self callback_webViewDidStartLoad];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self callback_webViewDidFailLoadWithError:error];
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    self.title = [self getWebTitle];
    BOOL resultBOOL = [self callback_webViewShouldStartLoadWithRequest:request navigationType:navigationType];
    return resultBOOL;
}

#pragma mark- WKNavigationDelegate
/**
 *  在发送请求之前，决定是否跳转
 *
 *  @param webView          实现该代理的webview
 *  @param navigationAction 当前navigation
 *  @param decisionHandler  是否调转block
 */
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    BOOL resultBOOL = [self callback_webViewShouldStartLoadWithRequest:navigationAction.request navigationType:navigationAction.navigationType];
    if(resultBOOL)
    {
        self.currentRequest = navigationAction.request;
        if(navigationAction.targetFrame == nil)
        {
            [webView loadRequest:navigationAction.request];
        }
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else
    {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}
/**
 *  页面开始加载时调用
 *
 *  @param webView    实现该代理的webview
 *  @param navigation 当前navigation
 */
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    wkDate1 = [NSDate date];
    [self callback_webViewDidStartLoad];
}
/**
 *  页面加载完成之后调用
 *
 *  @param webView    实现该代理的webview
 *  @param navigation 当前navigation
 */
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"wkweb time internal is %f",[[NSDate date]timeIntervalSinceDate:wkDate1]);
    [self callback_webViewDidFinishLoad];
}
/**
 *  加载失败时调用
 *
 *  @param webView    实现该代理的webview
 *  @param navigation 当前navigation
 *  @param error      错误
 */
- (void)webView:(WKWebView *) webView didFailProvisionalNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self callback_webViewDidFailLoadWithError:error];
}

- (void)webView: (WKWebView *)webView didFailNavigation:(WKNavigation *) navigation withError: (NSError *) error
{
    [self callback_webViewDidFailLoadWithError:error];
}
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler
{
/*
    if (challenge.previousFailureCount == 0) {
        // 自动认证不可信的证书
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }*/
    
    NSString *authenticationMethod = [[challenge protectionSpace] authenticationMethod];
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        NSURLCredential *credential = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
    /*
    NSString *hostName = webView.URL.host;
    NSString *authenticationMethod = [[challenge protectionSpace] authenticationMethod];
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        SecTrustRef secTrustRef = challenge.protectionSpace.serverTrust;
        if (secTrustRef != NULL)
        {
            SecTrustResultType result;
            OSErr er = SecTrustEvaluate(secTrustRef, &result);
            if (er != noErr)
            {
                completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace,nil);
                return;
            }
            if (result == kSecTrustResultRecoverableTrustFailure)
            {
                //证书不受信任
                CFArrayRef secTrustProperties = SecTrustCopyProperties(secTrustRef);
                NSArray *arr = CFBridgingRelease(secTrustProperties);
                NSMutableString *errorStr = [NSMutableString string];
                for (int i=0;i<arr.count;i++)
                {
                    NSDictionary *dic = [arr objectAtIndex:i];
                    
                    if (i != 0 ) [errorStr appendString:@" "];
                    [errorStr appendString:(NSString*)dic[@"value"]];
                }
                SecCertificateRef certRef = SecTrustGetCertificateAtIndex(secTrustRef, 0);
                CFStringRef cfCertSummaryRef = SecCertificateCopySubjectSummary(certRef);
                NSString *certSummary = (NSString *)CFBridgingRelease(cfCertSummaryRef);
                NSString *title = @"该服务器无法验证";
                NSString *message = [NSString stringWithFormat:@" 是否通过来自%@标识为 %@证书为%@的验证. \n%@" , @"我的app",hostName,certSummary, errorStr];
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
                    NSURLCredential* credential = [NSURLCredential credentialForTrust:secTrustRef];
                    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
                }]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    //[self presentViewController:alertController animated:YES completion:^{}];
                });
                return;
            }
            NSURLCredential* credential = [NSURLCredential credentialForTrust:secTrustRef];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return;
        }
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    }
    else
    {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }*/
}
#pragma mark- WKUIDelegate
///--  还没用到
#pragma mark- CALLBACK YXUWebView Delegate

- (void)callback_webViewDidFinishLoad
{
    if([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)])
    {
        [self.delegate webViewDidFinishLoad:self];
    }
}
- (void)callback_webViewDidStartLoad
{
    if([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)])
    {
        [self.delegate webViewDidStartLoad:self];
    }
}
- (void)callback_webViewDidFailLoadWithError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
    {
        [self.delegate webView:self didFailLoadWithError:error];
    }
}
-(BOOL)callback_webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType
{
    BOOL resultBOOL = YES;
    if (_usingUIWebView) {
        if([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
        {
            if(navigationType == -1) {
                navigationType = UIWebViewNavigationTypeOther;
            }
            resultBOOL = [self.delegate webView:self shouldStartLoadWithRequest:request navigationType:(UIWebViewNavigationType)navigationType];
        }
    }
    else
    {
        if([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
        {
            if(navigationType == -1) {
                navigationType = WKNavigationTypeOther;
            }
            resultBOOL = [self.delegate webView:self shouldStartLoadWithRequest:request navigationType:(WKNavigationType)navigationType];
        }
    }
    return resultBOOL;
}

#pragma mark- 基础方法
-(UIScrollView *)scrollView
{
    return [(id)_realWebView scrollView];
}

- (id)loadRequest:(NSURLRequest *)request
{
   // ASSERT_ClassOrNil(request, NSURLRequest);
    if (![request isKindOfClass:[NSURLRequest class]] || !request) {
        return nil;
    }
    self.originRequest = request;
    self.currentRequest = request;
    
    if(_usingUIWebView)
    {
        [(UIWebView*)_realWebView loadRequest:request];
        return nil;
    }
    else
    {
        return [(WKWebView*)_realWebView loadRequest:request];
    }
}
- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
   // ASSERT(string.length > 0);
    if(_usingUIWebView)
    {
        [(UIWebView*)_realWebView loadHTMLString:string baseURL:baseURL];
        return nil;
    }
    else
    {
        return [(WKWebView*)_realWebView loadHTMLString:string baseURL:baseURL];
    }
}
-(NSURLRequest *)currentRequest
{
    if(_usingUIWebView)
    {
        return [(UIWebView*)_realWebView request];;
    }
    else
    {
        return _currentRequest;
    }
}
-(NSURL *)URL
{
    if(_usingUIWebView)
    {
        return [(UIWebView*)_realWebView request].URL;;
    }
    else
    {
        return [(WKWebView*)_realWebView URL];
    }
}
-(BOOL)isLoading
{
    return [_realWebView isLoading];
}
-(BOOL)canGoBack
{
    return [_realWebView canGoBack];
}
-(BOOL)canGoForward
{
    return [_realWebView canGoForward];
}

- (id)goBack
{
    if(_usingUIWebView)
    {
        [(UIWebView*)_realWebView goBack];
        return nil;
    }
    else
    {
        return [(WKWebView*)_realWebView goBack];
    }
}
- (id)goForward
{
    if(_usingUIWebView)
    {
        [(UIWebView*)_realWebView goForward];
        return nil;
    }
    else
    {
        return [(WKWebView*)_realWebView goForward];
    }
}
- (id)reload
{
    if(_usingUIWebView)
    {
        [(UIWebView*)_realWebView reload];
        return nil;
    }
    else
    {
        return [(WKWebView*)_realWebView reload];
    }
}
- (id)reloadFromOrigin
{
    if(_usingUIWebView)
    {
        if(self.originRequest)
        {
            [self evaluateJavaScript:[NSString stringWithFormat:@"window.location.replace('%@')",self.originRequest.URL.absoluteString] completionHandler:nil];
        }
        return nil;
    }
    else
    {
        return [(WKWebView*)self.realWebView reloadFromOrigin];
    }
}
- (void)stopLoading
{
    [self.realWebView stopLoading];
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    if(_usingUIWebView)
    {
        NSString* result = [(UIWebView*)self.realWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
        if(completionHandler)
        {
            completionHandler(result,nil);
        }
    }
    else
    {
        return [(WKWebView*)self.realWebView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
    }
}
-(NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString
{
    if(_usingUIWebView)
    {
       // ASSERT_Class(_realWebView, UIWebView);
        NSString* result = [(UIWebView*)_realWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
        return result;
    }
    else
    {
       // ASSERT_Class(_realWebView, WKWebView);
        __block NSString* result = nil;
        __block BOOL isExecuted = NO;
        [(WKWebView*)_realWebView evaluateJavaScript:javaScriptString
                                   completionHandler:^(id obj, NSError *error) {
                                       if ([obj isKindOfClass:[NSString class]]) {
                                           result = obj;
                                       } else {
                                           result = [obj description];
                                       }
                                       isExecuted = YES;
                                   }];

        while (isExecuted == NO) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        return result;
    }
}
-(void)setScalesPageToFit:(BOOL)scalesPageToFit
{
    if(_usingUIWebView)
    {
       // ASSERT_Class(_realWebView, UIWebView);
        UIWebView* webView = _realWebView;
        webView.scalesPageToFit = scalesPageToFit;
    }
    else
    {
    //    ASSERT_Class(_realWebView, WKWebView);
        if(_scalesPageToFit == scalesPageToFit)
        {
            return;
        }
        
        WKWebView* webView = _realWebView;
        
        NSString *jScript = @"var meta = document.createElement('meta'); \
        meta.name = 'viewport'; \
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; \
        var head = document.getElementsByTagName('head')[0];\
        head.appendChild(meta);";
        
        if(scalesPageToFit)
        {
            WKUserScript *wkUScript = [[NSClassFromString(@"WKUserScript") alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
            [webView.configuration.userContentController addUserScript:wkUScript];
        }
        else
        {
            NSMutableArray* array = [NSMutableArray arrayWithArray:webView.configuration.userContentController.userScripts];
            for (WKUserScript *wkUScript in array)
            {
                if([wkUScript.source isEqual:jScript])
                {
                    [array removeObject:wkUScript];
                    break;
                }
            }
            for (WKUserScript *wkUScript in array)
            {
                [webView.configuration.userContentController addUserScript:wkUScript];
            }
        }
    }
    
    _scalesPageToFit = scalesPageToFit;
}
-(BOOL)scalesPageToFit
{
    if(_usingUIWebView)
    {
        return [_realWebView scalesPageToFit];
    }
    else
    {
        return _scalesPageToFit;
    }
}
#pragma mark-  如果没有找到方法 去realWebView 中调用
-(BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL hasResponds = [super respondsToSelector:aSelector];
    if(hasResponds == NO)
    {
        hasResponds = [self.delegate respondsToSelector:aSelector];
    }
    if(hasResponds == NO)
    {
        hasResponds = [self.realWebView respondsToSelector:aSelector];
    }
    return hasResponds;
}
- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature* methodSign = [super methodSignatureForSelector:selector];
    if(methodSign == nil)
    {
        if([self.realWebView respondsToSelector:selector])
        {
            methodSign = [self.realWebView methodSignatureForSelector:selector];
        }
        else
        {
            methodSign = [(id)self.delegate methodSignatureForSelector:selector];
        }
    }
    return methodSign;
}
- (void)forwardInvocation:(NSInvocation*)invocation
{
    if([self.realWebView respondsToSelector:invocation.selector])
    {
        [invocation invokeWithTarget:self.realWebView];
    }
    else
    {
        [invocation invokeWithTarget:self.delegate];
    }
}

#pragma mark- 清理
-(void)dealloc
{
    if(_usingUIWebView)
    {
        UIWebView* webView = _realWebView;
        webView.delegate = nil;
    }
    else
    {
        WKWebView* webView = _realWebView;
        webView.UIDelegate = nil;
        webView.navigationDelegate = nil;
        [webView removeObserver:self forKeyPath:@"title"];
    }
    [_realWebView scrollView].delegate = nil;
    [_realWebView stopLoading];
    [(UIWebView*)_realWebView loadHTMLString:@"" baseURL:nil];
    [_realWebView stopLoading];
    [_realWebView removeFromSuperview];
    _realWebView = nil;
}

@end
