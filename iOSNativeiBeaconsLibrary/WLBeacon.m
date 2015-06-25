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
