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
