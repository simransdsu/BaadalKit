//
//  BaadalError.swift
//  iList
//
//  Created by Simran Preet Singh Narang on 2022-02-04.
//

import Foundation


public enum BaadalError: Error {
    case failedToSave
    case failedToFetch
    case failedToDelete
    case notAuthenticated
}
