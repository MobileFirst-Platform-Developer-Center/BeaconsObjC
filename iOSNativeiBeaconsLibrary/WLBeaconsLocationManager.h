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
#import <UIKit/UIKit.h>

typedef void (^WLBeaconsStatusHandler)(NSString* statusDetails);

@interface WLBeaconsLocationManager : NSObject

+(WLBeaconsLocationManager *) sharedInstance;

-(void) requestPermissionToUseLocationServices;
-(void) requestPermissionToUseNotifications;

-(void) startMonitoring;
-(void) stopMonitoring;
-(void) startRangingWithStatusHandler:(WLBeaconsStatusHandler) statusHandler;
-(void) stopRanging;
-(void) resetMonitoringRangingState;

-(void) notifyApplicationDidEnterBackground;
-(void) notifyApplicationDidBecomeActive;
-(void) extendBackgroundRunningTime;

- (void)turnIntoiBeaconWithUuid:(NSString *)uuidString withMajor:(int)major withMinor:(int)minor withStatusHandler:(WLBeaconsStatusHandler) statusHandler;
-(void) stopAdvertisingAsiBeacon;

@end
