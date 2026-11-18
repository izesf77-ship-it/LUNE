import XCTest
@testable import LUNE

final class BackupAndCryptoTests: XCTestCase {

    func testEncryptDecryptRoundTrip() throws {
        let payload = Data("{\"formatVersion\":2,\"records\":[]}".utf8)
        let encrypted = try BackupCrypto.encrypt(payload: payload, password: "Пароль123")
        XCTAssertGreaterThan(encrypted.count, payload.count + 44)

        let decrypted = try BackupCrypto.decrypt(data: encrypted, password: "Пароль123")
        XCTAssertEqual(decrypted, payload)
    }

    func testWrongPasswordIsRejected() throws {
        let encrypted = try BackupCrypto.encrypt(payload: Data("secret".utf8), password: "verylongpassword")
        XCTAssertThrowsError(try BackupCrypto.decrypt(data: encrypted, password: "wrongpassword")) { error in
            guard let backupError = error as? BackupError else {
                return XCTFail("Неверный тип ошибки: \(error)")
            }
            switch backupError {
            case .wrongPasswordOrCorrupted: break
            default: XCTFail("Ожидалась ошибка пароля/целостности, получен \(backupError)")
            }
        }
    }

    func testCorruptedPayloadIsRejected() throws {
        var encrypted = try BackupCrypto.encrypt(payload: Data("secret".utf8), password: "password")
        let index = encrypted.count - 5
        encrypted[index] ^= 0xFF
        XCTAssertThrowsError(try BackupCrypto.decrypt(data: encrypted, password: "password"))
    }

    func testInvalidFormatAndVersion() throws {
        XCTAssertThrowsError(try BackupCrypto.decrypt(data: Data("not a backup".utf8), password: "x")) { error in
            guard case BackupError.invalidFormat = error else {
                return XCTFail("Ожидалась invalidFormat, получен \(error)")
            }
        }

        var data = Data("LUNEBK02".utf8)
        var version: UInt32 = 99
        withUnsafeBytes(of: version.littleEndian) { data.append(contentsOf: $0) }
        data.append(Data(repeating: 0, count: 32 + 24))
        XCTAssertThrowsError(try BackupCrypto.decrypt(data: data, password: "x")) { error in
            guard case BackupError.unsupportedVersion = error else {
                return XCTFail("Ожидалась unsupportedVersion, получен \(error)")
            }
        }
    }

    func testBackupPayloadCodable() throws {
        let payload = BackupPayload(
            formatVersion: BackupPayload.currentFormatVersion,
            appVersion: "1.0",
            schemaVersion: "1.1.0",
            createdAt: "2026-11-18T10:00:00Z",
            records: [BackupRecordDTO(entity: "DailyNote", fields: ["id": UUID().uuidString, "text": "Тест"])]
        )
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(BackupPayload.self, from: data)
        XCTAssertEqual(decoded.records.count, 1)
        XCTAssertEqual(decoded.records.first?.fields["text"], "Тест")
    }

    func testRussianPluralForms() {
        XCTAssertEqual(RussianPlural.days(1), "день")
        XCTAssertEqual(RussianPlural.days(2), "дня")
        XCTAssertEqual(RussianPlural.days(5), "дней")
        XCTAssertEqual(RussianPlural.days(21), "день")
        XCTAssertEqual(RussianPlural.days(22), "дня")
        XCTAssertEqual(RussianPlural.days(25), "дней")
        XCTAssertEqual(RussianPlural.cycles(11), "циклов")
    }
}
