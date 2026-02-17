# TextWatermark

A Swift package for text steganography -- hide secret text inside visible text using invisible Unicode characters.

## How it works

1. The secret text is converted to UTF-8 bytes
2. Each byte is split into two [**nibbles**](https://en.wikipedia.org/wiki/Nibble) (half-bytes of 4 bits each). A nibble holds a value from 0–15, which is exactly one hex digit. For example, the byte `0x48` (the letter "H") splits into a high nibble `4` and a low nibble `8`.
3. Each nibble is mapped to one of 16 invisible Unicode characters, so every byte of the secret becomes exactly two invisible characters
4. A start-of-payload marker (three consecutive U+2060 WORD JOINER) is inserted between the visible text and the payload
5. The decoder finds the marker, reads the invisible characters in pairs, reconstructs the bytes, and converts back to a string

## Usage

```swift
import TextWatermark

// Encode a secret message
let watermarked = TextWatermark.encode(
    visibleText: "Nothing to see here",
    secretText: "hidden message"
)
// watermarked looks like "Nothing to see here" but contains invisible characters

// Decode it back
let secret = TextWatermark.decode(from: watermarked)
// secret == "hidden message"
```

### Optional suffix

By default, encoded text has no visible artifacts. Pass a `suffix` to append visible text after the payload:

```swift
let withDot = TextWatermark.encode(
    visibleText: "Hello",
    secretText: "secret",
    suffix: "."
)
// Looks like "Hello." — the period is visible, the secret is not
// Decoding works the same regardless of suffix
```

## Try it out quick!

From the project directory, open a REPL with the library loaded:

```bash
swift run --repl
```

Then try encoding and decoding:

```swift
import TextWatermark

// Encode a secret — no visible artifacts
let msg = TextWatermark.encode(visibleText: "Nothing here", secretText: "top secret")
print(msg)                                  // "Nothing here"
print(msg.unicodeScalars.count)             // Much longer than it looks
print(TextWatermark.decode(from: msg)!)     // "top secret"

// Encode with a visible suffix
let dotMsg = TextWatermark.encode(visibleText: "Hello", secretText: "secret", suffix: ".")
print(dotMsg)                               // "Hello."
print(TextWatermark.decode(from: dotMsg)!)  // "secret"

:quit                                       // Exit the repl
```

## Adding to your project

```swift
dependencies: [
    .package(url: "https://github.com/mariozig/TextWatermark.git", from: "1.0.0")
]
```

## Acknowledgments

Inspired by [text_watermark](https://github.com/jaceddd/text_watermark) by [@jaceddd](https://github.com/jaceddd), a JavaScript implementation of the same concept. This Swift port uses UTF-8 encoding and an invisible start marker instead of the original's UTF-16 approach and visible trailing period.

## License

MIT
