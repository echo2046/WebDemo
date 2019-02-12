//
//  YXWebVC.m
//  YXP-iOS
//
//  Created by liyang on 14/11/11.
//  Copyright (c) 2014年 youxinpai. All rights reserved.
//

#import "YXWebVC.h"
//#import "UIViewController+HUD.h"
//#import "UIViewController+NavigationBar.h"
//#import "YXULolita.h"

static NSString *gs_userAgent = nil;

#if !CLIENT_DBM
#define kDef_Title_Loading      @"正在加载..."
#else
#define kDef_Title_Loading      @""
#endif

@interface YXWebVC ()
{
    NSURLRequest *_prevRequest;
    // HTTPS证书认证
    BOOL _authenticated;
    NSURLConnection *_urlConnection;
    NSURLRequest  *_failedRequest;

    NSURLRequest *_homeRequest;
}

@end

@implementation YXWebVC

@synthesize webView = _webView;

- (void)setUserAgent:(NSString *)userAgent
{
#define kKey_Agent  @"UserAgent"
    
#if kDef_Global_UserAgent
    if (userAgent.length < 1) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKey_Agent];
        return;
    }
    //    ASSERT(userAgent.length > 0);
    //get the original user-agent of webview
   // LOG(@"web %@",self.webView);
    gs_userAgent =  [self.webView configUserAgent:userAgent];
#endif

}

- (NSString *)userAgent;
{
    return (gs_userAgent);
}

- (void)dealloc{
  //  LOG(@"YXWebVC dealloc");
    [_webView stopLoading];
    _webView.delegate = nil;
    [_webView removeFromSuperview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.title = self.staticTitle?: kDef_Title_Loading;
    _webView = [[YXUWebView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height) usingWebKit:!_isUIWeb];
    [self.view addSubview:_webView];
   
    _webView.delegate = self;

    [self createBackButton];
    [self creatRefreshBtn];
    [self performSelector:@selector(loadFirst) withObject:nil afterDelay:.1];
}
- (void)createBackButton
{
    // 回退按钮和拖动返回
    if (self.navigationController.viewControllers.count > 1)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(0, 0, 64, 44);
        [btn setImage:[UIImage imageNamed:@"icon_chexiangqing_titlebar_back"] forState:UIControlStateNormal];
        [btn setTitle:@"返回" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [btn setTitleEdgeInsets:UIEdgeInsetsMake(1, -15, 0, 0)];
        [btn setImageEdgeInsets:UIEdgeInsetsMake(0, -25, 0, 0)];
        [btn addTarget:self action:@selector(onNavBack:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = item;
        self.navigationItem.leftItemsSupplementBackButton = NO;
    }
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)creatRefreshBtn{
    
    if (_hideRefreshButton)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        if (!self.navigationItem.rightBarButtonItem)
        {
            UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            rightBtn.frame = CGRectMake(0, 0, 20, 20);
            //[rightBtn setImage:_IMAGE(@"reload_btn") forState:UIControlStateNormal];
            [rightBtn addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
        }
    }
}
- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    NSString *str = [self getWebTitle];
    self.title = (str.length > 0) ? str : kDef_Title_Loading;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUrl:(NSString *)url;
{
    _url = [url copy];
}


- (void)loadFirst;
{
    if (_url.length > 0) {
        //[self loadURL:_url];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:200]];
    }
}

- (BOOL)loadURL:(NSString *)url;
{
    BOOL ret = NO;
    if (url.length > 0)
    {
        url = [self urlStringClipKVC:url];
        NSURLRequest *uu = [self updateRequest:url];
        ret = [self loadRequest:uu];
    }
    return (ret);
}

- (NSURLRequest *)updateRequest:(NSString *)url
{
    if (url && url.length > 0)
    {
        return [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    }
    return nil;
}

- (BOOL)loadRequest:(NSURLRequest*)request;
{
  //  ASSERT_Class(request, NSURLRequest);
    if (self.postParams) {
        NSMutableURLRequest *req = [request isKindOfClass:[NSMutableURLRequest class]] ? request : [request mutableCopy];
        [req addPostBody:self.postParams];
        request = req;
    }
    NSURL *url = request.URL;
    if (url && ![url isFileURL])
    {
        if (!_homeRequest) {
            _homeRequest = request;
        }
        [self.webView loadRequest:request];
        return (YES);
    }
    return (NO);
}

- (void)reload;
{
    [_webView reload];
}

- (void)onNavBack:(id)sender;
{

    if (_navigationBackBlock && [_navigationBackBlock isKindOfClass:NSClassFromString(@"NSBlock")])
    {
        _navigationBackBlock();
        return;
    }
    if (_webView.canGoBack)
    {
        [_webView goBack];
    }
    else
    {
        //网页的音频不会自己停止播放要重新加载一下页面才可以
        //[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        //[super onNavBack:sender];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSString *)getWebTitle;
{
    NSString *ret = _staticTitle;
    if(ret.length < 1){
        ret = [_webView getWebTitle];
    }
    return (ret?:@"");
}
- (NSString *)getWebImageURL;
{
    NSString *str = [_webView stringByEvaluatingJavaScriptFromString:@"document.querySelector(\"img\").outerHTML"];
   // str = [str matchFirstStringWithRegular:@"http(s)*://[^\"\\s]+"];
    return (str);
}
- (UIImage *)getWebImage;       // 获取web页的图片
{
    UIImage *ret = nil;
//    NSString *url = [self getWebImageURL];
    return (ret);
}

// 把url字符串里面的kvc键值给砍掉
- (NSString *)urlStringClipKVC:(NSString *)urlString;
{
    NSString *full = urlString;
        return (full);
}
- (NSDictionary *)kvc_diffParams:(NSDictionary *)dictionary;
{
    
    NSDictionary *ret = dictionary;
    @try {
        NSArray *keys = [dictionary allKeys];
        NSDictionary *dic = [self dictionaryWithValuesForKeys:keys];
        //dic = [dic dictionaryByRemoveNullObject];
        if (dic.count > 0) {
            NSMutableDictionary *tmp = [dictionary mutableCopy];
            [tmp removeObjectsForKeys:[dic allKeys]];
            ret = [tmp copy];
        }
    } @catch (NSException *exception) {
       
        ret = nil;
    } @finally {
    }
    return ((ret.count > 0) ? ret : nil);
}
#pragma mark -
- (void)onWebFinished:(BOOL)finished;
{
    NSString *str = [self getWebTitle];
    
    self.title = (str.length > 0) ? str : @"网页";
    if (self.block_getWebTitleBlock) {
        self.block_getWebTitleBlock(str);
    }
    self.title = (str.length > 0) ? str : @"";
}
- (void)webViewDidFinishLoad:(YXUWebView *)webView{
    [self onWebFinished:!webView.loading];
}
// 解决HTTPS证书问题
#pragma mark NSURLConectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] == 0)
    {
        _authenticated =YES;
        
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
    } else
    {
        [[challenge sender]cancelAuthenticationChallenge:challenge];
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    _authenticated =YES;
    [_urlConnection cancel];
    [_webView loadRequest:_failedRequest];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
  //  LOG(@"error!!! = %@",error);
}

#pragma mark - Lolita
/*
- (void)setLolita:(Object_Lolita *)lolita;
{
    // xinapp://mobile/YXWebVC -> http://www.qq.com/...
    NSString *str = [lolita.params safe_stringForKey:@"url"];
    Object_Lolita *lolita2 = (str.length > 0) ? [Object_Lolita URLWithString:str] : nil;
    [super setLolita:lolita2?:lolita];
}*/

@end

@implementation NSMutableURLRequest (SetPostBody)

- (void)addPostBody:(NSDictionary *)postDictionary;
{
}


@end
