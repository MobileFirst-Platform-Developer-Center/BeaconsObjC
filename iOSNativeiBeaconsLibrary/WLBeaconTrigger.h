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

#import <Foundation/Foundation.h>

@interface WLBeaconTrigger : NSObject

typedef NS_ENUM(NSInteger, WLBeaconTriggerType) {
	WLBeaconTriggerTypeEnter,
	WLBeaconTriggerTypeExit,
	WLBeaconTriggerTypeDwellInside,
	WLBeaconTriggerTypeDwellOutside
};

typedef NS_ENUM(NSInteger, WLBeaconProximityState) {
	WLBeaconProximityStateImmediate,
	WLBeaconProximityStateNear,
	WLBeaconProximityStateFar,
	WLBeaconProximityStateUnknown
};

@property NSString *triggerName;
@property WLBeaconTriggerType triggerType;
@property WLBeaconProximityState proximityState;
@property NSNumber *dwellingTime;
@property NSDictionary *actionPayload;

-(id) initFromJson:(NSDictionary *)beaconTriggerDict;

-(NSString *) toString;

+(NSString *) beaconTriggerTypeToString:(WLBeaconTriggerType) beaconTriggerType;

+(NSString *) beaconProximityStateToString:(WLBeaconProximityState) beaconProximityState;

@end
