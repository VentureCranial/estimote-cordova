<!---
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
-->

# com.venturecranial.cordova.estimote

This plugin provides access to the Estimote iOS SDK. Estimotes are
Bluetooth LE beacons which provide location, temperature, and motion
information in a manner which is compatible with Apple's iBeacon and
CoreLocation standards.

## Installation

    cordova plugin add com.venturecranial.cordova.estimote

## Supported Platforms

- iOS

## Methods

- Estimote.startRangingBeacons(success_callback, error_callback, [
       optional_interval_in_seconds])
- Estimote.stopRangingBeacons

## Objects

Callback receives an EstimoteAPIResponse object which lists:
    - whether ranging is currently active
    - the number of beacons in range
    - an array of beacon objects which provide:
      - the estimote color
      - the distance
      - the rssi value
      - the major and minor id numbers of the beacon

The callback will be invoked at MOST every interval seconds, with a default 
value of 10 seconds.

