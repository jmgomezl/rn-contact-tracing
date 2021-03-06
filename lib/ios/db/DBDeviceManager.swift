//
//  DBDeviceManager.swift
//  rn-contact-tracing
//
//  Created by Tzufit Lifshitz on 4/19/20.
//

import Foundation
import CoreData

class DBDeviceManager {
    
    static let shared = DBDeviceManager()
    
    func getDeviceByKey(publicKey:String) -> NSArray {
        return DBManager.shared.getEntityWithPredicate(entity: "Device", predicateKey: "publicKey", predicateValue: publicKey)
    }

    func getAllDevices() -> NSArray {
        return DBManager.shared.getAll("Device")
    }
    
    func saveNewDevice(deviceInfo: [String:Any]) {
        DBManager.shared.save(entity: "Device", attributes: deviceInfo)
    }
    
    func updateDevice() {
        let context = DBManager.shared.persistentContainer.viewContext
        do {
            try context.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func deleteAllDevices() {
        DBManager.shared.deleteAllData("Device")
    }
}
