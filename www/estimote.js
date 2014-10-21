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

/**
 * This class provides access to device estimote IOS sdk
 * @constructor
 */
var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec'),
    EstimoteAPIResponse = require('./EstimoteAPIResponse');

//  Is the API currently scanning?
var scanning = false;

// Keeps reference to startRangingBeacons calls.
var timers = {};

// Array of listeners; used to keep track of when we should call start and stop.
var listeners = [];

// Last reply from native
var reply = null;


function startScanning(win, fail, interval) {
    if (!scanning) {
        exec(win, fail, 'Estimote', 'startRangingBeacons', [interval]);
    }
    scanning = true;
}

function stopScanning() {
    // Tell tne Objective-C part to stop ranging beacons.
    if (scanning) {
        exec(null, null, 'Estimote', 'stopRangingBeacons', []);
    }
    scanning = false;
}


// Adds a callback pair to the listeners array
function createCallbackPair(win, fail) {
    return {win:win, fail:fail};
}

// Removes a win/fail listener pair from the listeners array
function removeListeners(l) {
    var idx = listeners.indexOf(l);
    if (idx > -1) {
        listeners.splice(idx, 1);
    }

    if (listeners.length === 0) {
        stopScanning();
    }
}

var EstimoteAPI = {

    /**
     * Asynchronously begin scanning for beacons in range.
     *
     * @param {Function} successCallback    The function to call each time beacon list updates
     * @param {Function} errorCallback      The function to call when there is an error getting beacon list. (OPTIONAL)
     */
    startRangingBeacons: function(successCallback, errorCallback, options) {

        argscheck.checkArgs('fFO', 'estimote.startRangingBeacons', arguments);

        // Build our two callback functions for our listener
        var win = function(a) {
            successCallback(reply);
        };

        var fail = function(e) {
            errorCallback && errorCallback(e);
        };

        // Add the listsner functions to our list
        listeners.push(createCallbackPair(win, fail));

        var interval = 10;
        if (options && options.interval) {
            interval = options.interval;
        }

        // If we are not currently scanning, start the scanner and let
        // 'er rip.
        startScanning(
            function(a) {
                reply = new EstimoteAPIResponse(a.isScanning, a.count, a.beacons);
                for (var i = 0, l = listeners.length; i < l; i++) {
                    listeners[i].win(reply);
                }
            },

            function(e) {
                for (var i = 0, l = listeners.length; i < l; i++) {
                    listeners[i].fail(e);
                }
            }, 

            interval);
    },

    /**
     * Stops ranging beacons.
     *
     */
    stopRangingBeacons: function(successCallback, errorCallback, options) {
        removeListeners(null);
        stopScanning();
    }
};

module.exports = EstimoteAPI;
