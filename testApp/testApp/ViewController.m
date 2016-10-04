//
//  ViewController.m
//  testApp
//
//  Created by Jaroslav O on 22/08/16.
//  Copyright © 2016 j. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong) IBOutlet UILabel *labelText;
@property (strong) IBOutlet UILabel *labelVersion;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.labelText.text = kTestSTring;
 
    
    // Show app version
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
    self.labelVersion.text = [NSString stringWithFormat:@"%@ (%@)", appVersion, build];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
