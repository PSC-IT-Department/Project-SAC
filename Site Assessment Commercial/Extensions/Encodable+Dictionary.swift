//
//  Encodable+Dictionary.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-07.
//  Copyright © 2019 chyapp.com. All rights reserved.
//
// https://stackoverflow.com/questions/45209743/how-can-i-use-swift-s-codable-to-encode-into-a-dictionary

import Foundation

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
    
        return (try? JSONSerialization.jsonObject(with: data,
                                                  options: .allowFragments
            )).flatMap { $0 as? [String: Any] }
    }
}
