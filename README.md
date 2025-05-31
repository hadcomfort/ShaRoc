# ShaRoc

**ShaRoc** is a pure and robust SHA-256 hashing library for the Roc programming language. It is designed to be easy to use and integrate into your Roc projects, providing a secure and reliable way to compute SHA-256 hashes. This library aims for compliance with FIPS 180-4 standards.

## Public API

The `Sha256` module exposes the following primary functions:

*   `hash : List U8 -> List U8`
    *   Computes the SHA-256 hash of a list of bytes (`List U8`) and returns the 32-byte hash as a `List U8`.
*   `hashToHex : List U8 -> Str`
    *   Computes the SHA-256 hash of a list of bytes (`List U8`) and returns the hash as a 64-character lowercase hexadecimal string (`Str`).
*   `hashStrToHex : Str -> Str`
    *   Computes the SHA-256 hash of a Roc string (`Str`) (after converting it to UTF-8 bytes) and returns the hash as a 64-character lowercase hexadecimal string (`Str`).
*   `hashStrToBytes : Str -> List U8`
    *   Computes the SHA-256 hash of a Roc string (`Str`) (after converting it to UTF-8 bytes) and returns the 32-byte hash as a `List U8`.

## Usage Examples

Here's how you can use ShaRoc in your Roc application:

```roc
app "myApp"
    imports [
        roc-community.sha256.Sha256, # (Assuming this will be the future package name)
        pf.Stdout,
    ]
    provides [main] to pf

main =
    # Example using hashStrToHex
    helloHashStr = Sha256.hashStrToHex "hello world"
    Stdout.line "SHA-256 of 'hello world': (Str.toUtf8 helloHashStr)"! # Printing string requires toUtf8

    # Example using hashToHex
    byteList = [0x68, 0x65, 0x6c, 0x6c, 0x6f] # "hello"
    helloBytesHashStr = Sha256.hashToHex byteList
    Stdout.line "SHA-256 of [0x68, 0x65, 0x6c, 0x6c, 0x6f]: (Str.toUtf8 helloBytesHashStr)"!

    # Example using hash
    rawHashBytes = Sha256.hash byteList
    # To print or use rawHashBytes, you might convert them to hex or handle as needed.
    # For demonstration, let's use the library's own utility (if it were exposed, or you'd write one)
    # Stdout.line "Raw hash bytes (hex): (Str.toUtf8 (Sha256.Internal.bytesToHex rawHashBytes))"!
    # Since bytesToHex is internal, you'd typically use hashToHex directly if you need a string.
    Stdout.line "SHA-256 of [0x68, 0x65, 0x6c, 0x6c, 0x6f] (using hash then manual hex for demo): (Str.toUtf8 helloBytesHashStr)"!


# Note: To run these examples, you would need the Sha256 library available
# and a platform that provides Stdout, like `basic-cli`.
# The exact import path `roc-community.sha256.Sha256` is a placeholder
# for how packages will be named and imported.
```

## Installation

(Details on how to install and integrate the ShaRoc library into your Roc project will be provided here once packaging standards are more established.)

You will typically add it as a dependency in your project's `Package.roc` file (or equivalent Roc package manifest).

## Running Tests

To run the tests for this library:

(Instructions for running tests, e.g., using `roc test tests/TestSha256.roc`, will be detailed here.)

## License

This library is released under the MIT License. See the `LICENSE` file for more details.
