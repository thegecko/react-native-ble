/**
 * BluetoothLE for iOS
 *
 * @providesModule BluetoothLE
 * @flow
 */

'use strict';

var NativeBluetoothLE = require('NativeModules').BluetoothLE;

var BluetoothLE = {
    startScan: NativeBluetoothLE.startScan,
    stopScan: NativeBluetoothLE.stopScan,
    connect: NativeBluetoothLE.connect,
    disconnect: NativeBluetoothLE.disconnect,
    discoverServices: NativeBluetoothLE.discoverServices
};

module.exports = BluetoothLE;