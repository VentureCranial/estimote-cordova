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
    utils = require("cordova/utils"),
    exec = require("cordova/exec");

//  Is the API currently running?
var running = false;

// Keeps reference to startRangingBeacons calls.
var timers = {};

// Array of listeners; used to keep track of when we should call start and stop.
var listeners = [];

// Last reply from native
var reply = null;

// Tells native to start.
function start() {
    exec(function(a) {
        var tempListeners = listeners.slice(0);
        reply = new EstimoteAPI(a.count, a.beaconList);
        for (var i = 0, l = tempListeners.length; i < l; i++) {
            tempListeners[i].win(reply);
        }
    }, function(e) {
        var tempListeners = listeners.slice(0);
        for (var i = 0, l = tempListeners.length; i < l; i++) {
            tempListeners[i].fail(e);
        }
    }, "Estimote", "start", []);
    running = true;
}

// Tells native to stop.
function stop() {
    exec(null, null, "Estimote", "stop", []);
    running = false;
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
        if (listeners.length === 0) {
            stop();
        }
    }
}

var EstimoteAPI = {
    /**
     * Asynchronously scan for Estimote beacons.
     *
     * @param {Function} successCallback    The function to call when the beacon list is available
     * @param {Function} errorCallback      The function to call when there is an error getting the beacon list. (OPTIONAL)
     * @param {EstimoteOptions} options     The options for EstimoteAPI calls. (OPTIONAL)
     */

    rangeAllBeacons: function(successCallback, errorCallback, options) {
        argscheck.checkArgs('fFO', 'estimote.rangeAllBeacons', arguments);

        var p;
        var win = function(a) {
            removeListeners(p);
            successCallback(a);
        };
        var fail = function(e) {
            removeListeners(p);
            errorCallback && errorCallback(e);
        };

        p = createCallbackPair(win, fail);
        listeners.push(p);

        if (!running) {
            start();
        }
    },

    /**
     * Asynchronously watches for beacons to enter range.
     *
     * @param {Function} successCallback    The function to call each time beacon list updates
     * @param {Function} errorCallback      The function to call when there is an error getting beacon list. (OPTIONAL)
     * @param {EstimoteOptions} options     The options for EstimoteAPI calls. (OPTIONAL)
     * @return String                       The watch id that must be passed to #clearWatch to stop watching.
     */
    startRangingBeacons: function(successCallback, errorCallback, options) {
        argscheck.checkArgs('fFO', 'estimote.startRangingBeacons', arguments);
        // Default interval (10 sec)
        var frequency = (options && options.frequency && typeof options.frequency == 'number') ? options.frequency : 10000;

        // Keep reference to watch id, and report readings as often as defined in frequency
        var id = utils.createUUID();

        var p = createCallbackPair(function(){}, function(e) {
            removeListeners(p);
            errorCallback && errorCallback(e);
        });
        listeners.push(p);

        timers[id] = {
            timer:window.setInterval(function() {
                if (reply) {
                    successCallback(reply);
                }
            }, frequency),
            listeners:p
        };

        if (running) {
            // If we're already running then immediately invoke the success callback
            // but only if we have retrieved a value, sample code does not check for null ...
            if (reply) {
                successCallback(reply);
            }
        } else {
            start();
        }

        return id;
    },

    /**
     * Stops ranging beacons.
     *
     * @param {String} id       The id of the watch returned from #startRangingBeacons.
     */
    stopRangingBeacons: function(id) {
        // Stop javascript timer & remove from timer list
        if (id && timers[id]) {
            window.clearInterval(timers[id].timer);
            removeListeners(timers[id].listeners);
            delete timers[id];
        }
    }
};

module.exports = EstimoteAPI;
