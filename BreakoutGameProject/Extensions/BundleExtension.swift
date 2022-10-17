//
//  BundleExtension.swift
//  BreakoutGameProject
//
//  Created by Yann Christophe Maertens on 30/12/2021.
//

import Foundation

enum DataErrors: String, Error {
    case invalidURL = "The URL is incorrect. Try again."
    case invalidData = "The data seems to be wrong. Try again."
    case invalidJSON = "Something's wrong in your JSON. Try again."
}

extension Bundle {
    func decode<T: Decodable>(_ resource: String) throws -> T {
        guard let url = url(forResource: resource, withExtension: nil) else {
            throw DataErrors.invalidURL.localizedDescription
        }
        guard let data = try? Data(contentsOf: url) else {
            throw DataErrors.invalidData.localizedDescription
        }
        guard let decodedData = try? JSONDecoder().decode(T.self, from: data) else {
            throw DataErrors.invalidJSON.localizedDescription
        }
        return decodedData
    }
}
