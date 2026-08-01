import CloudKit
import Foundation

enum CloudSyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case synced(Date)
    case accountUnavailable
    case failed(String)
}

enum CloudSyncOutcome: Sendable {
    case uploaded(Date)
    case downloaded(StampBookData, Date)
    case unchanged(Date)
}

protocol CloudSyncing: Sendable {
    func synchronize(_ localData: StampBookData) async throws -> CloudSyncOutcome
}

enum CloudSyncError: LocalizedError {
    case accountUnavailable
    case invalidRecord

    var errorDescription: String? {
        switch self {
        case .accountUnavailable:
            L10n.string("icloud.error.account-unavailable")
        case .invalidRecord:
            L10n.string("icloud.error.invalid-data")
        }
    }
}

@MainActor
final class CloudKitSyncService: CloudSyncing {
    private static let recordType = "StampBook"
    private static let recordName = "primary-stamp-book"
    private static let payloadKey = "payload"
    private static let modifiedAtKey = "clientModifiedAt"

    private let container: CKContainer
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(container: CKContainer = .default()) {
        self.container = container

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func synchronize(_ localData: StampBookData) async throws -> CloudSyncOutcome {
        guard try await container.accountStatus() == .available else {
            throw CloudSyncError.accountUnavailable
        }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: Self.recordName)

        do {
            let record = try await database.record(for: recordID)
            return try await reconcile(localData: localData, record: record, database: database)
        } catch let error as CKError where error.code == .unknownItem {
            let record = CKRecord(recordType: Self.recordType, recordID: recordID)
            return try await upload(localData, to: record, database: database)
        } catch let error as CKError where error.code == .serverRecordChanged {
            guard let serverRecord = error.serverRecord else { throw error }
            return try await reconcile(localData: localData, record: serverRecord, database: database)
        }
    }

    private func reconcile(
        localData: StampBookData,
        record: CKRecord,
        database: CKDatabase
    ) async throws -> CloudSyncOutcome {
        guard
            let payload = record[Self.payloadKey] as? Data,
            let remoteData = try? decoder.decode(StampBookData.self, from: payload)
        else {
            throw CloudSyncError.invalidRecord
        }

        if remoteData.modifiedAt > localData.modifiedAt {
            return .downloaded(remoteData, record.modificationDate ?? .now)
        }

        if localData.modifiedAt > remoteData.modifiedAt {
            return try await upload(localData, to: record, database: database)
        }

        return .unchanged(record.modificationDate ?? .now)
    }

    private func upload(
        _ data: StampBookData,
        to record: CKRecord,
        database: CKDatabase
    ) async throws -> CloudSyncOutcome {
        record[Self.payloadKey] = try encoder.encode(data) as CKRecordValue
        record[Self.modifiedAtKey] = data.modifiedAt as CKRecordValue
        let savedRecord = try await database.save(record)
        return .uploaded(savedRecord.modificationDate ?? .now)
    }
}
