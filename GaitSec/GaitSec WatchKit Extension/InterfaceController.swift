//
//  InterfaceController.swift
//  GaitSec WatchKit Extension
//
//  Created by Kevin on 08/05/2019.
//  Copyright © 2019 Yingnan Sun. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation
import CoreMotion

class InterfaceController: WKInterfaceController, WCSessionDelegate{
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //
    }
    

    
    @IBOutlet weak var displayLabel: WKInterfaceLabel!
    @IBOutlet weak var freqLabel: WKInterfaceLabel!
    
    var path = String()
    var freq = String()
    var data_collected = [String]()
    let connectivity = WKWatchConnectivityRefreshBackgroundTask();
    let motionManager = CMMotionManager()
    
    fileprivate let session : WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    override init() {
        super.init()
        
        session?.delegate = self
        session?.activate()
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func startMotionData(){
        if motionManager.isDeviceMotionAvailable {
            let handler: CMDeviceMotionHandler = {(motion: CMDeviceMotion?, error: Error?) -> Void in
                
                let timestamp = NSDate().timeIntervalSince1970
                let first_part=floor(timestamp)
                let second_part=timestamp-first_part
                var row = String(first_part)+","+String(format: "%.6f", second_part)+","
                row += String(format: "%.6f", motion!.userAcceleration.x)+","+String(format: "%.6f", motion!.userAcceleration.y)+","+String(format: "%.6f", motion!.userAcceleration.z)+","
                row += String(format: "%.6f", motion!.gravity.x)+","+String(format: "%.6f", motion!.gravity.y)+","+String(format: "%.6f", motion!.gravity.z)+","
                row += String(format: "%.6f", motion!.rotationRate.x)+","+String(format: "%.6f", motion!.rotationRate.y)+","+String(format: "%.6f", motion!.rotationRate.z)+","
                row += String(format: "%.6f", motion!.attitude.roll)+","+String(format: "%.6f", motion!.attitude.pitch)+","+String(format: "%.6f", motion!.attitude.yaw)+","
                row += String(format: "%.6f", motion!.magneticField.field.x)+","+String(format: "%.6f", motion!.magneticField.field.y)+","+String(format: "%.6f", motion!.magneticField.field.z)+","
                row += String(format: "%.6f", motion!.attitude.rotationMatrix.m11)+","+String(format: "%.6f", motion!.attitude.rotationMatrix.m12)+","+String(format: "%.6f", motion!.attitude.rotationMatrix.m13)+","
                row += String(format: "%.6f", motion!.attitude.rotationMatrix.m21)+","+String(format: "%.6f", motion!.attitude.rotationMatrix.m22)+","+String(format: "%.6f", motion!.attitude.rotationMatrix.m23)+","
                row += String(format: "%.6f", motion!.attitude.rotationMatrix.m31)+","+String(format: "%.6f", motion!.attitude.rotationMatrix.m32)+","+String(format: "%.6f", motion!.attitude.rotationMatrix.m33)+","
                row += String(format: "%.6f", motion!.attitude.quaternion.w)+","+String(format: "%.6f", motion!.attitude.quaternion.x)+","+String(format: "%.6f", motion!.attitude.quaternion.y)+","+String(format: "%.6f", motion!.attitude.quaternion.z)+"\n"
                
                //self.data_collected.append(row)
                self.writeToCSV(row: row, path: self.path)
                //let applicationData = ["data" : row]
                //self.sendtoiPhone(applicationData: applicationData as [String : AnyObject])
                
            }
            motionManager.startDeviceMotionUpdates(to: OperationQueue(), withHandler: handler)
        }
        else {
            displayLabel.setText("not available")
        }
    }
    
    func sendtoiPhone(applicationData: [String : AnyObject]) {
        // The paired iPhone has to be connected via Bluetooth.
        if (session?.isReachable)! {
            session?.sendMessage(applicationData,
                                 replyHandler: { replyData in
                                    // handle reply from iPhone app here
                                    print(replyData)
            }, errorHandler: { error in
                // catch any errors here
                print(error)
            })
        } else {
            // when the iPhone is not connected via Bluetooth
        }
    }
    
    func createCSV() {
        let timestamp = NSDate().timeIntervalSince1970
        print(timestamp)
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let str = dateFormatter.string(from: date)
        let file = "iWatch100Hz" + str + ".csv"
        let writingText = "timestamp, ms, AccelX, AccelY, AccelZ, Gx, Gy, Gz, Rx, Ry, Rz, roll, pitch, yaw, Mx, My, Mz, m11, m12, m13, m21, m22, m23, m31, m32, m33, Qw, Qx, Qy, Qz\n"
        
        if let dir : NSString = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first as NSString? {
            self.path = dir.appendingPathComponent(file);
            do {
                try writingText.write(toFile: self.path, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                /* error handling here */
            }
            
        }
    }
    
    func writeToCSV(row: String, path: String) {
        
        let data = row.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        
        if let fileHandle = FileHandle(forWritingAtPath: path){
            fileHandle.seekToEndOfFile()
            fileHandle.write(data!)
            fileHandle.closeFile()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        print(message)
        
        //Use this to update the UI instantaneously (otherwise, takes a little while)
        DispatchQueue.main.async {
            let buttonStatus = message["buttonStatus"] as? String
            self.freq = (message["freq"] as? String)!
            
            self.motionManager.deviceMotionUpdateInterval = 0.01
            self.motionManager.accelerometerUpdateInterval = 0.01
            //self.freqLabel.setText(String(1/Double(self.freq)!)+"Hz")
            
            if buttonStatus=="Start" {
                self.displayLabel.setText("Collecting")
                self.createCSV()
                self.startMotionData()
            }
            if (buttonStatus=="Stop") {
                self.displayLabel.setText("Stopped")
                self.motionManager.stopDeviceMotionUpdates()
                
                //let applicationData = ["data": self.data_collected]
                let fileUrl = URL(fileURLWithPath: self.path)
                self.session?.transferFile(fileUrl, metadata: nil)
                //self.sendtoiPhone(applicationData: applicationData as [String : AnyObject])
            }
        }
    }
    
    
}
