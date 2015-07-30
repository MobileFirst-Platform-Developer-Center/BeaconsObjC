/**
* Copyright 2015 IBM Corp.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
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
