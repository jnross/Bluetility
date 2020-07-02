//
//  LogUtils.swift
//  Bluetility
//
//  Created by Joseph Ross on 7/1/20.
//  Copyright © 2020 Joseph Ross. All rights reserved.
//

import Foundation

func log(_ message:String, file:String = #file, line:Int = #line, functionName:String = #function) {
    NSLog("\(file):\(line) (\(functionName)): \(message)\n")
}
