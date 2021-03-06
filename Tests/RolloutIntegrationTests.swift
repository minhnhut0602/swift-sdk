import XCTest
import ConfigCat

class RolloutIntegrationTests: XCTestCase {
    var matrixData: Data?
    let client: ConfigCatClient = ConfigCatClient(apiKey: "PKDVCLf-Hq-h-kCzMp-L7Q/psuH7BGHoUmdONrzzUOY7A")
    
    override func setUp() {
        super.setUp()
        let testBundle = Bundle(for: type(of: self))
        if let url = testBundle.url(forResource: "testmatrix", withExtension: "csv") {
            matrixData = try? Data(contentsOf: url)
        }
    }
    
    func testRolloutMatrix() throws {
        guard let matrixData = matrixData, let content = String(bytes: matrixData, encoding: .utf8) else {
            XCTFail()
            return
        }
            
        let rows = content.components(separatedBy: "\n")
            .map{ row in row.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)}
        
        let settingKeys = rows[0].components(separatedBy: ";")
            .map{ key in key.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)}
            .skip(count: 4)
        
        var errors: [String] = []
        for i in 1..<rows.count {
            let testObjects = rows[i].components(separatedBy: ";")
                .map{ key in key.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)}
            
            if testObjects.count == 1 {
                continue
            }
            
            var user: User? = nil
            if !testObjects[0].isEmpty && testObjects[0] != "##null##" {
                
                var email = ""
                var country = ""
                
                let identifier = testObjects[0]
                
                if !testObjects[1].isEmpty && testObjects[1] != "##null##" {
                    email = testObjects[1]
                }
                
                if !testObjects[2].isEmpty && testObjects[2] != "##null##" {
                    country = testObjects[2]
                }
                
                var custom: [String: String] = [:]
                if !testObjects[3].isEmpty && testObjects[3] != "##null##" {
                    custom["Custom1"] = testObjects[3]
                }
                
                user = User(identifier: identifier, email: email, country: country, custom: custom)
            }
            
            var i: Int = 0
            for settingKey in settingKeys {
                if let anyValue: Any = client.getValue(for: settingKey, defaultValue: nil, user: user) {
                    if let boolValue = anyValue as? Bool,
                        let expectedValue = Bool(testObjects[i + 4].lowercased()) {
                        if boolValue != expectedValue {
                            errors.append(String(format: "Identifier: %@, Key: %@. Expected: %@, Result: %@", testObjects[0], settingKey, expectedValue, boolValue))
                        }
                        
                        i += 1
                        continue
                    }
                    
                    if let intValue = anyValue as? Int,
                        let expectedValue = Int(testObjects[i + 4]) {
                        if intValue != expectedValue {
                            errors.append(String(format: "Identifier: %@, Key: %@. Expected: %@, Result: %@", testObjects[0], settingKey, expectedValue, intValue))
                        }
                        
                        i += 1
                        continue
                    }
                    
                    if let doubleValue = anyValue as? Double,
                        let expectedValue = Double(testObjects[i + 4]) {
                        if doubleValue != expectedValue {
                            errors.append(String(format: "Identifier: %@, Key: %@. Expected: %@, Result: %@", testObjects[0], settingKey, expectedValue, doubleValue))
                        }
                        
                        i += 1
                        continue
                    }
                    
                    if let stringValue = anyValue as? String {
                        let expectedValue = testObjects[i + 4]
                        if stringValue != expectedValue {
                            errors.append(String(format: "Identifier: %@, Key: %@. Expected: %@, Result: %@", testObjects[0], settingKey, expectedValue, stringValue))
                        }
                        
                        i += 1
                        continue
                    }
                }
                    
                XCTFail()
            }
        }
            
        XCTAssertEqual(0, errors.count)
        return
    }
}

extension Array {
    func skip(count:Int) -> [Element] { return [Element](self[count..<self.count]) }
}
