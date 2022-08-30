/*******************************************************************************
 * Copyright (c) 2014, 2016  IBM Corporation, Carnegie Mellon University and others
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *******************************************************************************/


#import "AgreementViewController.h"
#import "NavDataStore.h"
#import "ServerConfig.h"

@interface AgreementViewController ()

@end

@implementation AgreementViewController {
    int count; // temporary
    WKWebView *webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[[WKWebViewConfiguration alloc] init]];
    [self.view addSubview:webView];

    [webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint* topAnchor = [webView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0];
    NSLayoutConstraint* leftAnchor = [webView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:0];
    NSLayoutConstraint* rightAnchor = [webView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:0];
    NSLayoutConstraint* bottomAnchor = [webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0];
    [self.view addConstraint:topAnchor];
    [self.view addConstraint:leftAnchor];
    [self.view addConstraint:rightAnchor];
    [self.view addConstraint:bottomAnchor];

    webView.navigationDelegate = self;
    webView.UIDelegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (count++ == 0) {
        NSString *device_id = [[UIDevice currentDevice].identifierForVendor UUIDString];
        NSURL *url = [[ServerConfig sharedConfig].selected agreementURLWithIdentifier:device_id];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        request.timeoutInterval = 30;
        [webView loadRequest:request];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    // TODO: arrow only our content
    NSURL *url = [NSURL URLWithString:[[[webView URL] standardizedURL] absoluteString]];
    if ([[url path] hasSuffix:@"/finish_agreement.jsp"]) { // check if finish page is tryed to be loaded
        NSString *identifier = [[NavDataStore sharedDataStore] userID];
        [[ServerConfig sharedConfig] checkAgreementForIdentifier:identifier withCompletion:^(NSDictionary* config) {
            BOOL agreed = [config[@"agreed"] boolValue];
            if (agreed) {
                [self performSegueWithIdentifier:@"unwind_agreement" sender:self];
            } else {
                [[ServerConfig sharedConfig] clear];
                [self performSegueWithIdentifier:@"unwind_agreement" sender:self];
            }
        }];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.waitIndicator.hidden = NO;
        [self.waitIndicator startAnimating];
    });
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.waitIndicator.hidden = YES;
        [self.waitIndicator stopAnimating];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
