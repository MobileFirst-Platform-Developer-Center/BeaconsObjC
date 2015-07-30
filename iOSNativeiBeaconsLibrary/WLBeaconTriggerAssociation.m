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
#import "WLBeaconTriggerAssociation.h"

@implementation WLBeaconTriggerAssociation

-(id) initFromJson:(NSDictionary *)beaconTriggerAssociationDict {
	self = [super init];
	if (self) {
		self.uuid = [beaconTriggerAssociationDict objectForKey:@"uuid"];
		self.major = [beaconTriggerAssociationDict objectForKey:@"major"];
		self.minor = [beaconTriggerAssociationDict objectForKey:@"minor"];
		self.triggerName = [beaconTriggerAssociationDict objectForKey:@"triggerName"];
		NSNumber * t = [beaconTriggerAssociationDict objectForKey:@"timeOfLastTriggerFire"];
		if (t != nil) {
			self.timeOfLastTriggerFire = t.intValue;
		} else {
			self.timeOfLastTriggerFire = 0;
		}
	}
	return self;
}

-(NSString *) toString {
	return [NSString stringWithFormat:@"UUID: %@, major: %@, minor: %@, triggerName: %@", self.uuid, self.major, self.minor, self.triggerName, nil];
}

@end
