//
//  Array+Extension.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 5/23/20.
//  Copyright © 2020 Josh Holtz. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size:Int) -> [[Element]] {
        
        var chunkedArray = [[Element]]()
        
        for index in 0...self.count {
            if index % size == 0 && index != 0 {
                chunkedArray.append(Array(self[(index - size)..<index]))
            } else if(index == self.count && self.count > 0) {
                chunkedArray.append(Array(self[index - 1..<index]))
            }
        }
        
        return chunkedArray
    }
}
