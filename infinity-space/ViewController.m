//
//  ViewController.m
//  infinity-space
//
//  Created by niyao on 8/24/18.
//  Copyright © 2018 dourui. All rights reserved.
//

#import "ViewController.h"
#import "WebSocketManager.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, WebSocketManagerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray <NSDictionary *> *messages;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    ConsoleLog(@"test");
    WebSocketConfiguration *configuration = [[WebSocketConfiguration alloc] init];
    configuration.hostUrl = @"ws://10.1.3.43:23333";
    [WebSocketManager setup:configuration];
    [WebSocketManager start];
    
    [WebSocketManager shared].delegate = self;
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyboard)];
    [self.view addGestureRecognizer:tap];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.messages = [NSMutableArray array];
    
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

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSDictionary *message = self.messages[indexPath.item];
    cell.textLabel.text = message[@"content"];
    
    return cell;
}

#pragma mark - WebSocketManagerDelegate
- (void)webSocketDidReceiveMessage:(NSString *)message {
    NSError *jsonError;
    NSData *msgData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *msg = [NSJSONSerialization JSONObjectWithData:msgData options:NSJSONReadingMutableContainers error:&jsonError];
    
    if (!jsonError) {
        [self.messages addObject:msg];
        [self.tableView reloadData];
    } else {
        ConsoleLog(@"%@", jsonError.localizedDescription);
    }
}
@end
