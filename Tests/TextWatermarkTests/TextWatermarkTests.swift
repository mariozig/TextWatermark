import Testing
@testable import TextWatermark

// MARK: - Roundtrip Tests

@Test func roundtripBasicASCII() {
    let visible = "Hello, world!"
    let secret = "secret message"
    let encoded = TextWatermark.encode(visibleText: visible, secretText: secret)
    let decoded = TextWatermark.decode(from: encoded)
    #expect(decoded == secret)
}

@Test func roundtripSingleCharacter() {
    let encoded = TextWatermark.encode(visibleText: "A", secretText: "B")
    #expect(TextWatermark.decode(from: encoded) == "B")
}

@Test func roundtripEmoji() {
    let secret = "Hello 🌍🎉"
    let encoded = TextWatermark.encode(visibleText: "visible", secretText: secret)
    #expect(TextWatermark.decode(from: encoded) == secret)
}

@Test func roundtripZWJEmoji() {
    let secret = "👨‍👩‍👧‍👦"
    let encoded = TextWatermark.encode(visibleText: "family", secretText: secret)
    #expect(TextWatermark.decode(from: encoded) == secret)
}

@Test func roundtripMultilingual() {
    let secret = "日本語テスト café résumé"
    let encoded = TextWatermark.encode(visibleText: "text", secretText: secret)
    #expect(TextWatermark.decode(from: encoded) == secret)
}

@Test func roundtripLongText() {
    let secret = String(repeating: "abcde12345", count: 1000) // 10,000 chars
    let encoded = TextWatermark.encode(visibleText: "cover", secretText: secret)
    #expect(TextWatermark.decode(from: encoded) == secret)
}

@Test func roundtripWhitespace() {
    let secret = "line1\nline2\ttab"
    let encoded = TextWatermark.encode(visibleText: "visible", secretText: secret)
    #expect(TextWatermark.decode(from: encoded) == secret)
}

@Test func roundtripNullByte() {
    let secret = "before\0after"
    let encoded = TextWatermark.encode(visibleText: "visible", secretText: secret)
    #expect(TextWatermark.decode(from: encoded) == secret)
}

// MARK: - Suffix Tests

@Test func defaultSuffixProducesNoTrailingPeriod() {
    let encoded = TextWatermark.encode(visibleText: "Hello", secretText: "secret")
    #expect(!encoded.hasSuffix("."))
}

@Test func periodSuffix() {
    let encoded = TextWatermark.encode(visibleText: "Hello", secretText: "secret", suffix: ".")
    #expect(encoded.hasSuffix("."))
    #expect(TextWatermark.decode(from: encoded) == "secret")
}

@Test func customSuffix() {
    let encoded = TextWatermark.encode(visibleText: "Hello", secretText: "secret", suffix: " --end")
    #expect(encoded.hasSuffix(" --end"))
    #expect(TextWatermark.decode(from: encoded) == "secret")
}

@Test func decodeIgnoresSuffix() {
    let withDot = TextWatermark.encode(visibleText: "A", secretText: "msg", suffix: ".")
    let withCustom = TextWatermark.encode(visibleText: "A", secretText: "msg", suffix: " --end")
    let withNone = TextWatermark.encode(visibleText: "A", secretText: "msg")
    #expect(TextWatermark.decode(from: withDot) == "msg")
    #expect(TextWatermark.decode(from: withCustom) == "msg")
    #expect(TextWatermark.decode(from: withNone) == "msg")
}

// MARK: - Encode Edge Cases

@Test func emptySecretReturnsVisibleText() {
    let result = TextWatermark.encode(visibleText: "Hello", secretText: "")
    #expect(result == "Hello")
}

@Test func emptySecretWithSuffix() {
    let result = TextWatermark.encode(visibleText: "Hello", secretText: "", suffix: ".")
    #expect(result == "Hello.")
}

@Test func emptyVisibleTextStillEncodes() {
    let encoded = TextWatermark.encode(visibleText: "", secretText: "hidden")
    #expect(TextWatermark.decode(from: encoded) == "hidden")
}

@Test func outputStartsWithVisibleText() {
    let visible = "Check this out"
    let encoded = TextWatermark.encode(visibleText: visible, secretText: "secret")
    #expect(encoded.hasPrefix(visible))
}

@Test func payloadCharactersAreInvisible() {
    let visible = "Hello"
    let encoded = TextWatermark.encode(visibleText: visible, secretText: "test")
    // Everything after the visible text and before any suffix should be invisible
    let afterVisible = String(encoded.dropFirst(visible.count))
    for scalar in afterVisible.unicodeScalars {
        // All scalars should be either the marker (U+2060) or one of the 16 payload chars
        let isMarker = scalar == TextWatermark.markerScalar
        let isPayload = TextWatermark.invisibleToNibble[scalar] != nil
        #expect(isMarker || isPayload, "Unexpected visible scalar: U+\(String(scalar.value, radix: 16, uppercase: true))")
    }
}

// MARK: - Decode Edge Cases

@Test func decodeNoHiddenTextReturnsNil() {
    #expect(TextWatermark.decode(from: "Just normal text") == nil)
}

@Test func decodeEmptyStringReturnsNil() {
    #expect(TextWatermark.decode(from: "") == nil)
}

@Test func decodeVisibleTextWithZWJEmoji() {
    // ZWJ (U+200D) appears naturally in emoji — verify it doesn't cause false decode
    let text = "Family: 👨‍👩‍👧‍👦 emoji"
    #expect(TextWatermark.decode(from: text) == nil)
}
