/// A text steganography utility that hides secret text inside visible text
/// using invisible Unicode characters.
public enum TextWatermark {

    // MARK: - Public API

    /// Encode secret text as invisible characters appended to visible text.
    /// - Parameters:
    ///   - visibleText: The text that remains readable.
    ///   - secretText: The text to hide.
    ///   - suffix: Optional visible string appended after the invisible payload (default: none).
    /// - Returns: The combined string.
    public static func encode(
        visibleText: String,
        secretText: String,
        suffix: String = ""
    ) -> String {
        guard !secretText.isEmpty else { return visibleText + suffix }

        var result = visibleText

        // Start-of-payload marker: three consecutive U+2060
        result += payloadMarker

        // Encode each UTF-8 byte as two invisible characters (high nibble, low nibble)
        for byte in secretText.utf8 {
            let hi = Int(byte >> 4)
            let lo = Int(byte & 0x0F)
            result.unicodeScalars.append(nibbleToInvisible[hi])
            result.unicodeScalars.append(nibbleToInvisible[lo])
        }

        result += suffix
        return result
    }

    /// Decode hidden secret text from a watermarked string.
    /// - Parameter watermarkedText: The string that may contain a hidden payload.
    /// - Returns: The decoded secret text, or `nil` if no watermark is found.
    public static func decode(from watermarkedText: String) -> String? {
        let scalars = watermarkedText.unicodeScalars

        // Find the start marker: three consecutive U+2060
        var markerStart: String.UnicodeScalarView.Index?
        var consecutiveMarkers = 0
        for index in scalars.indices {
            if scalars[index] == markerScalar {
                consecutiveMarkers += 1
                if consecutiveMarkers == 3 {
                    markerStart = scalars.index(after: index)
                    break
                }
            } else {
                consecutiveMarkers = 0
            }
        }

        guard let payloadStart = markerStart else { return nil }

        // Collect nibble values from the payload
        var nibbles: [UInt8] = []
        for index in scalars[payloadStart...].indices {
            let scalar = scalars[index]
            if let nibble = invisibleToNibble[scalar] {
                nibbles.append(nibble)
            }
            // Non-invisible characters (e.g. suffix) are simply skipped
        }

        guard !nibbles.isEmpty else { return nil }

        // Pair nibbles into bytes (drop trailing odd nibble)
        let byteCount = nibbles.count / 2
        var bytes: [UInt8] = []
        bytes.reserveCapacity(byteCount)
        for i in 0..<byteCount {
            bytes.append((nibbles[i * 2] << 4) | nibbles[i * 2 + 1])
        }

        // String(decoding:as:) replaces invalid UTF-8 with U+FFFD;
        // verify the round-trip to return nil for corrupted data instead.
        let decoded = String(decoding: bytes, as: UTF8.self)
        guard decoded.utf8.elementsEqual(bytes) else { return nil }
        return decoded
    }

    /// The invisible start-of-payload marker: three consecutive U+2060 (WORD JOINER).
    public static let payloadMarker = String(repeating: String(markerScalar), count: 3)

    // MARK: - Private

    /// U+2060 WORD JOINER — used as the start-of-payload marker (×3).
    private static let markerScalar: Unicode.Scalar = "\u{2060}"

    /// Maps nibble values (0–15) to invisible Unicode scalars.
    private static let nibbleToInvisible: [Unicode.Scalar] = [
        "\u{206C}", // 0  INHIBIT ARABIC FORM SHAPING
        "\u{00AD}", // 1  SOFT HYPHEN
        "\u{200E}", // 2  LEFT-TO-RIGHT MARK
        "\u{2068}", // 3  FIRST STRONG ISOLATE
        "\u{202C}", // 4  POP DIRECTIONAL FORMATTING
        "\u{2069}", // 5  POP DIRECTIONAL ISOLATE
        "\u{206A}", // 6  INHIBIT SYMMETRIC SWAPPING
        "\u{200B}", // 7  ZERO-WIDTH SPACE
        "\u{200C}", // 8  ZERO-WIDTH NON-JOINER
        "\u{200D}", // 9  ZERO-WIDTH JOINER
        "\u{206D}", // a  ACTIVATE ARABIC FORM SHAPING
        "\u{206F}", // b  NOMINAL DIGIT SHAPES
        "\u{2062}", // c  INVISIBLE TIMES
        "\u{2063}", // d  INVISIBLE SEPARATOR
        "\u{2064}", // e  INVISIBLE PLUS
        "\u{206E}", // f  NATIONAL DIGIT SHAPES
    ]

    /// Reverse lookup: invisible scalar → nibble value.
    static let invisibleToNibble: [Unicode.Scalar: UInt8] = Dictionary(
        uniqueKeysWithValues: nibbleToInvisible.enumerated().map { ($1, UInt8($0)) }
    )
}
