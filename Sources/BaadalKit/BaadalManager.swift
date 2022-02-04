//
//  BaadalManager.swift
//  iList
//
//  Created by Simran Preet Singh Narang on 2022-02-04.
//

import Foundation
import CloudKit

public protocol RecordIDItem {
    var recordId: CKRecord.ID { get }
}


public struct BaadalManager {
    
    private let database: CKDatabase
    
    init(identifier: String? = nil) {
        if let identifier = identifier {
            database = CKContainer(identifier: identifier).privateCloudDatabase
            return
        }
        
        database = CKContainer.default().privateCloudDatabase
    }
    
    @available(macOS 10.15.0, *)
    @available(iOS 13.0.0, *)
    func save(record: CKRecord) async throws -> CKRecord {
 
        return try await withCheckedThrowingContinuation { continutation in
            database.save(record) { record, error in
                if let record = record, error == nil {
                    print("✅ Saved successfully in iCloud.")
                    return continutation.resume(returning: record)
                }
                
                print("❌ Failed to save with error: \(String(describing: error))")
                return continutation.resume(throwing: BaadalError.failedToSave)
            }
        }
    }
    
    @available(macOS 10.15.0, *)
    @available(iOS 13.0.0, *)
    func delete(_ item: RecordIDItem) async throws -> CKRecord.ID {
        return try await withCheckedThrowingContinuation { continutation in
            database.delete(withRecordID: item.recordId) { id, error in
                if let id = id, error == nil {
                    print("✅ Deleted successfully from iCloud.")
                    return continutation.resume(returning: id)
                }
                
                return continutation.resume(throwing: BaadalError.failedToDelete)
            }
        }
    }
    
    @available(macOS 10.15.0, *)
    @available(iOS 13.0.0, *)
    func fetch(recordType: String) async throws -> [CKRecord]{
        let query = CKQuery(recordType: recordType,
                            predicate: NSPredicate(value: true))
        
        var records: [CKRecord] = []
        
        return try await withCheckedThrowingContinuation { continutation in
            if #available(macOS 12.0, *) {
                if #available(iOS 15.0, *) {
                    database.fetch(withQuery: query) { result in
                        
                        switch(result) {
                        case .success((let matchResults,_)):
                            for matchResult in matchResults {
                                let x = matchResult.1
                                switch(x) {
                                case .success(let record):
                                    records.append(record)
                                    
                                case .failure(let err):
                                    print("❌ Failed to fetch matchedResult from iCloud with error \(err)")
                                    return continutation.resume(throwing: BaadalError.failedToFetch)
                                }
                            }
                            break
                            
                        case .failure(let error):
                            print("❌ Failed to fetch records from iCloud with error \(error)")
                            if let ckError = error as? CKError,
                               ckError.code == .notAuthenticated {
                                return continutation.resume(throwing: BaadalError.notAuthenticated)
                            } else {
                                return continutation.resume(throwing: BaadalError.failedToFetch)
                            }
                        }
                        
                        return continutation.resume(returning: records)
                    }
                }
            }
        }
    }
}
