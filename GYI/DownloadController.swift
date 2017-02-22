//
//  DownloadController.swift
//  YoutubeDLGUI
//
//  Created by Spencer Curtis on 12/11/16.
//  Copyright © 2016 Spencer Curtis. All rights reserved.
//

import Foundation
import Cocoa

class DownloadController {
    
    static let shared = DownloadController()
    
    weak var popover: NSPopover? {
        didSet {
            print("Popover was set")
        }
    }
    
    weak var downloadDelegate: DownloadDelegate?
    weak var processEndedDelegate: ProcessEndedDelegate?
    weak var executableUpdateDelegate: ExecutableUpdateDelegate?
    
    var applicationIsDownloading = false
    var userDidCancelDownload = false
    
    let autoUpdateYoutubeDLKey = "autoUpdateYoutubeDL"
    
    var currentTask: Process?
    
    var downloadArguments: [String: String] = [:]
    
    func parseResponseForPercentComplete(responseString: String) -> String? {
        let stringsArray = responseString.components(separatedBy: " ")
        
        
        guard let percentString = stringsArray.filter({$0.contains("%")}).first else { return nil }
        return percentString
    }
    
    func updateYoutubeDLExecutable() {
        let task = Process()
        guard let path = Bundle.main.resourcePath else { return }
        var fullPath = path
        fullPath.append("/youtube-dl")
        task.launchPath = fullPath
        
        let updateArgument = "-U"
        
        task.arguments = [updateArgument]
        
        
        let pipe = Pipe()
        task.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        
        currentTask = task
        
        var dataAvailableObserver: NSObjectProtocol!
        
        dataAvailableObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outHandle, queue: nil) {  notification -> Void in
            
            let data = outHandle.availableData
            if data.count > 0 {
                if let str = String(data: data, encoding: .utf8) {
                    print(str)
                    if str.contains("Updating") {
                        self.executableUpdateDelegate?.executableDidBeginUpdateWith(dataString: str)
                    } else if str.contains("Updated") {
                        self.executableUpdateDelegate?.executableDidFinishUpdatingWith(dataString: str)
                    }
                }
                outHandle.waitForDataInBackgroundAndNotify()
            } else {
                print("EOF on stdout from process")
                NotificationCenter.default.removeObserver(dataAvailableObserver)
            }
        }
        
        var processTerminatedObserver: NSObjectProtocol!
        
        processTerminatedObserver = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: task, queue: nil) { notification -> Void in
            print("terminated")
            NotificationCenter.default.removeObserver(processTerminatedObserver)
        }
        task.launch()
    }
    
    func downloadVideoAt(videoURL: String, outputFolder: String, account: Account? = nil) {
        
        let task = Process()
        guard let path = Bundle.main.resourcePath else { return }
        var fullPath = path
        fullPath.append("/youtube-dl")
        task.launchPath = fullPath
        
        let ignoreConfig = "--ignore-config"
        
        let output = "\(outputFolder)%(title)s.%(ext)s"
        
        //        let skipDownloadTEST = "--skip-download"
        
        var arguments = [ignoreConfig, "-o", output, "-v"]
        
        if let account = account, let username = account.username, let password = account.password {
            
            let accountArgs = ["-u", username, "-p", password]
            arguments.insert(contentsOf: accountArgs, at: 0)
        }
        
        arguments.append(videoURL)
        
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        
        currentTask = task
        
        var dataAvailableObserver: NSObjectProtocol!
        
        dataAvailableObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outHandle, queue: nil) {  notification -> Void in
            
            let data = outHandle.availableData
            if data.count > 0 {
                if let str = String(data: data, encoding: .utf8) {
                    let percentString = self.parseResponseForPercentComplete(responseString: str)
                    self.downloadDelegate?.updateProgressBarWith(percentString: percentString)
                    self.downloadDelegate?.updatePlaylistProgressBarWith(downloadString: str)
                    
                    if str.contains("has already been downloaded") { self.downloadDelegate?.userHasAlreadyDownloadedVideo() }
                    
                    if str.contains("ETA") { self.downloadDelegate?.parseResponseStringForETA(responseString: str)
                        self.downloadDelegate?.updateDownloadSpeedLabelWith(downloadString: str)
                    }
                    print(str)
                    
                }
                outHandle.waitForDataInBackgroundAndNotify()
            } else {
                print("EOF on stdout from process")
                NotificationCenter.default.removeObserver(dataAvailableObserver)
            }
        }
        
        var processTerminatedObserver: NSObjectProtocol!
        
        processTerminatedObserver = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: task, queue: nil) { notification -> Void in
            print("terminated")
            NotificationCenter.default.removeObserver(processTerminatedObserver)
            self.applicationIsDownloading = false
            NotificationCenter.default.post(name: processDidEndNotification, object: self)
        }
        task.launch()
    }
    
    func suspendCurrentTask() {
        currentTask?.suspend()
    }
    
    func resumeCurrentTask() {
        currentTask?.resume()
    }
    
    func terminateCurrentTask() {
        currentTask?.terminate()
    }
}


protocol DownloadDelegate: class {
    func updateProgressBarWith(percentString: String?)
    func updatePlaylistProgressBarWith(downloadString: String)
    func updateDownloadSpeedLabelWith(downloadString: String)
    func parseResponseStringForETA(responseString: String)
    func userHasAlreadyDownloadedVideo()
}

protocol ProcessEndedDelegate: class {
    func processDidEnd()
}

protocol ExecutableUpdateDelegate: class {
    func executableDidBeginUpdateWith(dataString: String)
    func executableDidFinishUpdatingWith(dataString: String)
}
