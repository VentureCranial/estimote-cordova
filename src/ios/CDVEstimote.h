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

#import "ESTBeaconManager.h"
#import <Cordova/CDVPlugin.h>

@interface CDVEstimote : CDVPlugin <ESTBeaconManagerDelegate> {
}

@property (readwrite, assign) BOOL isScanning;
@property (nonatomic, strong) NSString* callbackId;

@property (readwrite, strong) ESTBeaconManager *beaconManager;
@property (readwrite, strong) ESTBeaconRegion *region;
@property (readwrite, strong) NSArray *beaconsArray;

- (CDVPlugin *)initWithWebView:(UIWebView *)theWebView;
- (void)onReset;

- (void)sendNotificationCallback;
- (void)beaconsWereLocated;


- (void)startRangingBeacons:(CDVInvokedUrlCommand *)command;
- (void)stopRangingBeacons:(CDVInvokedUrlCommand *)command;

@end
