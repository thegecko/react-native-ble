#import "BluetoothLE.h"
#import "RCTConvert.h"
#import "RCTLog.h"

@interface BluetoothLE() <CBCentralManagerDelegate, CBPeripheralDelegate>

@end

@implementation BluetoothLE {
    CBCentralManager *_manager;
    NSMutableDictionary *_callbacks;
    NSMutableDictionary *_peripherals;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (instancetype)init {
    if ((self = [super init])) {
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
        _callbacks = [NSMutableDictionary dictionary]
        _peripherals = [NSMutableDictionary dictionary];
    }
    return self;
}

RCT_EXPORT_METHOD(startScan:(RCTResponseSenderBlock)foundCB) {
    [_callbacks setObject:foundCB forKey:@"foundCB"];
    [_manager scanForPeripheralsWithServices:nil options:nil];
}

RCT_EXPORT_METHOD(stopScan) {
    [_callbacks removeObjectForKey:@"foundCB"];
    [_manager stopScan];
}

RCT_EXPORT_METHOD(connect:(NSString *)peripheralUuid withCallback:(RCTResponseSenderBlock)connectCB andCallback:(RCTResponseSenderBlock)disconnectCB) {
    CBPeripheral *peripheral = [_peripherals objectForKey:peripheralUuid];

    if (peripheral) {
        [_callbacks setObject:connectCB forKey:@"connectCB"];
        [_callbacks setObject:disconnectCB forKey:@"disconnectCB"];
        [_manager connectPeripheral:peripheral options:nil];
    }
}

RCT_EXPORT_METHOD(disconnect:(NSString *)peripheralUuid) {
    CBPeripheral *peripheral = [_peripherals objectForKey:peripheralUuid];

    if (peripheral) {
        [_manager cancelPeripheralConnection:peripheral];
        // maybe call callback here if it doesn't get called below
    }
}

RCT_EXPORT_METHOD(discoverServices:(NSString *)peripheralUuid withCallback:(RCTResponseSenderBlock)discoverCB) {
    CBPeripheral *peripheral = [_peripherals objectForKey:peripheralUuid];

    if (peripheral) {
        [_callbacks setObject:discoverCB forKey:@"discoverCB"];
        [peripheral discoverServices:nil];
    }
}

-(void)discoverCharacteristics:(CBPeripheral *)peripheral forService:(CBService *)service {
    [peripheral discoverCharacteristics:nil forService:service];
}

-(void)discoverDescriptors:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic {
    [peripheral discoverDescriptorsForCharacteristic:characteristic];
}

-(void)readValue:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic {
    [peripheral readValueForCharacteristic:characteristic];
}

-(void)writeValue:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic withValue: (NSData *)data {
    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

-(void)writeValueWithResponse:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic withValue: (NSData *)data {
    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
}

-(void)enableNotify:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic {
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}

-(void)disableNotify:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic {
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

-(void)readValue:(CBPeripheral *)peripheral forDescriptor:(CBDescriptor *)descriptor {
    [peripheral readValueForDescriptor:descriptor];
}

-(void)writeValue:(CBPeripheral *)peripheral forDescriptor:(CBDescriptor *)descriptor withValue: (NSData *)data {
    [peripheral writeValue:data forDescriptor:descriptor];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        RCTLogError(@"Bluetooth device not on");
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {

}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {

}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    RCTLog(@"Discovered %@", peripheral.name);
    [_peripherals setObject: peripheral forKey: peripheral.identifier.UUIDString];

    RCTResponseSenderBlock callback = [_callbacks objectForKey:@"foundCB"];
    if (callback) {
        callback(@[{
            @"uuid": peripheral.identifier.UUIDString,
            @"name": peripheral.name,
            @"advertisementData": advertisementDatas
        }]);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;

    RCTResponseSenderBlock callback = [_callbacks objectForKey:@"connectCB"];
    if (callback) {
        callback(@[]);
    }

    [_callbacks removeObjectForKey:@"connectCB"];
    [_callbacks removeObjectForKey:@"disconnectCB"];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    RCTResponseSenderBlock callback = [_callbacks objectForKey:@"disconnectCB"];
    if (callback) {
        callback(@[]);
    }

    [_callbacks removeObjectForKey:@"connectCB"];
    [_callbacks removeObjectForKey:@"disconnectCB"];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        RCTLogError(@"Error connecting to peripheral: %@", [error localizedDescription]);
    }
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    RCTResponseSenderBlock callback = [_callbacks objectForKey:@"discoverCB"];
    if (callback) {
        NSMutableDictionary *services = @{};

        for (CBService *service in peripheral.services) {
            services[service.UUID.UUIDString] = @{
                @"uuid": service.UUID.UUIDString,
                @"primary": service.isPrimary
            };
        }

        callback(@[services]);
    }

    [_callbacks removeObjectForKey:@"discoverCB"];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // for (CBCharacteristic *characteristic in service.characteristics) {
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    // for (CBDescriptor *descriptor in characteristic.descriptors) {
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    // NSData *data = characteristic.value;
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        RCTLogError(@"Error writing characteristic value: %@", [error localizedDescription]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        RCTLogError(@"Error changing notification state: %@", [error localizedDescription]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    // NSData *data = descriptor.value;
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    if (error) {
        RCTLogError(@"Error writing descriptor value: %@", [error localizedDescription]);
    }
}

@end