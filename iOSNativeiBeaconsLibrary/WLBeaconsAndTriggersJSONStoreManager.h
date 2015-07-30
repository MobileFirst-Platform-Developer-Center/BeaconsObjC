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
#import "WLBeacon.h"
#import "WLBeaconTrigger.h"
#import "WLBeaconTriggerAssociation.h"
#import <UIKit/UIKit.h>
#import <IBMMobileFirstPlatformFoundation/IBMMobileFirstPlatformFoundation.h>
@import CoreLocation;

typedef void (^LoadBeaconsAndTriggersCompletionHandler)(bool success, NSString* error);

@interface WLBeaconsAndTriggersJSONStoreManager : NSObject

+ (WLBeaconsAndTriggersJSONStoreManager *) sharedInstance;

- (void) loadBeaconsAndTriggersFromAdapter:(NSString *)adapterName withProcedure:(NSString *)procedureName withCompletionHandler:(LoadBeaconsAndTriggersCompletionHandler) completionHandler;

- (void) saveBeaconsAndTriggersIntoJSONStore:(NSDictionary *)responseDictionary;

- (NSArray *) getBeaconsFromJsonStore;
- (NSArray *) getBeaconTriggersFromJsonStore;
- (NSArray *) getBeaconTriggerAssociationsFromJsonStore;

- (NSSet *) getUuids;
- (NSArray *) getMatchingBeaconsWithUuid:(NSString *)uuid;
- (NSArray *) getMatchingBeaconsWithUuid:(NSString *)uuid andMajor:(NSNumber *)major;
- (WLBeacon *) getBeaconWithUuid:(NSString *)uuid andMajor:(NSNumber *)major andMinor:(NSNumber *)minor;
- (NSArray *) getTriggerAssociationsOfBeaconWithUuid:(NSString *)uuid andMajor:(NSNumber *)major andMinor:(NSNumber *)minor;
- (WLBeaconTrigger *) getBeaconTriggerWithName:(NSString *)triggerName;

- (void) addToMonitoredRegions:(CLBeaconRegion *)regionIdentifier;
- (void) removeFromMonitoredRegions:(CLBeaconRegion *)regionIdentifier;
- (NSArray *) getMonitoredRegions;
- (void) resetMonitoredRegions;

- (void) setLastSeenProximity:(CLProximity)proximity forBeaconWithUuid:(NSString *)uuid andMajor:(NSNumber *)major andMinor:(NSNumber *)minor;
- (CLProximity) getLastSeenProximityForBeaconWithUuid:(NSString *)uuid andMajor:(NSNumber *)major andMinor:(NSNumber *)minor;
- (CLProximity) getLastSeenProximityOfBeacon:(WLBeacon *)beacon;

- (void) setTimeOfLastTriggerFire:(int)timeInterval triggerName:(NSString *)triggerName uuid:(NSString *)uuid major:(NSNumber *)major minor:(NSNumber *)minor;

@end
