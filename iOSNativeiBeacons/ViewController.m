/*
 *
 COPYRIGHT LICENSE: This information contains sample code provided in source code form. You may copy, modify, and distribute
 these sample programs in any form without payment to IBM® for the purposes of developing, using, marketing or distributing
 application programs conforming to the application programming interface for the operating platform for which the sample code is written.
 Notwithstanding anything to the contrary, IBM PROVIDES THE SAMPLE SOURCE CODE ON AN "AS IS" BASIS AND IBM DISCLAIMS ALL WARRANTIES,
 EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OR CONDITIONS OF MERCHANTABILITY, SATISFACTORY QUALITY,
 FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND ANY WARRANTY OR CONDITION OF NON-INFRINGEMENT. IBM SHALL NOT BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR OPERATION OF THE SAMPLE SOURCE CODE.
 IBM HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS OR MODIFICATIONS TO THE SAMPLE SOURCE CODE.
 
 */

#import "ViewController.h"

#import "WLBeaconsAndTriggersJSONStoreManager.h"
#import "WLBeaconsLocationManager.h"

#import "WLBeacon.h"
#import "WLBeaconTrigger.h"
#import "WLBeaconTriggerAssociation.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *turnIntoiBeaconButton;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	[self updateView:@""];

	[[WLBeaconsLocationManager sharedInstance] requestPermissionToUseLocationServices];
	[[WLBeaconsLocationManager sharedInstance] requestPermissionToUseNotifications];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (IBAction)doLoadBeaconsAndTriggers:(UIButton *)sender {
	[self updateView:@"Invoking loadBeaconsAndTriggersFromAdapter ..."];
	[[WLBeaconsAndTriggersJSONStoreManager sharedInstance] loadBeaconsAndTriggersFromAdapter:@"BeaconsAdapter" withProcedure:@"getBeaconsAndTriggers" withCompletionHandler:^(bool success, NSString *error) {
		if (success) {
			[self showBeaconsAndTriggers];
		} else {
			[self updateView:error];
		}
	}];
}

- (IBAction)doShowBeaconsAndTriggers:(UIButton *)sender {
	[self showBeaconsAndTriggers];
}

- (IBAction)doStartRanging:(UIButton *)sender {
	NSLog(@"StartRanging called.");
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Start Ranging" message:@"We will now start ranging for beacons." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
	[alert show];
	
	// Start ranging
	[[WLBeaconsLocationManager sharedInstance] startRangingWithStatusHandler:^(NSString *beaconDetails) {
		[self updateView:beaconDetails];
	}];
}

- (IBAction)doStopRanging:(UIButton *)sender {
	NSLog(@"StopRanging called.");
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stop Ranging" message:@"We will now stop ranging for beacons." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
	[alert show];
	
	// Stop ranging
	[[WLBeaconsLocationManager sharedInstance] stopRanging];
}

- (IBAction)doStartMonitoring:(UIButton *)sender {
	NSLog(@"StartMonitoring called.");
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Start Monitoring" message:@"We will now start monitoring for relevant beacons." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
	[alert show];
	
	// Start monitoring
	[[WLBeaconsLocationManager sharedInstance] startMonitoring];
}

- (IBAction)doStopMonitoring:(UIButton *)sender {
	NSLog(@"StopMonitoring called.");
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stop Monitoring" message:@"We will now stop monitoring for relevant beacons." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
	[alert show];
	
	// Stop monitoring
	[[WLBeaconsLocationManager sharedInstance] stopMonitoring];
	// Optionally reset monioring/ranging state
	[[WLBeaconsLocationManager sharedInstance] resetMonitoringRangingState];
}

- (IBAction)doTurnIntoiBeacon:(UIButton *)sender {
	// NSString *uuidString = @"2D3B31FA-3C4B-4A06-9B18-38057AA0964B";
	NSString *uuidString = @"8deefbb9-f738-4297-8040-96668bb44281";
	int major = 1;
	int minor = 4417;
	[[WLBeaconsLocationManager sharedInstance] turnIntoiBeaconWithUuid:uuidString withMajor:major withMinor:minor withStatusHandler:^(NSString *turnIntoiBeaconStatusDetails) {
		[self updateView:turnIntoiBeaconStatusDetails];
	}];
}

- (void)updateView:(NSString *)response
{
	[self.textView setText:response];
}

- (void)showBeaconsAndTriggers
{
	WLBeaconsAndTriggersJSONStoreManager *wlBeaconsAndTriggersJSONStoreManager = [WLBeaconsAndTriggersJSONStoreManager sharedInstance];
	NSArray *beacons = [wlBeaconsAndTriggersJSONStoreManager getBeaconsFromJsonStore];
	NSArray *beaconTriggers = [wlBeaconsAndTriggersJSONStoreManager getBeaconTriggersFromJsonStore];
	NSArray *beaconTriggerAssociations = [wlBeaconsAndTriggersJSONStoreManager getBeaconTriggerAssociationsFromJsonStore];
	
	NSMutableString * text = [[NSMutableString alloc] init];
	[text appendString:@"Beacons:\n"];
	for (int i=0; i < beacons.count; i++) {
		WLBeacon *beacon = beacons[i];
		[text appendFormat:@"%d) %@\n\n", (i + 1), [beacon toString], nil];
	}
	[text appendString:@"\nBeaconTriggers:\n"];
	for (int i=0; i < beaconTriggers.count; i++) {
		WLBeaconTrigger *beaconTrigger = beaconTriggers[i];
		[text appendFormat:@"%d) %@\n\n", (i + 1), [beaconTrigger toString], nil];
	}
	[text appendString:@"\nBeaconTriggerAssociations:\n"];
	for (int i=0; i < beaconTriggerAssociations.count; i++) {
		WLBeaconTriggerAssociation *beaconTriggerAssociation = beaconTriggerAssociations[i];
		[text appendFormat:@"%d) %@\n\n", (i + 1), [beaconTriggerAssociation toString], nil];
	}
	[self updateView:text];
}

@end
