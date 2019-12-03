//
//  ViewController.swift
//  GaitSec
//
//  Created by Kevin on 08/05/2019.
//  Copyright © 2019 Yingnan Sun. All rights reserved.
//

import UIKit
import WatchConnectivity
import CoreMotion
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var freqLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    
    var path = String()
    var path1 = String()
    var timestamp = Double()
    var date = Date()
    let motionManager = CMMotionManager()
    var backgroundTask = BackgroundTask()
    
    fileprivate var counterData = [Int]()
    fileprivate var session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configureWCSession()

    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        configureWCSession()
    }

    fileprivate func configureWCSession() {
        session?.delegate = self
        session?.activate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        
        self.stopButton.isEnabled = true
        self.plusButton.isEnabled = false
        self.minusButton.isEnabled = false
    }

    @IBAction func vibrateButtonDidTouch(_ sender: Any) {
        
        for _ in 1...2 {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            sleep(1)
        }
    }
    
    @IBAction func startButtonDidTouch(_ sender: Any) {
        print("start button touched")
        createCSV()
        
        //backgroundTask.startBackgroundTask()
        
        let freq = (1/Double(self.freqLabel.text!)!).roundTo(places: 2)
        var message = ["buttonStatus": "Start"]
        message["freq"] = String(freq)
        sendtoiWatch(applicationData: message as [String : AnyObject])
        self.displayLabel.text = "Collecting"
        motionManager.deviceMotionUpdateInterval = 0.01
        motionManager.accelerometerUpdateInterval = 0.01
        self.startButton.isEnabled = false
        
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
                
                self.writeToCSV(row: row, path: self.path)
            }
            motionManager.startDeviceMotionUpdates(to: OperationQueue(), withHandler: handler)
        }
    }
    
    @IBAction func plusButtonDidTouch(_ sender: Any) {
        let value = Double(self.freqLabel.text!)
        self.freqLabel.text = String(value!+50.0)
    }
    
    @IBAction func minusButtonDidTouch(_ sender: Any) {
        let value = Double(self.freqLabel.text!)
        self.freqLabel.text = String(value!-50.0)
    }
    
    @IBAction func stopButtonDidTouch(_ sender: Any) {
        var message = ["buttonStatus": "Stop"]
        message["freq"] = self.freqLabel.text!
        sendtoiWatch(applicationData: message as [String : AnyObject])
        motionManager.stopDeviceMotionUpdates()
        self.displayLabel.text = "Stopped"
        print("stop button touched")
        self.startButton.isEnabled = true
        //backgroundTask.stopBackgroundTask()
    }
    
    func createCSV() {
        self.timestamp = NSDate().timeIntervalSince1970
        self.date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        print(timestamp)
        let str = dateFormatter.string(from: self.date)
        let freq = self.freqLabel.text
        let file = "iPhoneX" + freq! + "Hz" + str + ".csv"
        let file1 = "iWatch" + freq! + "Hz" + str + ".csv"
        let writingText = "timestamp, ms, AccelX, AccelY, AccelZ, Gx, Gy, Gz, Rx, Ry, Rz, roll, pitch, yaw, Mx, My, Mz, m11, m12, m13, m21, m22, m23, m31, m32, m33, Qw, Qx, Qy, Qz\n"
        
        if let dir : NSString = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first as NSString? {
            self.path = dir.appendingPathComponent(file);
            self.path1 = dir.appendingPathComponent(file1);
            do {
                try writingText.write(toFile: self.path, atomically: true, encoding: String.Encoding.utf8)
                //try writingText.write(toFile: self.path1, atomically: true, encoding: String.Encoding.utf8)
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
    
    
    
}

//// MARK: WCSessionDelegate
extension ViewController: WCSessionDelegate {

    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
        //Dummy Implementation
    }

    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        //Dummy Implementation
    }

    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //Dummy Implementation
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {

        //Use this to update the UI instantaneously (otherwise, takes a little while)
        DispatchQueue.main.async {
            //if let Data = message["data"] as? [String] {
            //for index in 0...Data.count-1 {
            //self.writeToCSV(row: Data[index], path: self.path1)
            //}
            //}
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {

        let dir : NSString = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first as NSString?)!
        let freq = self.freqLabel.text
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        print(timestamp)
        let str = dateFormatter.string(from: self.date)
        let file1 = "iWatch_" + freq! + "Hz" + str + ".csv"
        let path = dir.appendingPathComponent(file1);
        let documentsUrl = URL(fileURLWithPath: path)
        print("documentsUrl: \(dir)")
        self.displayLabel.text = "Received"
        self.startButton.isEnabled = true
        do{
            try FileManager.default.copyItem(at: file.fileURL, to: documentsUrl)
        } catch {
            print("received, but path is wrong!")
        }
    }

    
    
    func sendtoiWatch(applicationData: [String : AnyObject]) {

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
}



extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
