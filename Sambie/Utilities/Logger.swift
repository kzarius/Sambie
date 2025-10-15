//
//  logger.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 5/14/25.
//

import Foundation

enum LogLevel: String {
    case debug
    case info
    case warning
    case error
}

func logger(_ message: String, level: LogLevel? = .info) {
    // Exit if debug is disabled:
    if Config.debug == false { return }
        
    // Format the date:
    let date = DateFormatter()
    date.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let formatted_date = date.string(from: Date())
    let formatted_message = "\(formatted_date) [\(level!.rawValue.uppercased())] \(message)"
    
    // Print the message to the console:
    print(formatted_message)
}

func logger(_ message: String, level: LogLevel? = .info, snapshot: MountSnapshot) {
    logger("Mount [\(snapshot.name)] - \(message)", level: level)
}
