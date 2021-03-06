//
//  BLEManager.m
//  BLETest
//
//  Created by Ran Greenberg on 07/04/2020.
//  Copyright © 2020 Facebook. All rights reserved.
//
#import "SpecialBleManager.h"
#import "rn_contact_tracing-Swift.h"


NSString *const EVENTS_FOUND_DEVICE         = @"foundDevice";
NSString *const EVENTS_SCAN_STATUS          = @"scanningStatus";
NSString *const EVENTS_ADVERTISE_STATUS     = @"advertisingStatus";

@interface SpecialBleManager ()

@property (nonatomic, strong) CBCentralManager* cbManager;
@property (nonatomic, strong) CBPeripheralManager* cbPeripheral;
@property (nonatomic, strong) CBService* service;
@property (nonatomic, strong) CBCharacteristic* characteristic;
@property (nonatomic, strong) RCTEventEmitter* eventEmitter;
@property (nonatomic, strong) NSString* scanUUIDString;
@property (nonatomic, strong) NSString* advertiseUUIDString;


@end

@implementation SpecialBleManager


#pragma mark - static methods

+ (id)sharedManager {
    static SpecialBleManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

#pragma mark - public methods

- (instancetype)init {
    if (self = [super init]) {
        self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.cbPeripheral = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

-(void)scan:(NSString *)serviceUUIDString withEventEmitter:(RCTEventEmitter*)emitter {
    if (serviceUUIDString == nil) {
        NSLog(@"Can't scan service when uuid is nil!");
        return;
    }
    self.eventEmitter = emitter;
    self.scanUUIDString = serviceUUIDString;
    CBUUID* UUID = [CBUUID UUIDWithString:serviceUUIDString];
    if (self.cbManager.state == CBManagerStatePoweredOn) {
        NSLog(@"Start scanning for %@", UUID);
        [self.cbManager scanForPeripheralsWithServices:@[UUID] options:nil];
        [self.eventEmitter sendEventWithName:EVENTS_SCAN_STATUS body:[NSNumber numberWithBool:YES]];
    }
}

- (void)stopScan:(RCTEventEmitter*)emitter {
    [self.cbManager stopScan];
    [self.eventEmitter sendEventWithName:EVENTS_SCAN_STATUS body:[NSNumber numberWithBool:NO]];
    self.scanUUIDString = nil;
}

-(void)advertise:(NSString *)serviceUUIDString withEventEmitter:(RCTEventEmitter*)emitter {
    self.advertiseUUIDString = serviceUUIDString;
    if (self.cbPeripheral.state != CBManagerStatePoweredOn) {
        return;
    }
    if (self.service && self.characteristic) {
        [self _advertise];
    } else {
        [self _setServiceAndCharacteristics:serviceUUIDString];
    }
}

- (void)stopAdvertise:(RCTEventEmitter*)emitter {
    [self.cbPeripheral stopAdvertising];
    [self.eventEmitter sendEventWithName:EVENTS_ADVERTISE_STATUS body:[NSNumber numberWithBool:NO]];
    self.advertiseUUIDString = nil;
}


#pragma mark - private methods

-(void) _setServiceAndCharacteristics:(NSString*)serviceUUIDString {
    if (serviceUUIDString == nil) {
        return;
    }
    CBUUID* UUID = [CBUUID UUIDWithString:serviceUUIDString];
    CBMutableCharacteristic* myCharacteristic = [[CBMutableCharacteristic alloc]
                                                 initWithType:UUID
                                                 properties:CBCharacteristicPropertyRead
                                                 value:nil
                                                 permissions:0];
    CBMutableService* myService = [[CBMutableService alloc] initWithType:UUID primary:YES];
    myService.characteristics = [NSArray arrayWithObject:myCharacteristic];
    self.service = myService;
    self.characteristic = myCharacteristic;
    [self.cbPeripheral addService:myService];
}

-(void) _advertise {
    if (self.cbPeripheral.state == CBManagerStatePoweredOn){
        [self.cbPeripheral startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.service.UUID]}];
        [self.eventEmitter sendEventWithName:EVENTS_ADVERTISE_STATUS body:[NSNumber numberWithBool:YES]];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"Central manager state: %d", central.state);
    [self scan:self.scanUUIDString withEventEmitter:self.eventEmitter];
    
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    NSString* name = @"";
    NSString* address = @"";
    
    NSLog(@"Discovered device with name: %@", peripheral.name);
    if (peripheral && peripheral.name != nil) {
        name = peripheral.name;
    }
    
    if (advertisementData && [advertisementData[CBAdvertisementDataServiceUUIDsKey] count] > 0) {
        address = ((CBUUID*)advertisementData[CBAdvertisementDataServiceUUIDsKey][0]).UUIDString;
    }
    
    NSDictionary* device = @{
        @"device_address": address,
        @"rssi": RSSI,
        @"firstTimestamp": [NSNumber numberWithInt:0],
        @"lastTimestamp": [NSNumber numberWithInt:0],
        @"tx": [NSNumber numberWithInt:0]
    };
//    @NSManaged public var publicKey: String?
//    @NSManaged public var device_address: String?
//    @NSManaged public var device_protocol: String?
//    @NSManaged public var rssi: Int16
//    @NSManaged public var firstTimestamp: Int16
//    @NSManaged public var lastTimestamp: Int16
//    @NSManaged public var tx: Int16
    
    [self.eventEmitter sendEventWithName:EVENTS_FOUND_DEVICE body:device];
    
    [DBClient addDevice:device];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    NSLog(@"Peripheral manager atate: %d", peripheral.state);
    [self advertise:self.advertiseUUIDString withEventEmitter:self.eventEmitter];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    } else {
        NSLog(@"Service added with UUID:%@", service.UUID);
        [self _advertise];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error {
    if (error) {
        NSLog(@"didStartAdvertising: Error: %@", error);
        return;
    }
    NSLog(@"didStartAdvertising");
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    NSLog(@"Peripheral name:%@", peripheral.name);
}
@end
