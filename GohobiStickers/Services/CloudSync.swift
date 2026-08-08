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
    private static let containerIdentifier = "iCloud.com.nakaokarei.GohobiStickers.7ZJJ7KR6WA"
    private static let recordType = "StampBook"
    private static let recordName = "primary-stamp-book"
    private static let payloadKey = "payload"
    private static let modifiedAtKey = "clientModifiedAt"
    private static let imageRecordType = "StampImage"
    private static let imageAssetKey = "asset"
    private static let imageRevisionKey = "revision"

    private let container: CKContainer
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let imageStore: StampImageStore

    init(container: CKContainer? = nil, imageStore: StampImageStore? = nil) {
        self.container = container ?? CKContainer(identifier: Self.containerIdentifier)
        self.imageStore = imageStore ?? StampImageStore()

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
            let record: CKRecord
            do {
                record = try await database.record(for: recordID)
            } catch {
                guard Self.cloudErrorCode(for: error) == .unknownItem else { throw error }
                let newRecord = CKRecord(recordType: Self.recordType, recordID: recordID)
                return try await upload(
                    localData,
                    to: newRecord,
                    previousData: nil,
                    database: database
                )
            }
            return try await reconcile(localData: localData, record: record, database: database)
        } catch {
            if Self.cloudErrorCode(for: error) == .serverRecordChanged,
               let serverRecord = Self.serverRecord(from: error) {
                return try await reconcile(localData: localData, record: serverRecord, database: database)
            }
            throw error
        }
    }

    private static func cloudErrorCode(for error: Error) -> CKError.Code? {
        if let cloudError = error as? CKError {
            return cloudError.code
        }

        let cocoaError = error as NSError
        guard cocoaError.domain == CKErrorDomain else { return nil }
        return CKError.Code(rawValue: cocoaError.code)
    }

    private static func serverRecord(from error: Error) -> CKRecord? {
        if let cloudError = error as? CKError, let record = cloudError.serverRecord {
            return record
        }
        return (error as NSError).userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord
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
            try await downloadMissingImages(for: remoteData, database: database)
            return .downloaded(remoteData, record.modificationDate ?? .now)
        }

        if localData.modifiedAt > remoteData.modifiedAt {
            return try await upload(
                localData,
                to: record,
                previousData: remoteData,
                database: database
            )
        }

        try await downloadMissingImages(for: remoteData, database: database)
        return .unchanged(record.modificationDate ?? .now)
    }

    private func upload(
        _ data: StampBookData,
        to record: CKRecord,
        previousData: StampBookData?,
        database: CKDatabase
    ) async throws -> CloudSyncOutcome {
        try await uploadImages(for: data, database: database)
        record[Self.payloadKey] = try encoder.encode(data) as CKRecordValue
        record[Self.modifiedAtKey] = data.modifiedAt as CKRecordValue
        let savedRecord = try await database.save(record)
        if let previousData {
            await deleteObsoleteImages(previousData: previousData, currentData: data, database: database)
        }
        return .uploaded(savedRecord.modificationDate ?? .now)
    }

    private func uploadImages(for data: StampBookData, database: CKDatabase) async throws {
        for reference in Self.imageReferences(in: data) {
            let recordID = Self.imageRecordID(for: reference)
            let imageRecord: CKRecord
            do {
                let existing = try await database.record(for: recordID)
                if existing[Self.imageRevisionKey] as? String == reference.revision.uuidString.lowercased(),
                   existing[Self.imageAssetKey] is CKAsset {
                    continue
                }
                imageRecord = existing
            } catch {
                guard Self.cloudErrorCode(for: error) == .unknownItem else { throw error }
                imageRecord = CKRecord(recordType: Self.imageRecordType, recordID: recordID)
            }

            let fileURL = imageStore.fileURL(entryID: reference.entryID, revision: reference.revision)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw CloudSyncError.invalidRecord
            }
            imageRecord[Self.imageRevisionKey] = reference.revision.uuidString.lowercased() as CKRecordValue
            imageRecord[Self.imageAssetKey] = CKAsset(fileURL: fileURL)
            _ = try await database.save(imageRecord)
        }
    }

    private func downloadMissingImages(for data: StampBookData, database: CKDatabase) async throws {
        for reference in Self.imageReferences(in: data) where !imageStore.contains(
            entryID: reference.entryID,
            revision: reference.revision
        ) {
            let record: CKRecord
            do {
                record = try await database.record(for: Self.imageRecordID(for: reference))
            } catch {
                if Self.cloudErrorCode(for: error) == .unknownItem {
                    throw CloudSyncError.invalidRecord
                }
                throw error
            }
            guard
                record[Self.imageRevisionKey] as? String == reference.revision.uuidString.lowercased(),
                let asset = record[Self.imageAssetKey] as? CKAsset,
                let assetURL = asset.fileURL,
                let assetData = try? Data(contentsOf: assetURL)
            else {
                throw CloudSyncError.invalidRecord
            }
            try imageStore.saveNormalizedData(
                assetData,
                entryID: reference.entryID,
                revision: reference.revision
            )
        }
    }

    private func deleteObsoleteImages(
        previousData: StampBookData,
        currentData: StampBookData,
        database: CKDatabase
    ) async {
        let previousReferences = Dictionary(
            uniqueKeysWithValues: Self.imageReferences(in: previousData).map { ($0.entryID, $0) }
        )
        let currentEntryIDs = Set(Self.imageReferences(in: currentData).map(\.entryID))
        for reference in previousReferences.values where !currentEntryIDs.contains(reference.entryID) {
            do {
                _ = try await database.deleteRecord(withID: Self.imageRecordID(for: reference))
            } catch {
                guard Self.cloudErrorCode(for: error) == .unknownItem else { continue }
            }
        }
    }

    private struct ImageReference: Hashable {
        let entryID: UUID
        let revision: UUID
    }

    private static func imageReferences(in data: StampBookData) -> [ImageReference] {
        data.roads.flatMap(\.entries).compactMap { entry in
            entry.imageRevision.map { ImageReference(entryID: entry.id, revision: $0) }
        }
    }

    private static func imageRecordID(for reference: ImageReference) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "stamp-image-\(reference.entryID.uuidString.lowercased())"
        )
    }
}
