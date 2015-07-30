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

#import "WLBeacon.h"

@implementation WLBeacon

-(id) initFromJson:(NSDictionary *)beaconDict {
	self = [super init];
	if (self) {
		self.uuid = [beaconDict objectForKey:@"uuid"];
		self.major = [beaconDict objectForKey:@"major"];
		self.minor = [beaconDict objectForKey:@"minor"];
		self.latitude = [beaconDict objectForKey:@"latitude"];
		self.longitude = [beaconDict objectForKey:@"longitude"];
		self.customData = [beaconDict objectForKey:@"customData"];
		NSString *proximity = [beaconDict objectForKey:@"lastSeenProximity"];
		if (proximity) {
			self.lastSeenProximity = proximity;
		} else {
			self.lastSeenProximity = [WLBeacon CLProximityToString:CLProximityUnknown];
		}
	}
	return self;
}

-(NSString *) toString {
	NSMutableString *text = [[NSMutableString alloc] init];
	[text appendFormat:@"UUID: %@, major: %@, minor: %@", self.uuid, self.major, self.minor, nil];
	if (self.latitude != nil) {
		[text appendFormat:@", latitude: %@", self.latitude, nil];
	}
	if (self.longitude != nil) {
		[text appendFormat:@", longitude: %@", self.longitude, nil];
	}
	if (self.customData != nil) {
		for (NSString *key in self.customData.allKeys) {
			NSString *value = [self.customData objectForKey:key];
			[text appendFormat:@", %@: '%@'", key, value, nil];
		}
	}
	if (self.lastSeenProximity != nil) {
		[text appendFormat:@", lastSeenProximity: %@", self.lastSeenProximity, nil];
	}
	return text;
}

+(NSString *) CLProximityToString: (CLProximity) clProximity
{
	NSString *string = nil;
	switch(clProximity) {
		case CLProximityUnknown:
			string = @"Unknown";
			break;
		case CLProximityImmediate:
			string = @"Immediate";
			break;
		case CLProximityNear:
			string = @"Near";
			break;
		case CLProximityFar:
			string = @"Far";
			break;
	}
	return string;
}

+(NSDictionary *) getCLProximityStrings {
	return @{@"Unknown": @(CLProximityUnknown),
			 @"Immediate": @(CLProximityImmediate),
			 @"Near" : @(CLProximityNear),
			 @"Far": @(CLProximityFar)};
}

+(CLProximity) StringToCLProximity: (NSString *) clProximityString
{
	NSDictionary * proximityStrings = [WLBeacon getCLProximityStrings];
	return (CLProximity)[[proximityStrings objectForKey:clProximityString]intValue];
}

@end
