//
//  ServerResponse.swift
//  Noze.io / Macro
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016-2020 ZeeZide GmbH. All rights reserved.
//

import enum  NIOHTTP1.HTTPResponseStatus
import class http.ServerResponse

public extension ServerResponse {
  // TODO: Would be cool: send(stream: GReadableStream), then stream.pipe(self)
  
  
  // MARK: - Status Handling
  
  /// Set the HTTP status, returns self
  ///
  /// Example:
  ///
  ///     res.status(404).send("didn't find it")
  ///
  @discardableResult
  @inlinable
  func status(_ code: Int) -> Self {
    statusCode = code
    return self
  }
  
  /// Set the HTTP status code and send the status description as the body.
  ///
  @inlinable
  func sendStatus(_ code: Int) {
    let status = HTTPResponseStatus(statusCode: code)
    statusCode = code
    send(status.reasonPhrase)
  }
  
  
  // MARK: - Sending Content
 
  @inlinable
  func send(_ string: String) {
    if canAssignContentType {
      var ctype = string.hasPrefix("<html") ? "text/html" : "text/plain"
      ctype += "; charset=utf-8"
      setHeader("Content-Type", ctype)
    }
    
    write(string)
    end()
  }
  
  @inlinable
  func send(_ data: [ UInt8 ]) {
    if canAssignContentType {
      setHeader("Content-Type", "application/octet-stream")
    }
    
    write(data)
    end()
  }
  
  @inlinable
  func send<T: Encodable>(_ object: T) { json(object) }
  
  @inlinable
  var canAssignContentType : Bool {
    return !headersSent && getHeader("Content-Type") == nil
  }
  
  @inlinable
  func format(handlers: [ String : () -> () ]) {
    var defaultHandler : (() -> ())? = nil
    
    guard let rq = request else {
      handlers["default"]?()
      return
    }
    
    for ( key, handler ) in handlers {
      guard key != "default" else { defaultHandler = handler; continue }
      
      if let mimeType = rq.accepts(key) {
        if canAssignContentType {
          setHeader("Content-Type", mimeType)
        }
        handler()
        return
      }
    }
    if let cb = defaultHandler { cb() }
  }
  
  
  // MARK: - Header Accessor Renames
  
  @inlinable
  func get(_ header: String) -> Any? {
    return getHeader(header)
  }
  @inlinable
  func set(_ header: String, _ value: Any?) {
    if let v = value { setHeader(header, v) }
    else             { removeHeader(header) }
  }
}
