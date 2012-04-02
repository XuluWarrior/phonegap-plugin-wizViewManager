/* WizWebView - Creates Instance of wizard UIWebView.
 *
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2011
 * @file WizWebView.m for PhoneGap
 *
 */ 

#import "WizWebView.h"
#import "WizDebugLog.h"
#import "WizViewManagerPlugin.h"


@implementation WizWebView

@synthesize wizView;

static PGPlugin* viewManager;
static BOOL isActive = FALSE;

-(UIWebView *)createNewInstanceView:(PGPlugin*)myViewManager newBounds:(CGRect)webViewBounds sourceToLoad:(NSString*)src 
{
    
    viewManager = myViewManager;
    
    wizView = [UIWebView new];
    [wizView scalesPageToFit];
    wizView.delegate = self;
    wizView.multipleTouchEnabled   = YES;
    wizView.autoresizesSubviews    = YES;
    wizView.hidden                 = NO;
    wizView.userInteractionEnabled = YES;
    wizView.opaque = NO;
    
    WizLog(@"[WizWebView] ******* building new view. src : %@", src);
    
    // load source from URI for example
    // /Users/WizardBookPro/Library/Application Support/iPhone Simulator/4.3.2/Applications/14013381-4491-42B9-8A72-30223350C81C/myApp.app/www/test2_index.html
    
    
    NSURL *candidateURL = [NSURL URLWithString:src];
    if (candidateURL && candidateURL.scheme && candidateURL.host) {
        // candidate is a well-formed url with:
        //  - a scheme (like http://)
        //  - a host (like stackoverflow.com)
        
        WizLog(@"[WizViewManager] ******* building with URL");
        [wizView loadRequest:[NSURLRequest requestWithURL:candidateURL]];
        
        
    } else {
        
        WizLog(@"[WizViewManager] ******* building with local file");
        
        NSString *fileString = src;
        
        NSString *newHTMLString = [[NSString alloc] initWithContentsOfFile: fileString encoding: NSUTF8StringEncoding error: NULL];
        
        NSURL *newURL = [[NSURL alloc] initFileURLWithPath: fileString];
        
        [wizView loadHTMLString: newHTMLString baseURL: newURL];
        
        [newHTMLString release];
        [newURL release];
    }

    
    wizView.bounds = webViewBounds;
    
    [wizView setFrame:CGRectMake(
                                 webViewBounds.origin.x,
                                 webViewBounds.origin.y,
                                 webViewBounds.size.width,
                                 webViewBounds.size.height
                                 )];
    
    // add this view as subview after creating instance in parent class.
    return wizView;
}

+ (BOOL) isActive
{
    return isActive;
}


- (void)webViewDidFinishLoad:(UIWebView *)theWebView 
{
	// view is loaded
    WizLog(@"[WizWebView] ******* view is LOADED! " );
    
    isActive = TRUE;
    
    // to send data straght to mainView onLoaded via phonegap callback
     
    NSMutableDictionary * callbackDict = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViewLoadedCallbackId]];
    
    WizLog(@"[WizViewManager] ******* viewLoadedCallbackId : %@ ", callbackDict); 
    NSString* callbackId = [callbackDict objectForKey:@"viewLoadedCallback"];
    
   
    PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK];
    [viewManager writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];

    
    [callbackDict release];
    
    /*
    // to send data straght to mainView onLoaded
     
     
    NSMutableDictionary * viewList = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViews]];
    UIWebView* targetWebView = [viewList objectForKey:@"mainView"]; 
    WizLog(@"[WizWebView] ******* targetWebView... %@", targetWebView);
    [targetWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"wizMessageReceiver('%@');", myName]];
     
    */
   
}



- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSMutableURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType 
{
    
    NSString *requestString = [[request URL] absoluteString];
    // get prefix
    NSArray* prefixer = [requestString componentsSeparatedByString:@":"];
    // WizLog(@"[WizWebView] ******* prefixer is:  %@", prefixer );
    
    // example request string
    // wizMessageView://mainView/{here is our data stringified}
    
    // do insensitive compare to support SDK >5
    if ([(NSString*)[prefixer objectAtIndex:0] caseInsensitiveCompare:@"wizMessageView"] == 0) {
        
        NSArray* components = [requestString componentsSeparatedByString:@"://"];
        NSString* messageData = (NSString*)[components objectAtIndex:1];
                
        NSRange range = [messageData rangeOfString:@"?"];
        
        NSString* targetView = [messageData substringToIndex:range.location];
        
        WizLog(@"[WizWebView] ******* targetView is:  %@", targetView );
        
        int targetLength = targetView.length;
        
        NSString* postData = [messageData substringFromIndex:targetLength+1];
        
        // WizLog(@"[WizWebView] ******* postData is:  %@", postData );

        NSMutableDictionary * viewList = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViews]];
        
        // WizLog(@"[WizWebView] ******* current views... %@", viewList);

        
        if ([viewList objectForKey:targetView]) {
            UIWebView* targetWebView = [viewList objectForKey:targetView]; 
            NSString *postDataEscaped = [postData stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
            [targetWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"wizMessageReceiver('%@');", postDataEscaped]];
        }
        
        // TODO: error handle
        // no error handle,...

        [viewList release];
        
        return NO;
        
	}
    
    // Accept any other URLs
	return YES;
}

@end