//
//  ViewController.m
//  WebDemo
//
//  Created by 鱼头 on 2017/9/15.
//  Copyright © 2017年 鱼头. All rights reserved.
//

#import "ViewController.h"
#import "YXWebVC.h"
@interface ViewController ()
{
    UITextView *inputTextView;
    UISegmentedControl *segControl;
}
@end

@implementation ViewController
#define iosVersion  [[UIDevice currentDevice].systemVersion floatValue]
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"WebDemo";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createSubViews];
   // [self cacheDirectory];
}
- (void)cacheDirectory
{
    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary]
                            objectForKey:@"CFBundleIdentifier"];
    NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
    NSString *webKitFolderInCaches = [NSString
                                      stringWithFormat:@"%@/Caches/%@/WebKit",libraryDir,bundleId];
    NSString *webKitFolderInCachesfs = [NSString
                                        stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
    NSLog(@"webkitFolderInLib:%@,webKitFolderInCaches:%@,webKitFolderInCachesfs:%@",webkitFolderInLib,webKitFolderInCaches,webKitFolderInCachesfs);
}
- (void)createSubViews
{
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;

    //title label
    UILabel *titleLabel = [[UILabel alloc]init];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = @"请在下边的输入框输入url";
    titleLabel.textColor = [UIColor redColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:15];
    [titleLabel setFrame:CGRectMake(0, 100, screenWidth, 20)];
    [self.view addSubview:titleLabel];
    
    //input text view
    inputTextView = [[UITextView alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(titleLabel.frame) + 10, screenWidth - 40, 120)];
    inputTextView.delegate = self;
    inputTextView.backgroundColor = [UIColor lightGrayColor];
    [inputTextView setTextColor:[UIColor blackColor]];
    inputTextView.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:inputTextView];
#if 1
    inputTextView.text = @"http://m.ceshi.xin.com/common/prosell_intro/?cityid=201&from=app&nb=424cedb9af3046239aeae81c8b8b61f8";
    //@"https://m.xin.com/common/prosell_intro/?cityid=201&from=app&nb=424cedb9af3046239aeae81c8b8b61f8";
    //@"https://m.xin.com/common/prosell_intro/?cityid=201&from=app&nb=424cedb9af3046239aeae81c8b8b61f8";
#endif
    
    //seg control
    NSArray *items = @[@"UIWeb",@"WKWeb"];
    segControl = [[UISegmentedControl alloc]initWithItems:items];
    segControl.selectedSegmentIndex = 0;
    segControl.selected = YES;
    segControl.tintColor = [UIColor orangeColor];
    [segControl setFrame:CGRectMake((screenWidth - 200)/2, CGRectGetMaxY(inputTextView.frame) + 30, 200, 30)];
    [segControl addTarget:self action:@selector(segControlChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segControl];
    
    //button
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [nextButton setTitle:@"下一步" forState:UIControlStateNormal];
    [nextButton setBackgroundColor:[UIColor whiteColor]];
    [nextButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(nextButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [nextButton setFrame:CGRectMake((screenWidth - 200)/2, CGRectGetMaxY(segControl.frame) + 30, 200, 45)];
    [self.view addSubview:nextButton];
}

- (IBAction)nextButtonClicked:(id)sender;
{
    
    if (!inputTextView.text.length) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"url不能为空" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSString *urlStr = [inputTextView.text lowercaseString];
    if ([urlStr hasPrefix:@"http"]||[urlStr hasPrefix:@"https"]) {
        YXWebVC *webVC = [[YXWebVC alloc]init];
        webVC.url = [urlStr copy];
        webVC.isUIWeb = ((segControl.selectedSegmentIndex == 0)?YES:NO);
        [self.navigationController pushViewController:webVC animated:YES];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"url格式不正确" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
}
- (void)segControlChanged:(id)sender
{
    
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    /*
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:inputTextView.text]]];*/
    [self removeWebCache];
    
}
- (void)removeWebCache{
    if (iosVersion >= 9.0) {
//        NSSet *websiteDataTypes= [NSSet setWithArray:@[
//                                                       WKWebsiteDataTypeDiskCache,
//                                                       //WKWebsiteDataTypeOfflineWebApplication
//                                                       WKWebsiteDataTypeMemoryCache,
//                                                       //WKWebsiteDataTypeLocal
//                                                       WKWebsiteDataTypeCookies,
//                                                       //WKWebsiteDataTypeSessionStorage,
//                                                       //WKWebsiteDataTypeIndexedDBDatabases,
//                                                       //WKWebsiteDataTypeWebSQLDatabases
//                                                       ]];
        
        // All kinds of data
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            NSLog(@"ios9 wkwebsitedatasource delete datasource");
        }];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        
    } else {
        //先删除cookie
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            [storage deleteCookie:cookie];
        }
        NSError *error;
        
        NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary]
                                objectForKey:@"CFBundleIdentifier"];
        
        if (segControl.selectedSegmentIndex == 0) {
            //UIWebView生成的一些文件夹
            NSString *uiWebFolder = [NSString
                                     stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
            if ([[NSFileManager defaultManager] fileExistsAtPath:uiWebFolder]) {
                [[NSFileManager defaultManager]removeItemAtPath:uiWebFolder error:&error];
            }
        }
        else
        {
            //webkit生成的一些文件夹
            NSString *webkitFolder = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
            NSString *webKitCachePath1 = [NSString
                                          stringWithFormat:@"%@/Caches/%@",libraryDir,@"com.apple.WebKit.Networking"];
            NSString *webKitCachePath2 = [NSString
                                          stringWithFormat:@"%@/Caches/%@",libraryDir,@"com.apple.WebKit.WebContent"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:webkitFolder]) {
                [[NSFileManager defaultManager]removeItemAtPath:webkitFolder error:&error];
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:webKitCachePath1]) {
                [[NSFileManager defaultManager]removeItemAtPath:webKitCachePath1 error:&error];
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:webKitCachePath2]) {
                [[NSFileManager defaultManager]removeItemAtPath:webKitCachePath2 error:&error];
            }
        }
        
        //下面是两种web都会生成的一个文件夹
        NSString *webCachesPath = [NSString
                                            stringWithFormat:@"%@/Caches/%@",libraryDir,bundleId];
        if ([[NSFileManager defaultManager] fileExistsAtPath:webCachesPath]) {
            [[NSFileManager defaultManager]removeItemAtPath:webCachesPath error:&error];
        }
        
        //在使用UIWeb的时候 Cookies文件有文件，使用WebKit的时候Cookies中没有文件
        NSString *cookiesFolderPath = [libraryDir stringByAppendingString:@"/Cookies"];
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&error];
        
//        if (iosVersion > 8.f)
//        {
//            if ([[NSFileManager defaultManager] fileExistsAtPath:webkitFolderInLib]) {
//                [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
//            }
//            if ([[NSFileManager defaultManager] fileExistsAtPath:webKitFolderInCaches]) {
//                [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:nil];
//            }
//            if ([[NSFileManager defaultManager] fileExistsAtPath:webKitFolderInCachesfs]) {
//                [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCachesfs error:nil];
//            }
//            NSError *error;
//            if ([[NSFileManager defaultManager]fileExistsAtPath:webKitDBPath]) {
//                if ([[NSFileManager defaultManager] removeItemAtPath:webKitDBPath error:&error])
//                {
//                    NSLog(@"delete db success!!");
//                }
//            }
//        }
        /* iOS8.0 WebView Cache的存放路径
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
        iOS7.0 WebView Cache的存放路径
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCachesfs error:&error];*/
        NSLog(@"current memory:%ld,current disk:%ld",[[NSURLCache sharedURLCache] currentMemoryUsage],[[NSURLCache sharedURLCache]currentDiskUsage]);
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
}
#pragma mark - UITextView Delegate Methods

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView;
{
    return YES;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView;
{
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView;
{
    
}
- (void)textViewDidEndEditing:(UITextView *)textView;
{
    
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    return YES;
}
- (void)textViewDidChange:(UITextView *)textView;
{
    
}
- (void)textViewDidChangeSelection:(UITextView *)textView;
{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
