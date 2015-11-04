//
//  Session.swift
//  GeneralAPI
//
//  Created by 王义川 on 15/7/16.
//  Copyright © 2015年 肇庆市创威发展有限公司. All rights reserved.
//

import Foundation
import API

public class Session {
    public let cipher: Cipher
    public let authenticator: Authenticator
//    public private(set) var expiredTime: NSDate
//    public var isExpired:Bool {
//        return expiredTime.timeIntervalSince1970 <= ServerTime.sharedInstance.time.timeIntervalSince1970
//    }
    public var storage: [String:Any] = [:]
    
    public init(cipher: Cipher, authenticator: Authenticator) {
        self.cipher = cipher
        self.authenticator = authenticator
    }
}

public let SessionDidChangeNotification = "SessionDidChangeNotification"
extension Session {
    public private(set) static var currentSession: Session? {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(SessionDidChangeNotification, object: nil)
        }
    }
    
    private static let lock = NSRecursiveLock()
    private static var disposable: (() -> Void)?
    
    public static func setCurrentSession(session: Session, expiredTime: NSDate) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        currentSession = session
        scheduleExpired(expiredTime)
    }
    
    public static func clearCurrentSession() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        currentSession = nil
        disposeSchedule()
    }
    
    public static func updateSessionExpiredTime(expiredTime: NSDate) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if currentSession != nil  {
            scheduleExpired(expiredTime)
        }
    }
    
    private static func disposeSchedule() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        disposable?()
        disposable = nil
    }
    
    private static func scheduleExpired(expiredTime: NSDate) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        disposeSchedule()
        
        let disposed = Obejct(false)
        disposable = {
            disposed.value = true
        }
        
        dispatch_after(wallTimeWithDate(expiredTime), dispatch_get_main_queue()) {
            lock.lock()
            defer {
                lock.unlock()
            }
            
            if !disposed.value {
                clearCurrentSession()
            }
        }
    }
}

private class Obejct<Value> {
    var value: Value
    
    init(_ value: Value) {
        self.value = value
    }
}

private func wallTimeWithDate(date: NSDate) -> dispatch_time_t {
    var seconds = 0.0
    let frac = modf(date.timeIntervalSince1970, &seconds)
    
    let nsec: Double = frac * Double(NSEC_PER_SEC)
    var walltime = timespec(tv_sec: CLong(seconds), tv_nsec: CLong(nsec))
    
    return dispatch_walltime(&walltime, 0)
}