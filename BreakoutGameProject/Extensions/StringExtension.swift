//
//  StringExtension.swift
//  BreakoutGameProject
//
//  Created by Yann Christophe Maertens on 30/12/2021.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
