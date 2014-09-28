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

@interface CDVEstimote () <ESTBeaconManagerDelegate> {}
@property (readwrite, assign) BOOL isRunning;
@property (readwrite, assign) BOOL haveReturnedResult;
@property (readwrite, strong) ESTBeaconManager* beaconManager;
@property (readwrite, strong) ESTBeaconRegion *region;
@property (readwrite, strong) NSArray *beaconsArray;
@end

@implementation CDVEstimote

@synthesize callbackId, isRunning;

// defaults to 10 msec
#define kAccelerometerInterval 10
// g constant: -9.81 m/s^2
#define kGravitationalConstant -9.81

- (CDVEstimote*)init {
    self = [super init];
    if (self) {
        self.callbackId = nil;
        self.isRunning = NO;
        self.haveReturnedResult = YES;
        self.beaconManager = nil;
    }
    return self;
}

- (void)dealloc {
    [self stop:nil];
}

- (void)start:(CDVInvokedUrlCommand*)command {

    self.haveReturnedResult = NO;
    self.callbackId = command.callbackId;

    if (!self.beaconManager) {
        self.beaconManager = [[ESTBeaconManager alloc] init];
        self.beaconManager.delegate = self;

        self.region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                              identifier:@"EstimoteSampleRegion"];

        [self.beaconManager requestAlwaysAuthorization];
        [self startRangingBeacons];
    }

    // if ([self.motionManager isAccelerometerAvailable] == YES) {
    //     // Assign the update interval to the motion manager and start updates
    //     [self.motionManager setAccelerometerUpdateInterval:kAccelerometerInterval/1000];  // expected in seconds
    //     __weak CDVAccelerometer* weakSelf = self;
    //     [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
    //         x = accelerometerData.acceleration.x;
    //         y = accelerometerData.acceleration.y;
    //         z = accelerometerData.acceleration.z;
    //         timestamp = ([[NSDate date] timeIntervalSince1970] * 1000);
    //         [weakSelf returnAccelInfo];
    //     }];

    //     if (!self.isRunning) {
    //         self.isRunning = YES;
    //     }
    // }

}

- (void)onReset
{
    [self stop:nil];
}

- (void)stop:(CDVInvokedUrlCommand*)command {
    if (!self.beaconManager) {
        [self stopRangingBeacons];
    //     if (self.haveReturnedResult == NO){
    //         // block has not fired before stop was called, return whatever result we currently have
    //         [self returnAccelInfo];
    //     }
    //     [self.motionManager stopAccelerometerUpdates];
    }

    self.isRunning = NO;
}

- (void)returnBeaconList {
    NSMutableDictionary* beaconList = [NSMutableDictionary dictionaryWithCapacity:2];
    [beaconList setValue:[NSNumber numberWithUnsignedInteger:[self.beaconsArray count]] forKey:@"count"];
    [beaconList setValue:[NSArray arrayWithArray:self.beaconsArray] forKey:@"beacons"];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:beaconList];
    [result setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    self.haveReturnedResult = YES;
}

// TODO: Consider using filtering to isolate instantaneous data vs. gravity data -jm

/*
 #define kFilteringFactor 0.1

 // Use a basic low-pass filter to keep only the gravity component of each axis.
 grav_accelX = (acceleration.x * kFilteringFactor) + ( grav_accelX * (1.0 - kFilteringFactor));
 grav_accelY = (acceleration.y * kFilteringFactor) + ( grav_accelY * (1.0 - kFilteringFactor));
 grav_accelZ = (acceleration.z * kFilteringFactor) + ( grav_accelZ * (1.0 - kFilteringFactor));

 // Subtract the low-pass value from the current value to get a simplified high-pass filter
 instant_accelX = acceleration.x - ( (acceleration.x * kFilteringFactor) + (instant_accelX * (1.0 - kFilteringFactor)) );
 instant_accelY = acceleration.y - ( (acceleration.y * kFilteringFactor) + (instant_accelY * (1.0 - kFilteringFactor)) );
 instant_accelZ = acceleration.z - ( (acceleration.z * kFilteringFactor) + (instant_accelZ * (1.0 - kFilteringFactor)) );


 */

-(void)startRangingBeacons {

    if ([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.beaconManager requestAlwaysAuthorization];
    }
    else if([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        [self.beaconManager startRangingBeaconsInRegion:self.region];
    }
    else if([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        // FAILED to get authorization to follow location.
    }
    else if([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        // FAILED to get authorization to follow location.
    }
}

-(void)stopRangingBeacons {
    [self.beaconManager stopRangingBeaconsInRegion:self.region];
    [self.beaconManager stopEstimoteBeaconDiscovery];
}

 /*--- BEACON MANAGER DELEGATE FUNCTIONS */


- (void)beaconManager:(ESTBeaconManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self startRangingBeacons];
}

- (void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region {
    self.beaconsArray = beacons;
    // invoke callback if beacons changed
}

- (void)beaconManager:(ESTBeaconManager *)manager didDiscoverBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region {
    self.beaconsArray = beacons;
    // invoke callback if beacons changed
}

@end
