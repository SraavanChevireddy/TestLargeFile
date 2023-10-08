//
//  Dateformatter+Ext.swift
//  FirstCopy
//
//  Created by Sraavan Chevireddy on 08/10/23.
//

import Foundation

extension Date {
    var convert: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}
