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

#import <UIKit/UIKit.h>
#import "ESTBeaconManager.h"
#import <Cordova/CDVPlugin.h>

@interface CDVEstimote : CDVPlugin
{
//     double x;
//     double y;
//     double z;
//     NSTimeInterval timestamp;
}

@property (readonly, assign) BOOL isRunning;
@property (nonatomic, strong) NSString* callbackId;

- (CDVEstimote *)init;

- (void)start:(CDVInvokedUrlCommand*)command;
- (void)stop:(CDVInvokedUrlCommand*)command;

@end
