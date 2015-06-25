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
#import "WLBeaconTrigger.h"

@implementation WLBeaconTrigger

-(NSDictionary *) getBeaconTriggerTypeNames {
	return @{@"Enter": @(WLBeaconTriggerTypeEnter),
	  @"Exit": @(WLBeaconTriggerTypeExit),
	  @"DwellInside" : @(WLBeaconTriggerTypeDwellInside),
	  @"DwellOutside": @(WLBeaconTriggerTypeDwellOutside)};
}

+(NSString *) beaconTriggerTypeToString:(WLBeaconTriggerType) beaconTriggerType {
	NSString *string = nil;
	switch(beaconTriggerType) {
		case WLBeaconTriggerTypeEnter:
			string = @"Enter";
			break;
		case WLBeaconTriggerTypeExit:
			string = @"Exit";
			break;
		case WLBeaconTriggerTypeDwellInside:
			string = @"DwellInside";
			break;
		case WLBeaconTriggerTypeDwellOutside:
			string = @"DwellOutside";
			break;
	}
	return string;
}

-(WLBeaconTriggerType) BeaconTriggerTypeFromString:(NSString *)triggerTypeString {
	NSDictionary * beaconTriggerTypeNames = [self getBeaconTriggerTypeNames];
	return (WLBeaconTriggerType)[[beaconTriggerTypeNames objectForKey:triggerTypeString]intValue];
}

-(NSDictionary *) getBeaconProximityStateNames {
	return @{@"Immediate": @(WLBeaconProximityStateImmediate),
			 @"Near": @(WLBeaconProximityStateNear),
			 @"Far" : @(WLBeaconProximityStateFar),
			 @"Unknown": @(WLBeaconProximityStateUnknown)};
}

+(NSString *) beaconProximityStateToString:(WLBeaconProximityState) beaconProximityState {
	NSString *string = nil;
	switch(beaconProximityState) {
		case WLBeaconProximityStateImmediate:
			string = @"Immediate";
			break;
		case WLBeaconProximityStateNear:
			string = @"Near";
			break;
		case WLBeaconProximityStateFar:
			string = @"Far";
			break;
		case WLBeaconProximityStateUnknown:
			string = @"Unknown";
			break;
	}
	return string;
}

-(WLBeaconProximityState) BeaconProximityStateFromString:(NSString *)proximityStateString {
	NSDictionary * beaconProximityStateNames = [self getBeaconProximityStateNames];
	return (WLBeaconProximityState)[[beaconProximityStateNames objectForKey:proximityStateString]intValue];
}

-(id) initFromJson:(NSDictionary *)beaconTriggerDict {
	self = [super init];
	if (self) {
		self.triggerName = [beaconTriggerDict objectForKey:@"triggerName"];
		self.triggerType = [self BeaconTriggerTypeFromString:[beaconTriggerDict objectForKey:@"triggerType"]];
		self.proximityState = [self BeaconProximityStateFromString:[beaconTriggerDict objectForKey:@"proximityState"]];
		self.dwellingTime = [beaconTriggerDict objectForKey:@"dwellingTime"];
		self.actionPayload = [beaconTriggerDict objectForKey:@"actionPayload"];
	}
	return self;
}

-(NSString *) toString {
	NSString * triggerTypeString = [WLBeaconTrigger beaconTriggerTypeToString:self.triggerType];
	NSString * proximityStateString = [WLBeaconTrigger beaconProximityStateToString:self.proximityState];
	NSMutableString *text = [[NSMutableString alloc] init];
	[text appendFormat:@"triggerName: %@, triggerType: %@, proximityState: %@", self.triggerName, triggerTypeString, proximityStateString, nil];
	if (self.dwellingTime != nil) {
		[text appendFormat:@", dwellingTime %@", self.dwellingTime, nil];
	}
	if (self.actionPayload != nil) {
		for (NSString *key in self.actionPayload.allKeys) {
			NSString *value = [self.actionPayload objectForKey:key];
			[text appendFormat:@", %@: '%@'", key, value, nil];
		}
	}
	return text;
}

@end
