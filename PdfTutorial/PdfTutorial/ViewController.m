//
//  ViewController.m
//  PdfTutorial
//
//  Created by Sasidhar Koti on 03/03/16.
//  Copyright © 2016 Sasidhar Koti. All rights reserved.
//

#import "ViewController.h"
#import "DrawingLayer.h"

@interface ViewController ()

// IBOutLet of the webview.
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic)  DrawingLayer *drawingLayer;
@property (weak, nonatomic) IBOutlet UIView *drawingView;

@property (weak, nonatomic) IBOutlet UIButton *editBtn;
@property (weak, nonatomic) IBOutlet UIButton *saveBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _drawingView.hidden = YES;
    // Do any additional setup after loading the view, typically from a nib.
    
    // 1) get the file path
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"pdf"];
    // 2) convert nstring to nsurl (getting the filepath).
    NSURL *targetURL = [NSURL fileURLWithPath:path];
    // 3)convert nsurl to nsurlrequest
    NSURLRequest *request = [NSURLRequest requestWithURL:targetURL];
    
    // 4) load the webview request
    [_webView loadRequest:request];
    
    [_webView setScalesPageToFit:NO];
    
    
    self.drawingLayer = [[DrawingLayer alloc] initWithFrame:CGRectMake(0, 0, self.drawingView.frame.size.width, self.drawingView.frame.size.height)];
    [self.drawingView addSubview:self.drawingLayer];
    self.drawingView.hidden = YES;
    
}

- (IBAction)editAction:(id)sender {
    [self.webView.scrollView setZoomScale:1];
    
    self.drawingView.hidden = NO;
    _webView.scrollView.scrollEnabled = NO;
    _webView.scrollView.bounces = NO;
    self.drawingLayer.isErasing = NO;
}

- (IBAction)saveAction:(id)sender {
    [self drawPDF];
    _webView.scrollView.scrollEnabled = YES;
    _webView.scrollView.bounces = YES;
    
    self.drawingLayer.isErasing = NO;
    self.drawingView.hidden = YES;
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
                              @"saved" message:@"pdf saved successfully" delegate:nil
                                             cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alertView show];
}

- (IBAction)erase:(id)sender {
    _webView.scrollView.scrollEnabled = YES;
    _webView.scrollView.bounces = YES;
    
    self.drawingLayer.isErasing = YES;
}



- (void)drawPDF
{
    CGFloat verticalContentOffset = self.webView.scrollView.contentOffset.y;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"pdf"];
  
    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData(pdfData, self.webView.scrollView.bounds, nil);
    

    //path of the pdf resource
    CFURLRef url = CFURLCreateWithFileSystemPath (NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, 0);
    
    //open template file
    //the data type CGPDFDocumentRef to represent a PDF document
    
    CGPDFDocumentRef templateDocument = CGPDFDocumentCreateWithURL(url);
    CFRelease(url);
    
    //count the number pages in document
    size_t count = CGPDFDocumentGetNumberOfPages(templateDocument);
    CGFloat pageHeight = self.webView.scrollView.contentSize.height / count;
    CGFloat drawingViewY = fmod(verticalContentOffset, pageHeight);
    CGPDFPageRef templatePage;
    if (count) {
        
        //iterate over all page, to create each page with annoations
        for (size_t pageNumber = 1; pageNumber <= count; pageNumber++) {
            
            //Gets the page for the specified page number from the PDF document.
            templatePage = CGPDFDocumentGetPage(templateDocument, pageNumber);
            CGRect templatePageBounds = CGPDFPageGetBoxRect(templatePage, kCGPDFMediaBox);
            CGFloat scale = templatePageBounds.size.width/self.drawingView.bounds.size.width;
            UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, self.drawingView.bounds.size.width, pageHeight), nil);
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGContextScaleCTM(context, 1/scale, 1/scale);
            CGContextTranslateCTM(context, 0.0, templatePageBounds.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            
            //drawing open page of pdf
            CGContextDrawPDFPage(context, templatePage);
            
            CGContextTranslateCTM(context, 0.0, templatePageBounds.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextScaleCTM(context, scale, scale);

            //converting uiview on top of webview into image and drawing it to pdf.
            if (verticalContentOffset >= (pageNumber - 1)*pageHeight && verticalContentOffset <= pageNumber*pageHeight) {
                CGRect visibleRect;
                visibleRect.origin = CGPointMake(0, drawingViewY);
                visibleRect.size = self.drawingView.bounds.size;
                
                UIImage *image = [self renderView:self.drawingView WithBounds:self.drawingView.bounds];
                CGContextDrawImage(UIGraphicsGetCurrentContext(), visibleRect, image.CGImage);
            }
            if (verticalContentOffset+self.drawingView.bounds.size.height > (pageNumber - 1)*pageHeight && self.drawingView.bounds.size.height + verticalContentOffset <= pageNumber*pageHeight) {
                
                CGRect visibleRect;
                CGFloat y = drawingViewY - pageHeight;
                visibleRect.origin = CGPointMake(0, y);
                visibleRect.size = self.drawingView.bounds.size;
                
                UIImage *image = [self renderView:self.drawingView WithBounds:self.drawingView.bounds];
                CGContextDrawImage(UIGraphicsGetCurrentContext(), visibleRect, image.CGImage);
            }
        }
    }
    CGPDFDocumentRelease(templateDocument);
    UIGraphicsEndPDFContext();
    
    [self savePDFDataTofile:pdfData];
}


- (UIImage *) renderView:(UIView *)view WithBounds:(CGRect)frame {
    
    CGSize imageSize = frame.size;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGAffineTransform verticalFlip = CGAffineTransformMake(1, 0, 0, -1, 0, frame.size.height);
    CGContextConcatCTM(c, verticalFlip);
    [view.layer renderInContext:c];
    
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [UIImage imageWithCGImage: screenshot.CGImage scale:-1.0f orientation: UIImageOrientationLeftMirrored];
}

- (void)savePDFDataTofile:(NSData*)data
{
    if(data) {
        NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory=[paths objectAtIndex:0];
        
        NSString *finalPath=[documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat: @"myFile.pdf"]];
        //in can open the path and see the update pdf file.. or you can open the edited pdf file in uiwebview.
        NSLog(@"finalpath--%@",finalPath);
        [data  writeToFile:finalPath atomically:YES];
        
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
