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
#import "WLBeaconsLocationManager.h"
#import "WLBeaconsAndTriggersJSONStoreManager.h"
@import CoreLocation;
@import CoreBluetooth;
#import <IBMMobileFirstPlatformFoundation/IBMMobileFirstPlatformFoundation.h>


@interface WLBeaconsLocationManager () <CLLocationManagerDelegate, CBPeripheralManagerDelegate> {
@private
	WLBeaconsStatusHandler rangingStatusHandler;
	WLBeaconsStatusHandler turnIntoiBeaconStatusHandler;
}

@property CLLocationManager *locationManager;
@property NSTimeInterval minTimeGapInSecsBetweenConsecutiveTriggerActions;

@property UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property Boolean appRunningInBackground;

@property CLBeaconRegion *beaconDataToEmit;
@property CBPeripheralManager *peripheralManager;

@end

@implementation WLBeaconsLocationManager

static WLBeaconsLocationManager* sharedInstance = nil;

+(WLBeaconsLocationManager *) sharedInstance
{
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [[self alloc] init];
		}
		return sharedInstance;
	}
}

-(id) init
{
	self = [super init];
	if (self) {
		self.locationManager = [[CLLocationManager alloc] init];
		self.locationManager.delegate = self;
		self.minTimeGapInSecsBetweenConsecutiveTriggerActions = 0; // ToDo load from JSONStore

		self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
		self.appRunningInBackground = YES; // this is initially set to YES so that extendBackgroundRunningTime is called at least once from within locationManager:didDetermineState:forRegion

		self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
	}
	return self;
}

-(void) requestPermissionToUseLocationServices
{
	if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
		[self.locationManager requestAlwaysAuthorization];
	}
}

-(void) requestPermissionToUseNotifications
{
	UIApplication *application = [UIApplication sharedApplication];
	if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
		UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
		UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
		[application registerUserNotificationSettings:notificationSettings];
	}
}

-(void) setMinTimeGapBetweenConsecutiveTriggerActions:(NSTimeInterval)minTimeGapInSecs {
	// ToDo store in JSONStore
	self.minTimeGapInSecsBetweenConsecutiveTriggerActions = minTimeGapInSecs;
}

-(void) startMonitoring
{
	[self stopMonitoring];
	NSSet *uuids = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getUuids];
	for (NSString *uuidString in uuids) {
		NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
		CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:uuidString];
		region.notifyEntryStateOnDisplay = YES;
		[self startMonitoringForRegion:region];
	}
}

-(void) startMonitoringForRegion:(CLBeaconRegion *)region
{
	[self.locationManager startMonitoringForRegion:region];
	[[WLBeaconsAndTriggersJSONStoreManager sharedInstance] addToMonitoredRegions:region];
}

-(void) stopMonitoring
{
	[self stopRanging];
	NSArray *monitoredRegions = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getMonitoredRegions];
	for (CLBeaconRegion *monitoredRegion in monitoredRegions) {
		[self stopMonitoringForRegion:monitoredRegion];
	}
}

-(void) stopMonitoringForRegion:(CLBeaconRegion *)monitoredRegion
{
	[self.locationManager stopMonitoringForRegion:monitoredRegion];
	[[WLBeaconsAndTriggersJSONStoreManager sharedInstance] removeFromMonitoredRegions:monitoredRegion];
}

-(void) startRangingWithStatusHandler:(WLBeaconsStatusHandler) statusHandler
{
	rangingStatusHandler = statusHandler;
	NSSet *uuids = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getUuids];
	for (NSString *uuidString in uuids) {
		NSUUID *uuid = [self createUuidFromString:uuidString];
		CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:uuidString];
		[self.locationManager startRangingBeaconsInRegion:region];
	}
}

-(void) stopRanging
{
	NSSet *uuids = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getUuids];
	for (NSString *uuidString in uuids) {
		NSUUID *uuid = [self createUuidFromString:uuidString];
		CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:uuidString];
		[self.locationManager stopRangingBeaconsInRegion:region];
	}
}

-(void) resetMonitoringRangingState
{
	WLBeaconsAndTriggersJSONStoreManager *wlBeaconsAndTriggersJSONStoreManager = [WLBeaconsAndTriggersJSONStoreManager sharedInstance];
	NSArray *wlBeacons = [wlBeaconsAndTriggersJSONStoreManager getBeaconsFromJsonStore];
	for (WLBeacon *wlBeacon in wlBeacons) {
		[wlBeaconsAndTriggersJSONStoreManager setLastSeenProximity:CLProximityUnknown forBeaconWithUuid:wlBeacon.uuid andMajor:wlBeacon.major andMinor:wlBeacon.minor];
		NSArray *associations =	[wlBeaconsAndTriggersJSONStoreManager getTriggerAssociationsOfBeaconWithUuid:wlBeacon.uuid andMajor:wlBeacon.major andMinor:wlBeacon.minor];
		for (WLBeaconTriggerAssociation *association in associations) {
			[wlBeaconsAndTriggersJSONStoreManager setTimeOfLastTriggerFire:0 triggerName:association.triggerName uuid:association.uuid major:association.major minor:association.minor];
		}
	}
}

#pragma mark - Location manager delegate

-(void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
	[self.locationManager requestStateForRegion:region];
}

-(void) locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
	if (state == CLRegionStateInside) {
		if (self.appRunningInBackground) {
			[self extendBackgroundRunningTime];
		}
		NSArray *monitoredRegions = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getMonitoredRegions];
		if (monitoredRegions.count > 0) {
			[self startRangingWithStatusHandler:^(NSString *beaconDetails) {}];
		}
	}
}

-(void) locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
	NSLog(@"didEnterRegion() called.");
	
	// Start ranging so as to get the major number of beacons within range. This is to know the branch/store that the user has entered.
	[self startRangingWithStatusHandler:^(NSString *beaconDetails) {}];
}

-(void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
	NSLog(@"didExitRegion() called.");
	CLBeaconRegion *beaconRegion = (CLBeaconRegion *) region;
	NSString *uuidString = [self getUuidStringOfBeaconRegion:beaconRegion];
	if (beaconRegion.major != nil && beaconRegion.minor != nil) {
		WLBeacon *wlBeacon = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getBeaconWithUuid:uuidString andMajor:beaconRegion.major andMinor:beaconRegion.minor];
		if (wlBeacon != nil) {
			[self processExitFromBeacon:wlBeacon];
		}
	} else {
		NSArray *wlBeacons = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getMatchingBeaconsWithUuid:uuidString];
		for (WLBeacon *wlBeacon in wlBeacons) {
			[self processExitFromBeacon:wlBeacon];
		}
	}
}

-(void) locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
	/*
	 CoreLocation will call this delegate method at 1 Hz with updated range information.
	 Beacons will be categorized and displayed by proximity. A beacon can belong to multiple
	 regions. It will be displayed multiple times if that is the case. If that is not desired,
	 use a set instead of an array.
	 */
	NSString *beaconDetails = [self getDetailsOfBeacons:beacons];
	rangingStatusHandler(beaconDetails);
	NSLog(@" Beacons:\n%@\n", beaconDetails);

	// See if trigger actions need to be fired for any of the beacons within range.
	WLBeaconsAndTriggersJSONStoreManager *wlBeaconsAndTriggersJSONStoreManager = [WLBeaconsAndTriggersJSONStoreManager sharedInstance];
	for (CLBeacon *beacon in beacons) {
		if (beacon.proximity == CLProximityUnknown) {
			continue;
		}
		NSArray *associations =	[wlBeaconsAndTriggersJSONStoreManager getTriggerAssociationsOfBeaconWithUuid:[self getUuidStringOfBeacon:beacon] andMajor:beacon.major andMinor:beacon.minor];
		for (WLBeaconTriggerAssociation *association in associations) {
//			NSTimeInterval timeElapsedInSecs = [[NSDate date] timeIntervalSinceReferenceDate] - association.timeOfLastTriggerFire;
//			if (timeElapsedInSecs < self.minTimeGapInSecsBetweenConsecutiveTriggerActions) {
//				continue;
//			}
			WLBeaconTrigger *beaconTrigger = [wlBeaconsAndTriggersJSONStoreManager getBeaconTriggerWithName:association.triggerName];
			switch (beaconTrigger.triggerType) {
				case WLBeaconTriggerTypeEnter:
					[self trackBeaconState:beacon forEnterTrigger:beaconTrigger];
					break;
				case WLBeaconTriggerTypeExit:
					[self trackBeaconState:beacon forExitTrigger:beaconTrigger];
					break;
				default:
					break;
			}
		}
		NSString *uuidString = [self getUuidStringOfBeacon:beacon];
		CLProximity lastSeenProximity = [wlBeaconsAndTriggersJSONStoreManager getLastSeenProximityForBeaconWithUuid:uuidString andMajor:beacon.major andMinor:beacon.minor];
		if (beacon.proximity != lastSeenProximity) {
			[wlBeaconsAndTriggersJSONStoreManager setLastSeenProximity:beacon.proximity forBeaconWithUuid:uuidString andMajor:beacon.major andMinor:beacon.minor];
		}
	}
	// Start monitoring for UUID+Major+Minor regions of all beacons within the branch/store. This is required for the case of multiple beacons per branch/store so as to get notified of exit from specific beacon regions. This won't be required for the case of single beacon per branch.
}

-(void) trackBeaconState:(CLBeacon *)beacon forEnterTrigger:(WLBeaconTrigger *)beaconTrigger
{
	CLProximity prevProximity = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getLastSeenProximityForBeaconWithUuid:[self getUuidStringOfBeacon:beacon] andMajor:beacon.major andMinor:beacon.minor];
	CLProximity curProximity = beacon.proximity;
	if (prevProximity == CLProximityUnknown) {
		// transition from CLProximityUnknown to CLProximityFar | CLProximityNear | CLProximityImmediate
		if (beaconTrigger.proximityState == WLBeaconProximityStateFar) {
			[self fireTriggerAction:beaconTrigger forBeacon:beacon];
		} else if (beaconTrigger.proximityState == WLBeaconProximityStateNear && (curProximity == CLProximityNear || curProximity == CLProximityImmediate)) {
			[self fireTriggerAction:beaconTrigger forBeacon:beacon];
		} else if (beaconTrigger.proximityState == WLBeaconProximityStateImmediate && curProximity == CLProximityImmediate) {
			[self fireTriggerAction:beaconTrigger forBeacon:beacon];
		}
	} else if (prevProximity == CLProximityFar && (curProximity == CLProximityNear || curProximity == CLProximityImmediate)) {
		// transition from CLProximityFar to CLProximityNear | CLProximityImmediate
		if (beaconTrigger.proximityState == WLBeaconProximityStateNear) {
			[self fireTriggerAction:beaconTrigger forBeacon:beacon];
		} else if (beaconTrigger.proximityState == WLBeaconProximityStateImmediate && curProximity == CLProximityImmediate) {
			[self fireTriggerAction:beaconTrigger forBeacon:beacon];
		}
	} else if (prevProximity == CLProximityNear && curProximity == CLProximityImmediate) {
		// transition from CLProximityNear to CLProximityImmediate
		if (beaconTrigger.proximityState == WLBeaconProximityStateImmediate) {
			[self fireTriggerAction:beaconTrigger forBeacon:beacon];
		}
	}
}

-(void) trackBeaconState:(CLBeacon *)beacon forExitTrigger:(WLBeaconTrigger *)beaconTrigger
{
	CLProximity prevProximity = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getLastSeenProximityForBeaconWithUuid:[self getUuidStringOfBeacon:beacon] andMajor:beacon.major andMinor:beacon.minor];
	CLProximity curProximity = beacon.proximity;
	if (prevProximity == CLProximityImmediate && (curProximity == CLProximityNear || curProximity == CLProximityFar)) {
		// transition from CLProximityImmediate to CLProximityNear | CLProximityFar
		if (beaconTrigger.proximityState == WLBeaconProximityStateImmediate) {
			[self fireTriggerAction:beaconTrigger forBeacon:beacon];
		} else if (beaconTrigger.proximityState == WLBeaconProximityStateNear && curProximity == CLProximityFar) {
			[self fireTriggerAction:beaconTrigger forBeacon:beacon];
		}
	} else if (prevProximity == CLProximityNear && curProximity == CLProximityFar) {
		// transition from CLProximityNear to CLProximityFar
		if (beaconTrigger.proximityState == WLBeaconProximityStateNear) {
			[self fireTriggerAction:beaconTrigger forBeacon:beacon];
		}
	}
}

-(void) processExitFromBeacon:(WLBeacon *)wlBeacon {
	WLBeaconsAndTriggersJSONStoreManager *wlBeaconsAndTriggersJSONStoreManager = [WLBeaconsAndTriggersJSONStoreManager sharedInstance];
	CLProximity prevProximity = [wlBeaconsAndTriggersJSONStoreManager getLastSeenProximityOfBeacon:wlBeacon];
	if (prevProximity == CLProximityUnknown) {
		return;
	}
	NSArray *associations =	[wlBeaconsAndTriggersJSONStoreManager getTriggerAssociationsOfBeaconWithUuid:wlBeacon.uuid andMajor:wlBeacon.major andMinor:wlBeacon.minor];
	for (WLBeaconTriggerAssociation *association in associations) {
		WLBeaconTrigger *beaconTrigger = [wlBeaconsAndTriggersJSONStoreManager getBeaconTriggerWithName:association.triggerName];
		if (beaconTrigger.triggerType == WLBeaconTriggerTypeExit) {
			[self processExitFromBeacon:wlBeacon withTrigger:beaconTrigger withPrevProximity:prevProximity];
		}
	}
	[wlBeaconsAndTriggersJSONStoreManager setLastSeenProximity:CLProximityUnknown forBeaconWithUuid:wlBeacon.uuid andMajor:wlBeacon.major andMinor:wlBeacon.minor];
}

-(void) processExitFromBeacon:(WLBeacon *)beacon withTrigger:(WLBeaconTrigger *)beaconTrigger withPrevProximity:(CLProximity)prevProximity
{
	if (prevProximity == CLProximityImmediate) {
		// transition from CLProximityImmediate to outside
		[self fireTriggerAction:beaconTrigger forWLBeacon:beacon];
	} else if (prevProximity == CLProximityNear) {
		// transition from CLProximityNear to outside
		if (beaconTrigger.proximityState == WLBeaconProximityStateNear || beaconTrigger.proximityState == WLBeaconProximityStateFar) {
			[self fireTriggerAction:beaconTrigger forWLBeacon:beacon];
		}
	} else if (prevProximity == CLProximityFar) {
		// transition from CLProximityFar to outside
		if (beaconTrigger.proximityState == WLBeaconProximityStateFar) {
			[self fireTriggerAction:beaconTrigger forWLBeacon:beacon];
		}
	}
}

-(void) trackBeaconState:(CLBeacon *)beacon forDwellInsideTrigger:(WLBeaconTrigger *)beaconTrigger
{
	// ToDo
	CLProximity prevProximity = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getLastSeenProximityForBeaconWithUuid:[self getUuidStringOfBeacon:beacon] andMajor:beacon.major andMinor:beacon.minor];
	CLProximity curProximity = beacon.proximity;
	if (curProximity == prevProximity ) {
//		NSTimeInterval timeElapsedInSecs = [[NSDate date] timeIntervalSinceReferenceDate] - association.timeOfLastTriggerFire;
//		if (timeElapsedInSecs < self.minTimeGapInSecsBetweenConsecutiveTriggerActions) {
//			;
//		}
	}
}

-(void) fireTriggerAction:(WLBeaconTrigger *)beaconTrigger forBeacon:(CLBeacon *)beacon
{
	WLBeacon *wlBeacon = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getBeaconWithUuid:[self getUuidStringOfBeacon:beacon] andMajor:beacon.major andMinor:beacon.minor];
	[self fireTriggerAction:beaconTrigger forWLBeacon:wlBeacon];
}

-(void) fireTriggerAction:(WLBeaconTrigger *)beaconTrigger forBeaconRegion:(CLBeaconRegion *)beaconRegion
{
	WLBeacon *wlBeacon = [[WLBeaconsAndTriggersJSONStoreManager sharedInstance] getBeaconWithUuid:[self getUuidStringOfBeaconRegion:beaconRegion] andMajor:beaconRegion.major andMinor:beaconRegion.minor];
	[self fireTriggerAction:beaconTrigger forWLBeacon:wlBeacon];
}

-(void) fireTriggerAction:(WLBeaconTrigger *)beaconTrigger forWLBeacon:(WLBeacon *)wlBeacon
{
	NSString *branchName = [wlBeacon.customData objectForKey:@"branchName"];
	NSString *alertMessage = [beaconTrigger.actionPayload objectForKey:@"alert"];
	if(alertMessage != nil) {
		alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"$branchName" withString:branchName];
		NSString *alertTitle = [WLBeaconTrigger beaconTriggerTypeToString:beaconTrigger.triggerType];
		[self sendLocalNotification:alertTitle withMessage:alertMessage];
	} else {
		NSString *adapterName = [beaconTrigger.actionPayload objectForKey:@"adapterName"];
		NSString *procedureName = [beaconTrigger.actionPayload objectForKey:@"procedureName"];
		NSString *userName = [self getUserName];
		[self invokeAdapterProcedure:adapterName withProcedure:procedureName forUser:userName forBranch:branchName];
	};
}

-(NSString *) getUserName
{
	return @"<username>";
}

-(void) sendLocalNotification:(NSString *)alertTitle withMessage:(NSString *)alertMessage
{
	UILocalNotification *localNotif = [[UILocalNotification alloc] init];
	if (localNotif == nil) {
		return;
	}
	localNotif.alertBody = alertMessage;
	localNotif.alertAction = alertTitle;
	localNotif.soundName = UILocalNotificationDefaultSoundName;
	localNotif.applicationIconBadgeNumber = 1;
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithObject:alertMessage forKey:@"alertMessage"];
	[infoDict setValue:alertTitle forKey:@"alertTitle"];
	localNotif.userInfo = infoDict;
	[[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
}

- (void) invokeAdapterProcedure:(NSString *)adapterName withProcedure:(NSString *)procedureName forUser:(NSString*)userName forBranch:(NSString *)branchName
{
	NSLog(@"Invoking Adapter:%@ withProcedure:%@ forUser:%@ forBranch:%@...", adapterName, procedureName, userName, branchName);
	NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"/adapters/%@/%@", adapterName, procedureName]];
	WLResourceRequest* request = [WLResourceRequest requestWithURL:url method:WLHttpMethodGet];
	[request setQueryParameterValue:[NSString stringWithFormat:@"['%@','%@']", userName, branchName] forName:@"params"];
	[request sendWithCompletionHandler:^(WLResponse *response, NSError *error) {
		if (error != nil) {
			NSLog(@"Invocation Failure: %@", error);
		} else {
			NSLog(@"Invocation Success: %@", response);
		}
	}];
}

#pragma mark - utility functions

-(NSUUID *) createUuidFromString:(NSString *) uuidString
{
	return [[NSUUID alloc] initWithUUIDString:uuidString];
}

-(NSString *) getUuidStringOfBeacon:(CLBeacon *)beacon
{
	return [beacon.proximityUUID.UUIDString lowercaseString];
}

-(NSString *) getUuidStringOfBeaconRegion:(CLBeaconRegion *)beaconRegion
{
	return [beaconRegion.proximityUUID.UUIDString lowercaseString];
}

-(NSString *) getDetailsOfBeacons:(NSArray *)beacons
{
	NSMutableString *beaconDetails = [[NSMutableString alloc] initWithString:[self getCurrentTimeStamp]];
	[beaconDetails appendString:@"\n"];
	for(CLBeacon *beacon in beacons) {
		NSString *uuid = [@"UUID: " stringByAppendingString:[self getUuidStringOfBeacon:beacon]];
		NSString *major = [@", Major: " stringByAppendingString:[[beacon major] stringValue]];
		NSString *minor = [@", Minor: " stringByAppendingString:[[beacon minor] stringValue]];
		NSString *proximity = [@", Proximity: " stringByAppendingString:[WLBeacon CLProximityToString:[beacon proximity]]];
		NSString *accuracy = [NSString stringWithFormat:@", Accuracy: %.2fm", beacon.accuracy];
		[beaconDetails appendString:uuid];
		[beaconDetails appendString:major];
		[beaconDetails appendString:minor];
		[beaconDetails appendString:proximity];
		[beaconDetails appendString:accuracy];
		[beaconDetails appendString:@"\n"];
	}
	return beaconDetails;
}

-(NSString *) getCurrentTimeStamp
{
	NSDate *currentTime = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	NSString *resultString = [dateFormatter stringFromDate: currentTime];
	return resultString;
}

#pragma mark - Functions to increase background running time

-(void) notifyApplicationDidEnterBackground {
	[self extendBackgroundRunningTime];
	self.appRunningInBackground = YES;
}

-(void) notifyApplicationDidBecomeActive {
	self.appRunningInBackground = NO;
}

-(void) extendBackgroundRunningTime
{
	if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
		NSLog(@"Starting BeaconRangingBackgroundTask.");
		self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"BeaconRangingBackgroundTask" expirationHandler:^{
			NSLog(@"Ending BeaconRangingBackgroundTask.");
			[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
			self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
		}];
	}
}

#pragma mark - Functions to turn an iOS device into iBeacon

- (void)turnIntoiBeaconWithUuid:(NSString *)uuidString withMajor:(int)major withMinor:(int)minor withStatusHandler:(WLBeaconsStatusHandler)statusHandler
{
	turnIntoiBeaconStatusHandler = statusHandler;
	NSString *identifier = [[NSString alloc] initWithFormat:@"%@_%d_%d", uuidString, major, minor];
	NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
	self.beaconDataToEmit = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major: major minor: minor identifier:identifier];
	[self peripheralManagerDidUpdateState:self.peripheralManager];
}

-(void) stopAdvertisingAsiBeacon
{
	[self.peripheralManager stopAdvertising];
}

-(void) peripheralManagerDidUpdateState:(CBPeripheralManager*)peripheral
{
	if (peripheral.state < CBPeripheralManagerStatePoweredOn) {
		turnIntoiBeaconStatusHandler(@"Error turning device into iBeacon");
		UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Bluetooth must be enabled" message:@"To configure your device as a beacon" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		return;
	}

	[self.peripheralManager stopAdvertising];

	if (self.beaconDataToEmit) {
		// The region's peripheral data contains the CoreBluetooth-specific data we need to advertise.
		NSDictionary *peripheralData = [self.beaconDataToEmit peripheralDataWithMeasuredPower:@-59];
		[self.peripheralManager startAdvertising:peripheralData];
		NSString *uuidString = [self getUuidStringOfBeaconRegion:self.beaconDataToEmit];
		int major = self.beaconDataToEmit.major.intValue;
		int minor = self.beaconDataToEmit.minor.intValue;
		turnIntoiBeaconStatusHandler([[NSString alloc] initWithFormat:@"%@\nDevice is now broadcasting as an iBeacon with UUID=%@, major=%d, minor=%d", [self getCurrentTimeStamp], uuidString, major, minor]);
	}
}

@end
