/*
     Copyright 2014 Venture Cranial, LLC

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

 */

#import "CDVEstimote.h"

@implementation CDVEstimote

@synthesize callbackId, isScanning, callbackInterval,
            nextNotificationAfterTimeInterval;


- (CDVEstimote *)initWithWebView:(UIWebView *)theWebView {
    self = (CDVEstimote *)[super initWithWebView:(UIWebView *)theWebView];
    if (self) {
        self.callbackInterval = 0;
        self.nextNotificationAfterTimeInterval = 0;
        self.callbackId = nil;
        self.beaconManager = [[ESTBeaconManager alloc] init];
        self.beaconManager.delegate = self;
        self.region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                          identifier:@"EstimoteSampleRegion"];
        self.isScanning = NO;

        if ([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            NSLog(@"Requesting estimote beacon authorization.");
            [self.beaconManager requestWhenInUseAuthorization];
        }

    }
    return self;
}

- (void)dealloc {
    [self stopRangingBeacons:nil];
    self.beaconManager.delegate = nil;
    self.region = nil;
    self.isScanning = NO;
    self.callbackId = nil;
    self.beaconManager = nil;
}

/*
 * Start
 *
 * Called when the system should begin looking for beacons. The
 * callback function will be called when the list of beacons
 * updates. The first paramter is an optional minimum interval value,
 * which will keep the ranging process from executing the callback
 * before that number of seconds has passed.
 *
 */

- (void)startRangingBeacons:(CDVInvokedUrlCommand *)command {

    self.callbackId = command.callbackId;

    NSString *interval = [command argumentAtIndex:0];

    if (interval) {
        self.callbackInterval = [interval integerValue];
    } else {
        self.callbackInterval = 10;
    }

    // Force the first interval to run immediately
    self.nextNotificationAfterTimeInterval = 0;

    if (self.beaconManager) {

        if ([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            NSLog(@"Requesting estimote beacon authorization.");
            [self.beaconManager requestWhenInUseAuthorization];
        }

        // NSLog(@"Ranging begins.");
        [self.beaconManager startRangingBeaconsInRegion:self.region];
        self.isScanning = YES;
        [self sendNotificationCallback];
    }


}


- (void)onReset {
    [self stopRangingBeacons:nil];
}

/*
 * Stop
 *
 * Called when the system should discontinue the process of
 * looking for nearby beacons.
 *
 */

- (void)stopRangingBeacons:(CDVInvokedUrlCommand*)command {
    if (self.beaconManager) {
        [self.beaconManager stopRangingBeaconsInRegion:self.region];
    }

    self.isScanning = NO;

    if (command != nil) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

/*
 * sendNotificationCallback
 *
 * Called by the plugin when it finds beacons and needs to alert the
 * JavaScript side via a callback.
 *
 */

- (void)sendNotificationCallback {

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];

    if (now <= self.nextNotificationAfterTimeInterval) {
        return;
    }

    self.nextNotificationAfterTimeInterval = now + self.callbackInterval;

    NSMutableDictionary *beaconList = [NSMutableDictionary dictionaryWithCapacity:3];
    [beaconList setValue:[NSNumber numberWithUnsignedInteger:[self.beaconsArray count]] forKey:@"count"];
    [beaconList setValue:[NSNumber numberWithBool:self.isScanning] forKey:@"isScanning"];

    NSMutableArray *beacons = [NSMutableArray arrayWithCapacity:[self.beaconsArray count]];
    for(ESTBeacon *i in self.beaconsArray) {
        NSMutableDictionary *beacon = [NSMutableDictionary dictionaryWithCapacity:6];
        // [beacon setValue:i.name forKey:@"name"];
        [beacon setValue:[NSNumber numberWithInteger:i.color] forKey:@"color"];
        [beacon setValue:i.major forKey:@"major"];
        [beacon setValue:i.minor forKey:@"minor"];
        [beacon setValue:i.distance forKey:@"distance"];
        [beacon setValue:i.macAddress forKey:@"mac"];
        [beacon setValue:[NSNumber numberWithInteger:i.rssi] forKey:@"rssi"];
        [beacons addObject:beacon];
    }

    [beaconList setValue:[NSArray arrayWithArray:beacons] forKey:@"beacons"];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:beaconList];
    [result setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}


/*
 * beaconsWereLocated
 *
 * Called by the delegate methods when the EstimoteSDK finds beacons.
 * This function also determines if we need to notify the callback.
 *
 */

- (void)beaconsWereLocated {
    [self sendNotificationCallback];
}

 /*--- BEACON MANAGER DELEGATE FUNCTIONS */


- (void)beaconManager:(ESTBeaconManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorized) {
        NSLog(@"Authorization for beacon hunting — approved. Ranging begins.");
        if (self.isScanning) {
            [self.beaconManager startRangingBeaconsInRegion:self.region];
        }
    }
}

- (void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region {
    self.beaconsArray = beacons;
    // NSLog(@"Beacons ranged - calling beaconsWereLocated.");
    [self beaconsWereLocated];
}

- (void)beaconManager:(ESTBeaconManager *)manager didDiscoverBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region {
    self.beaconsArray = beacons;
    // NSLog(@"Beacons discovered - calling beaconsWereLocated.");
    [self beaconsWereLocated];
}

@end
