#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)exceptionAction:(UIButton *)sender {
    NSArray *arr = @[@1, @2 ,@3];
    NSLog(@"%@", [arr objectAtIndex:4]);
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.view.backgroundColor = [UIColor redColor];
}

@end
