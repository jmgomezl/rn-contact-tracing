import React, {useEffect, useState} from 'react';
import {
  NativeEventEmitter,
  TouchableOpacity,
  Text,
  FlatList,
  View,
  StyleSheet,
} from 'react-native';
import SpecialBle from 'rn-contact-tracing';
import {requestLocationPermssion} from './src/Permissions'

const SERVICE_UUID = '00000000-0000-1000-8000-00805F9B34FB';
const PUBLIC_KEY = '12345678901234567';
const TAG = "EXAMPLE";


const App: () => React$Node = () => {

  const [scanningStatus, setScanningStatus] = useState(false);
  const [advertisingStatus, setAdvertisingStatus] = useState(false);
  const [devices, setDevices] = useState([]);

  useEffect(() => {
    const eventEmitter = new NativeEventEmitter(SpecialBle);
    eventEmitter.addListener('scanningStatus', (status) => setScanningStatus(status));
    eventEmitter.addListener('advertisingStatus', (status) => setAdvertisingStatus(status));
    eventEmitter.addListener('foundDevice', (event) => {
      console.log(event);
      _getAllDevicesFromDB();
      },
    );
    _getAllDevicesFromDB();
  }, []);



  // Start scanning for a specific serviceUUID
  function _startScan() {
    SpecialBle.startBLEScan(SERVICE_UUID);
  }

  // Stop scanning
  function _stoptScan() {
    SpecialBle.stopBLEScan();
  }

  // Start advertising with SERVICE_UUID & PUBLIC_KEY
  function _advertise() {
    SpecialBle.advertise(SERVICE_UUID,PUBLIC_KEY);
  }

  // Stop advertising
  function _stopAdvertise() {
    SpecialBle.stopAdvertise();
  }

  // in Android - start foreground service with scanning & advertising tasks
  function _startBLEService() {
    SpecialBle.startBLEService(SERVICE_UUID,PUBLIC_KEY);
  }

  // stop background tasks
  function _stopBLEService() {
    SpecialBle.stopBLEService();
  }

  // get all devices from DB
  async function _getAllDevicesFromDB() {
    SpecialBle.getAllDevices((devices) => {
        setDevices(devices)
    })
  }

  // clean all devices from DB
  function _cleanAllDevicesFromDB() {
    SpecialBle.cleanDevicesDB();
    _getAllDevicesFromDB();
  }

  // add list of public_keys
  function _setPublicKeys() {
    let publicKeys = ['12345','12346','12347','12348','12349']
    SpecialBle.setPublicKeys(publicKeys);
  }


  function _requestLocationPermission() {
    requestLocationPermssion();
  }


    return (
        <View style={styles.container}>
            <View style={styles.subContainer}>
                <Text>Scanning: {scanningStatus.toString()} </Text>
                <Text>Advertising: {advertisingStatus.toString()}</Text>
                <TouchableOpacity style={styles.btn} onPress={_requestLocationPermission}>
                    <Text>Location Permission</Text>
                </TouchableOpacity>

            </View>
            <View style={styles.subContainer}>
                <TouchableOpacity style={styles.btn} onPress={_startScan}>
                    <Text>Start Scan</Text>
                </TouchableOpacity>

                <TouchableOpacity style={styles.btn} onPress={_stoptScan}>
                    <Text>Stop Scan</Text>
                </TouchableOpacity>
            </View>
            <View style={styles.subContainer}>
                <TouchableOpacity style={styles.btn} onPress={_advertise}>
                    <Text>Start Advertise</Text>
                </TouchableOpacity>

                <TouchableOpacity style={styles.btn} onPress={_stopAdvertise}>
                    <Text>Stop Advertise</Text>
                </TouchableOpacity>
            </View>
            <View style={styles.subContainer}>
                <TouchableOpacity style={styles.btn} onPress={_startBLEService}>
                    <Text>Start BLE service</Text>
                </TouchableOpacity>

                <TouchableOpacity style={styles.btn} onPress={_stopBLEService}>
                    <Text>Stop BLE service</Text>
                </TouchableOpacity>


                <TouchableOpacity style={styles.btn} onPress={_getAllDevicesFromDB}>
                    <Text>Get all devices from DB</Text>
                </TouchableOpacity>

                <TouchableOpacity style={styles.btn} onPress={_cleanAllDevicesFromDB}>
                    <Text>Remove Devices from DB</Text>
                </TouchableOpacity>
            </View>
            <View style={styles.subContainer}>
                <TouchableOpacity style={styles.btn} onPress={_setPublicKeys}>
                    <Text>Set public Keys</Text>
                </TouchableOpacity>
            </View>




            <FlatList
                data={devices}
                style={{marginTop: 5}}
                keyExtractor={item => item.public_key}
                renderItem={({item}) => <Text style={styles.item}>
                    {item.public_key} :
                    {item.device_address} :
                    {item.device_rssi} </Text>}
            />
        </View>
    );
};


const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 10,
    marginHorizontal: 5,
  },
  subContainer: {
    flexWrap: 'wrap',
    flexDirection: 'row',
    alignItems: 'center'
  },
  btn: {
    marginHorizontal: 5,
    marginVertical:10,
    padding: 10,
    alignItems: 'center',
    backgroundColor: 'orange'
  },
  item: {
    padding: 10,
    height: 44,
  },
});

export default App;
