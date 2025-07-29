import Foundation

// MARK: - String Unicode Extensions

extension String {
    /// 將 Unicode escape sequences (\uXXXX) 轉換為正常字元
    /// 用於處理從 JSON 或 API 回應中收到的 Unicode 轉義序列
    /// 
    /// Example:
    /// ```swift
    /// let escaped = "\\u4e2d\\u6587"  // Unicode for "中文"
    /// let decoded = escaped.decodedUnicode  // Returns "中文"
    /// ```
    var decodedUnicode: String {
        // 將字串包裝成 JSON 格式以便 JSONDecoder 處理
        let jsonWrapped = "\"\(self)\""
        
        // 嘗試使用 JSONDecoder 解碼 Unicode escape sequences
        if let data = jsonWrapped.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(String.self, from: data) {
            return decoded
        }
        
        // 如果解碼失敗，返回原始字串
        return self
    }
    
    /// 將字串編碼為 Unicode escape sequences
    /// 與 decodedUnicode 相反的操作
    /// 
    /// Example:
    /// ```swift
    /// let chinese = "中文"
    /// let encoded = chinese.unicodeEscaped  // Returns "\\u4e2d\\u6587"
    /// ```
    var unicodeEscaped: String {
        var result = ""
        for scalar in self.unicodeScalars {
            if scalar.isASCII {
                result += String(scalar)
            } else {
                result += String(format: "\\u%04x", scalar.value)
            }
        }
        return result
    }
    
    /// 檢查字串是否包含 Unicode escape sequences
    /// 
    /// Example:
    /// ```swift
    /// let text = "Hello \\u4e2d\\u6587"
    /// print(text.containsUnicodeEscapes)  // true
    /// ```
    var containsUnicodeEscapes: Bool {
        return self.range(of: "\\\\u[0-9a-fA-F]{4}", options: .regularExpression) != nil
    }
}
