//
//  ViewController.m
//  infinity-space
//
//  Created by niyao on 8/24/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import "ViewController.h"
#import "WebSocketManager.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    ConsoleLog(@"test");
    WebSocketConfiguration *configuration = [[WebSocketConfiguration alloc] init];
    configuration.hostUrl = @"ws://192.168.1.106:23333";
    [WebSocketManager setup:configuration];
    [WebSocketManager start];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)resignKeyboard {
    [self.view endEditing:YES];
}
- (IBAction)reconnect:(id)sender {
    [WebSocketManager.shared reconnect];
}

- (IBAction)close:(id)sender {
    [WebSocketManager.shared close];
}

- (IBAction)sendMessage:(id)sender {
    [self resignKeyboard];
    if (self.messageTextField.text.length > 0 && self.nicknameTextField.text.length > 0) {
        NSDictionary *messageDic = @{
                              @"content": self.messageTextField.text,
                              @"nickname":self.nicknameTextField.text
                              };
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject: messageDic
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"JSON Output: %@", jsonString);
        
        [WebSocketManager.shared send:jsonString];
        self.messageTextField.text = @"";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
