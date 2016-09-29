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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.labelText.text = kTestSTring;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
