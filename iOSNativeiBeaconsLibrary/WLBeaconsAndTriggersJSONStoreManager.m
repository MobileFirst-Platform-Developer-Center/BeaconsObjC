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

#import "WLBeaconsAndTriggersJSONStoreManager.h"
#import <IBMMobileFirstPlatformFoundation/IBMMobileFirstPlatformFoundation.h>

@implementation WLBeaconsAndTriggersJSONStoreManager

static WLBeaconsAndTriggersJSONStoreManager* sharedInstance = nil;

+ (WLBeaconsAndTriggersJSONStoreManager *) sharedInstance
{
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [[self alloc] init];
		}
		return sharedInstance;
	}
}

- (void) loadBeaconsAndTriggersFromAdapter:(NSString *)adapterName withProcedure:(NSString *)procedureName withCompletionHandler:(LoadBeaconsAndTriggersCompletionHandler) completionHandler
{
	NSLog(@"Invoking loadBeaconsAndTriggersFromAdapter:%@ withProcedure:%@ ...", adapterName, procedureName);
	NSString *applicationName = [self getApplicationName];
	NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"/adapters/%@/%@", adapterName, procedureName]];
	WLResourceRequest* request = [WLResourceRequest requestWithURL:url method:WLHttpMethodGet];
	[request setQueryParameterValue:[NSString stringWithFormat:@"['%@',null]", applicationName] forName:@"params"];
	[request sendWithCompletionHandler:^(WLResponse *response, NSError *error) {
		if (error != nil) {
			NSLog(@"Invocation Failure: %@", error);
			NSString *resultText = @"Invocation failure.\n";
			resultText = [resultText stringByAppendingString: error.description];
			completionHandler(false, resultText);
		} else {
			NSLog(@"Invocation Success: %@", response);
			NSDictionary *responseDictionary = [response getResponseJson];
			[[WLBeaconsAndTriggersJSONStoreManager sharedInstance] saveBeaconsAndTriggersIntoJSONStore:responseDictionary];
			completionHandler(true, nil);
		}
	}];
}

- (NSString *) getApplicationName
{
	NSString* plistLoc = [[NSBundle mainBundle]pathForResource:@"worklight" ofType:@"plist"];
	if (plistLoc == nil) {
		NSLog(@"Unable to locate worklight.plist! Application id will be nil!");
		return nil;
	}
	NSDictionary* wlProps = [NSDictionary dictionaryWithContentsOfFile:plistLoc];
	NSString* applicationId = [wlProps valueForKey:@"application id"];
	return applicationId;
}

- (void) saveBeaconsAndTriggersIntoJSONStore:(NSDictionary *)responseDictionary
{
	NSArray *beaconsDictionary = [responseDictionary objectForKey:@"beacons"];
	NSArray *beaconTriggersDictionary = [responseDictionary objectForKey:@"beaconTriggers"];
	NSArray *beaconTriggerAssociationsDictionary = [responseDictionary objectForKey:@"beaconTriggerAssociations"];
	
	NSError* error = nil;
	[[JSONStore sharedInstance] destroyDataAndReturnError:&error];
	
	[self saveBeaconsIntoJsonStore:beaconsDictionary];
	[self saveBeaconTriggersIntoJsonStore:beaconTriggersDictionary];
	[self saveBeaconTriggerAssociationsIntoJsonStore:beaconTriggerAssociationsDictionary];
}

- (JSONStoreCollection *) beaconsJSONStoreCollection
{
	NSString *collectionName = @"beacons";
	JSONStoreCollection* jsonStoreCollection = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
	if (jsonStoreCollection == nil) {
		jsonStoreCollection = [[JSONStoreCollection alloc] initWithName:collectionName];
		[jsonStoreCollection setSearchField:@"uuid" withType:JSONStore_String];
		[jsonStoreCollection setSearchField:@"major" withType:JSONStore_Integer];
		[jsonStoreCollection setSearchField:@"minor" withType:JSONStore_Integer];
		[[JSONStore sharedInstance] openCollections:@[jsonStoreCollection] withOptions:nil error:nil];
	}
	return jsonStoreCollection;
}

- (JSONStoreCollection *) beaconTriggersJSONStoreCollection
{
	NSString *collectionName = @"beaconTriggers";
	JSONStoreCollection* jsonStoreCollection = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
	if (jsonStoreCollection == nil) {
		jsonStoreCollection = [[JSONStoreCollection alloc] initWithName:collectionName];
		// triggerName cannot be used as search field as it is a reserved keyword in SQLite!
		[jsonStoreCollection setSearchField:@"name" withType:JSONStore_String];
		[[JSONStore sharedInstance] openCollections:@[jsonStoreCollection] withOptions:nil error:nil];
	}
	return jsonStoreCollection;
}

- (JSONStoreCollection *) beaconTriggerAssociationsJSONStoreCollection
{
	NSString *collectionName = @"beaconTriggerAssociations";
	JSONStoreCollection* jsonStoreCollection = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
	if (jsonStoreCollection == nil) {
		jsonStoreCollection = [[JSONStoreCollection alloc] initWithName:collectionName];
		[jsonStoreCollection setSearchField:@"uuid" withType:JSONStore_String];
		[jsonStoreCollection setSearchField:@"major" withType:JSONStore_Integer];
		[jsonStoreCollection setSearchField:@"minor" withType:JSONStore_Integer];
		[[JSONStore sharedInstance] openCollections:@[jsonStoreCollection] withOptions:nil error:nil];
	}
	return jsonStoreCollection;
}

- (JSONStoreCollection *) monitoredRegionsJSONStoreCollection
{
	NSString *collectionName = @"monitoredRegions";
	JSONStoreCollection* jsonStoreCollection = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
	if (jsonStoreCollection == nil) {
		jsonStoreCollection = [[JSONStoreCollection alloc] initWithName:collectionName];
		[jsonStoreCollection setSearchField:@"identifier" withType:JSONStore_String];
		[[JSONStore sharedInstance] openCollections:@[jsonStoreCollection] withOptions:nil error:nil];
	}
	return jsonStoreCollection;
}

- (void) saveBeaconsIntoJsonStore:(NSArray *)beaconsJsonArray
{
	[[self beaconsJSONStoreCollection] addData:beaconsJsonArray andMarkDirty:NO withOptions:nil error:nil];
}

- (void) saveBeaconTriggersIntoJsonStore:(NSArray *)beaconTriggersJsonArray
{
	// Workaround for "triggerName cannot be used as search field as it is a reserved keyword in SQLite!"
	NSMutableArray *newJsonArray = [[NSMutableArray alloc] init];
	for (NSDictionary *dict in beaconTriggersJsonArray) {
		NSMutableDictionary *newDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
		NSString *triggerName = [dict objectForKey:@"triggerName"];
		[newDict setObject:triggerName forKey:@"name"];
		[newJsonArray addObject:newDict];
	}
	[[self beaconTriggersJSONStoreCollection] addData:newJsonArray andMarkDirty:NO withOptions:nil error:nil];
}

- (void) saveBeaconTriggerAssociationsIntoJsonStore:(NSArray *)beaconTriggerAssociationsJsonArray
{
	[[self beaconTriggerAssociationsJSONStoreCollection] addData:beaconTriggerAssociationsJsonArray andMarkDirty:NO withOptions:nil error:nil];
}

- (NSArray *) getBeaconsFromJsonStore
{
	NSArray *beaconsJson = [[self beaconsJSONStoreCollection] findAllWithOptions:nil error:nil];
	return [self getBeacons:beaconsJson];
}

- (NSArray *) getBeaconTriggersFromJsonStore
{
	NSArray *beaconTriggersJson = [[self beaconTriggersJSONStoreCollection] findAllWithOptions:nil error:nil];
	return [self getBeaconTriggers:beaconTriggersJson];
}

- (NSArray *) getBeaconTriggerAssociationsFromJsonStore
{
	NSArray *beaconTriggerAssociationsJson = [[self beaconTriggerAssociationsJSONStoreCollection] findAllWithOptions:nil error:nil];
	return [self getBeaconTriggerAssociations:beaconTriggerAssociationsJson];
}

- (NSArray *) getBeacons:(NSArray *)beaconsJson
{
	// Parse beaconsJson
	NSMutableArray *beacons = [[NSMutableArray alloc] init];
	for (int i=0; i<beaconsJson.count; i++) {
		NSDictionary *beaconDict = beaconsJson[i];
		if ([beaconDict objectForKey:@"json"]) {
			beaconDict = [beaconDict objectForKey:@"json"];
		}
		WLBeacon *beacon = [[WLBeacon alloc] initFromJson:beaconDict];
		[beacons addObject:beacon];
	}
	return beacons;
}

- (NSArray *) getBeaconTriggers:(NSArray *)beaconTriggersJson
{
	// Parse beaconTriggersJson
	NSMutableArray *beaconTriggers = [[NSMutableArray alloc] init];
	for (int i=0; i<beaconTriggersJson.count; i++) {
		NSDictionary *beaconTriggerDict = beaconTriggersJson[i];
		if ([beaconTriggerDict objectForKey:@"json"]) {
			beaconTriggerDict = [beaconTriggerDict objectForKey:@"json"];
		}
		WLBeaconTrigger *beaconTrigger = [[WLBeaconTrigger alloc] initFromJson:beaconTriggerDict];
		[beaconTriggers addObject:beaconTrigger];
	}
	return beaconTriggers;
}

- (NSArray *) getBeaconTriggerAssociations:(NSArray *)beaconTriggerAssociationsJson
{
	// Parse beaconTriggerAssociationsJson
	NSMutableArray *beaconTriggerAssociations = [[NSMutableArray alloc] init];
	for (int i=0; i<beaconTriggerAssociationsJson.count; i++) {
		NSDictionary *beaconTriggerAssociationDict = beaconTriggerAssociationsJson[i];
		if ([beaconTriggerAssociationDict objectForKey:@"json"]) {
			beaconTriggerAssociationDict = [beaconTriggerAssociationDict objectForKey:@"json"];
		}
		WLBeaconTriggerAssociation *beaconTriggerAssociation = [[WLBeaconTriggerAssociation alloc] initFromJson:beaconTriggerAssociationDict];
		[beaconTriggerAssociations addObject:beaconTriggerAssociation];
	}
	return beaconTriggerAssociations;
}

- (NSSet *) getUuids
{
	// Returns an array of NSString
	NSArray *results = [[self beaconsJSONStoreCollection] findAllWithOptions:nil error:nil];
	if (results) {
		NSMutableSet *uuids = [[NSMutableSet alloc] init];
		for (NSDictionary *result in results) {
			NSString *uuid = [result valueForKeyPath:@"json.uuid"];
			[uuids addObject:uuid];
		}
		return uuids;
	}
	return nil;
}

- (NSArray *) getMatchingBeaconsWithUuid:(NSString *)uuid
{
	// Returns an array of WLBeacon
	JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
	[queryPart searchField:@"uuid" equal:uuid];
	NSArray* results = [[self beaconsJSONStoreCollection] findWithQueryParts:@[queryPart] andOptions:nil error:nil];
	if (results) {
		NSMutableArray *beacons = [[NSMutableArray alloc] init];
		for (NSDictionary *result in results) {
			NSDictionary *beaconDict = [result objectForKey:@"json"];
			WLBeacon *beacon = [[WLBeacon alloc] initFromJson:beaconDict];
			[beacons addObject:beacon];
		}
		return beacons;
	}
	return nil;
}

- (NSArray *) getMatchingBeaconsWithUuid:(NSString *)uuid andMajor:(NSNumber *)major
{
	// Returns an array of WLBeacon
	JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
	[queryPart searchField:@"uuid" equal:uuid];
	[queryPart searchField:@"major" equal:[major stringValue]];
	NSArray* results = [[self beaconsJSONStoreCollection] findWithQueryParts:@[queryPart] andOptions:nil error:nil];
	if (results) {
		NSMutableArray *beacons = [[NSMutableArray alloc] init];
		for (NSDictionary *result in results) {
			NSDictionary *beaconDict = [result objectForKey:@"json"];
			WLBeacon *beacon = [[WLBeacon alloc] initFromJson:beaconDict];
			[beacons addObject:beacon];
		}
		return beacons;
	}
	return nil;
}

- (WLBeacon *) getBeaconWithUuid:(NSString *)uuid andMajor:(NSNumber *)major andMinor:(NSNumber *)minor
{
	JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
	[queryPart searchField:@"uuid" equal:uuid];
	[queryPart searchField:@"major" equal:[major stringValue]];
	[queryPart searchField:@"minor" equal:[minor stringValue]];
	NSArray* results = [[self beaconsJSONStoreCollection] findWithQueryParts:@[queryPart] andOptions:nil error:nil];
	if (results && results.count == 1) {
		NSDictionary *result = results[0];
		NSDictionary *beaconDict = [result objectForKey:@"json"];
		WLBeacon *beacon = [[WLBeacon alloc] initFromJson:beaconDict];
		return beacon;
	}
	return nil;
}

- (NSArray *) getTriggerAssociationsOfBeaconWithUuid:(NSString *)uuid andMajor:(NSNumber *)major andMinor:(NSNumber *)minor
{
	// Returns an array of WLBeaconTriggerAssociation
	JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
	[queryPart searchField:@"uuid" equal:uuid];
	[queryPart searchField:@"major" equal:[major stringValue]];
	[queryPart searchField:@"minor" equal:[minor stringValue]];
	NSArray* results = [[self beaconTriggerAssociationsJSONStoreCollection] findWithQueryParts:@[queryPart] andOptions:nil error:nil];
	if (results) {
		NSMutableArray *associations = [[NSMutableArray alloc] init];
		for (NSDictionary *result in results) {
			NSDictionary *beaconTriggerAssociationDict = [result objectForKey:@"json"];
			WLBeaconTriggerAssociation *beaconTriggerAssociation = [[WLBeaconTriggerAssociation alloc] initFromJson:beaconTriggerAssociationDict];
			[associations addObject:beaconTriggerAssociation];
		}
		return associations;
	}
	return nil;
}

- (WLBeaconTrigger *) getBeaconTriggerWithName:(NSString *)triggerName
{
	JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
	// triggerName cannot be used as search field as it is a reserved keyword in SQLite!
	[queryPart searchField:@"name" equal:triggerName];
	NSArray* results = [[self beaconTriggersJSONStoreCollection] findWithQueryParts:@[queryPart] andOptions:nil error:nil];
	if (results && results.count == 1) {
		NSDictionary *result = results[0];
		NSDictionary *beaconTriggerDict = [result objectForKey:@"json"];
		WLBeaconTrigger *beaconTrigger = [[WLBeaconTrigger alloc] initFromJson:beaconTriggerDict];
		return beaconTrigger;
	}
	return nil;
}

- (void) addToMonitoredRegions:(CLBeaconRegion *)region
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict setObject:region.identifier forKey:@"identifier"];
	[dict setObject:[region.proximityUUID UUIDString] forKey:@"uuid"];
	if (region.major) {
		[dict setObject:region.major forKey:@"major"];
	}
	if (region.minor) {
		[dict setObject:region.minor forKey:@"minor"];
	}
	[[self monitoredRegionsJSONStoreCollection] addData:@[dict] andMarkDirty:NO withOptions:nil error:nil];
}

- (void) removeFromMonitoredRegions:(CLBeaconRegion *)region
{
	NSString *identifier = region.identifier;
	JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
	[queryPart searchField:@"identifier" equal:identifier];
	NSArray* results = [[self monitoredRegionsJSONStoreCollection] findWithQueryParts:@[queryPart] andOptions:nil error:nil];
	if (results && results.count > 0) {
		NSDictionary *result = results[0];
		NSNumber *id = [result objectForKey:@"_id"];
		[[self monitoredRegionsJSONStoreCollection] removeWithIds:@[id] andMarkDirty:NO error:nil];
	}
}

- (NSArray *) getMonitoredRegions
{
	NSArray *results = [[self monitoredRegionsJSONStoreCollection] findAllWithOptions:nil error:nil];
	if (results) {
		NSMutableArray *monitoredRegions = [[NSMutableArray alloc] init];
		for (NSDictionary *result in results) {
			NSDictionary *dict = [result objectForKey:@"json"];
			NSString *identifier = [dict objectForKey:@"identifier"];
			NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[dict objectForKey:@"uuid"]];
			NSNumber *major = [dict objectForKey:@"major"];
			NSNumber *minor = [dict objectForKey:@"minor"];
			CLBeaconRegion *monitoredRegion;
			if (major && minor) {
				monitoredRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[major intValue] minor:[minor intValue] identifier:identifier];
			} else if (major) {
				monitoredRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[major intValue] identifier:identifier];
			} else {
				monitoredRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier];
			}
			[monitoredRegions addObject:monitoredRegion];
		}
		return monitoredRegions;
	}
	return nil;
}

- (void) resetMonitoredRegions
{
	[[self monitoredRegionsJSONStoreCollection] removeCollectionWithError:nil];
}

- (void) setLastSeenProximity:(CLProximity)proximity forBeaconWithUuid:(NSString *)uuid andMajor:(NSNumber *)major andMinor:(NSNumber *)minor
{
	JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
	[queryPart searchField:@"uuid" equal:uuid];
	[queryPart searchField:@"major" equal:[major stringValue]];
	[queryPart searchField:@"minor" equal:[minor stringValue]];
	NSArray* results = [[self beaconsJSONStoreCollection] findWithQueryParts:@[queryPart] andOptions:nil error:nil];
	if (results && results.count == 1) {
		NSDictionary *result = results[0];

		NSDictionary *beaconDict = [result objectForKey:@"json"];
		NSMutableDictionary *newBeaconDict = [[NSMutableDictionary alloc] initWithDictionary:beaconDict];
		NSString *proximityString = [WLBeacon CLProximityToString:proximity];
		[newBeaconDict setValue:proximityString forKey:@"lastSeenProximity"];

		NSNumber *_id = [result objectForKey:@"_id"];
		NSMutableDictionary *newResult = [[NSMutableDictionary alloc] init];
		[newResult setValue:_id forKey:@"_id"];
		[newResult setValue:newBeaconDict forKey:@"json"];
	
		NSError* error = nil;
		int docsReplaced = [[[self beaconsJSONStoreCollection] replaceDocuments:@[newResult] andMarkDirty:NO error:&error] intValue];
		NSLog(@"#of docs replaced = %d\n", docsReplaced);
	}
}

- (CLProximity) getLastSeenProximityForBeaconWithUuid:(NSString *)uuid andMajor:(NSNumber *)major andMinor:(NSNumber *)minor
{
	WLBeacon *beacon = [self getBeaconWithUuid:uuid andMajor:major andMinor:minor];
	CLProximity proximity = [WLBeacon StringToCLProximity:beacon.lastSeenProximity];
	return proximity;
}

- (CLProximity) getLastSeenProximityOfBeacon:(WLBeacon *)beacon
{
	CLProximity proximity = [WLBeacon StringToCLProximity:beacon.lastSeenProximity];
	return proximity;
}

- (void) setTimeOfLastTriggerFire:(int)timeInterval triggerName:(NSString *)triggerName uuid:(NSString *)uuid major:(NSNumber *)major minor:(NSNumber *)minor
{
	//ToDo
}

@end
