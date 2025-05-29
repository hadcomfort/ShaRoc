# Plan and Outline for a Roc SHA-256 Library

This document outlines the plan, architecture, implementation details, and development considerations for creating a pure Roc library for SHA-256 hashing.

## Core Functionality & API (MVP)

This section outlines the minimum viable product (MVP) for the SHA-256 Roc library, focusing on the core hashing functions and convenient wrappers.

### 1. Primary Hashing Function (Bytes to Bytes)

*   **Signature:** `hash : List U8 -> List U8`
*   **Description:** This is the fundamental, pure hashing function. It takes a list of bytes (`List U8`) as input and returns a 32-byte list (`List U8`) representing the SHA-256 hash of the input.

### 2. Convenience Hashing Function (Bytes to Hex String)

*   **Signature:** `hashToHex : List U8 -> Str`
*   **Description:** This function provides a convenient way to get a human-readable hash. It takes a list of bytes (`List U8`), computes its SHA-256 hash, and then converts the resulting 32-byte hash into a 64-character lowercase hexadecimal string (`Str`).

### 3. Convenience Hashing Function (String to Hex String)

*   **Signature:** `hashStrToHex : Str -> Str` (Note: `hashStr` was considered but `hashStrToHex` is clearer)
*   **Description:** This function simplifies hashing Roc strings. It takes a Roc string (`Str`) as input, first converts it to a list of bytes (`List U8`) using UTF-8 encoding. Then, it computes the SHA-256 hash of these bytes and returns the hash as a 64-character lowercase hexadecimal string (`Str`).

### 4. Optional Hashing Function (String to Raw Bytes)

*   **Signature:** `hashStrToBytes : Str -> List U8`
*   **Description:** This function is for users who need the raw byte output from a string input. It takes a Roc string (`Str`), converts it to a list of bytes (`List U8`) using UTF-8 encoding, computes the SHA-256 hash, and returns the raw 32-byte hash as a `List U8`.

## Proposed Library Architecture & File Structure

This section details the planned directory structure and the role of each key file within the SHA-256 Roc library.

### 1. Overall Directory Structure

The library will be organized as follows:

```
sha256-roc-lib/
├── src/
│   ├── Sha256.roc
│   └── Sha256/
│       └── Internal.roc
├── tests/
│   └── TestSha256.roc
├── Package.roc
└── README.md
```

### 2. File Descriptions

*   **`src/Sha256.roc`:**
    *   **Role:** This file serves as the main public API module for the library. It is what consumers of the library will import to access the SHA-256 hashing functionalities.
    *   **Exposed Functions:** It will expose the functions defined in the "Core Functionality & API (MVP)" section:
        *   `hash : List U8 -> List U8`
        *   `hashToHex : List U8 -> Str`
        *   `hashStrToHex : Str -> Str`
        *   `hashStrToBytes : Str -> List U8`
    *   **Interaction with `Internal.roc`:** This module will delegate the complex parts of the SHA-256 algorithm (like padding, the compression loop, and specific transformations) to `Sha256/Internal.roc`. It will primarily handle input validation/conversion (e.g., string to byte list for `hashStrToHex`) and then call the core hashing logic in `Internal.roc`. It will also use helpers from `Internal.roc` for tasks like converting the final hash bytes to a hexadecimal string.

*   **`src/Sha256/Internal.roc`:**
    *   **Role:** This module houses all the internal, implementation-specific details of the SHA-256 algorithm. Its contents are not intended for direct use by the library's consumers and are subject to change without notice.
    *   **Examples of Logic:**
        *   SHA-256 initial hash values (H0-H7).
        *   SHA-256 round constants (K).
        *   Bitwise helper functions (e.g., `ROTR`, `SHR`, `SIGMA0`, `SIGMA1`, `Ch`, `Maj`).
        *   Message padding logic (pre-processing).
        *   The main message schedule and compression loop.
        *   Helper functions for converting byte lists to/from words (U32), and byte lists to hexadecimal strings.
    *   **Emphasis:** The functions and values within this module are strictly internal. The `Sha256.roc` module will expose a curated, stable API, abstracting these internal details away from the end-user.

*   **`tests/TestSha256.roc`:**
    *   **Purpose:** This file will contain the test suite for the library. It will use Roc's built-in testing capabilities to define various test cases.
    *   **Test Coverage:** Tests will include:
        *   Hashing known byte sequences and comparing against standard SHA-256 test vectors (e.g., from NIST).
        *   Testing `hashToHex` for correct hexadecimal conversion.
        *   Testing `hashStrToHex` with various string inputs, including empty strings and strings with UTF-8 characters.
        *   Testing `hashStrToBytes` for correct byte output.
        *   Edge cases like empty inputs.

*   **`Package.roc`:**
    *   **Role:** This is the Roc package manifest file. It defines essential metadata for the library.
    *   **Contents:**
        *   `name`: The name of the package (e.g., `roc-community/sha256`).
        *   `version`: The version of the package (e.g., `1.0.0`).
        *   `dependencies`: Any external Roc packages this library depends on (likely none for the MVP).
        *   `exposes`: A list of modules that this package exposes to consumers. For this library, it will primarily be `[ Sha256 ]`.

*   **`README.md`:**
    *   **Purpose:** This file provides the primary user-facing documentation for the library.
    *   **Contents:**
        *   A brief description of the library and its purpose.
        *   Installation instructions.
        *   Usage examples.
        *   API Overview.
        *   Information on running tests.
        *   Licensing information.

## Key Implementation Details & Considerations

This section covers crucial aspects of the SHA-256 algorithm's implementation within the Roc library. All logic described here will reside primarily within `src/Sha256/Internal.roc` unless otherwise specified for user-facing modules.

### 1. Constants

*   **Initial Hash Values (H0-H7):** Eight 32-bit (U32) values.
    *   `h0 := 0x6a09e667`, ..., `h7 := 0x5be0cd19`
*   **Round Constants (K):** Sixty-four 32-bit (U32) values.
    *   Example: `k[0] := 0x428a2f98`, ..., `k[63] := 0xc67178f2`
*   **Location:** Defined as top-level values in `src/Sha256/Internal.roc`.

### 2. Helper Functions (Bitwise operations on U32)

Essential SHA-256 operations: `rotr`, `shr`, `ch`, `maj`, `bigSigma0`, `bigSigma1`, `smallSigma0`, `smallSigma1`. Implemented as pure functions in `src/Sha256/Internal.roc`.

### 3. Preprocessing (Padding)

Input messages (`List U8`) are padded to a multiple of 512 bits (64 bytes):
1.  Append `1` bit (byte `0x80`).
2.  Append `0` bits until length is 448 mod 512.
3.  Append original message length as a 64-bit big-endian integer.

### 4. Processing in 512-bit (64-byte) Chunks

Padded message processed in sequential 64-byte chunks:
1.  Initialize h0-h7 with H constants.
2.  For each chunk:
    *   Create message schedule `w` (64 U32 words).
    *   Initialize working variables a-h.
    *   Compression Loop (64 rounds) using `w`, K constants, and helper functions.
    *   Update h0-h7.

### 5. Output Formatting

*   **Final Hash (List U8):** Concatenation of h0-h7 (big-endian), resulting in a 32-byte `List U8`.
*   **Hexadecimal String Conversion (`Str`):** For `hashToHex` and `hashStrToHex`, the 32-byte `List U8` is converted to a 64-character lowercase hexadecimal string.

### 6. Endianness

*   **Big-Endian Critical:** For parsing message words, appending message length, and final hash output.
*   **Roc Handling:** Use Roc's standard library for byte-to-U32 conversion (big-endian) or implement manually if needed.

### 7. Purity

*   All core cryptographic logic must be pure Roc functions. No side effects.

## Testing Strategy

All tests will be located in `tests/TestSha256.roc`.

### 1. Test Harness

*   Tests organized into groups by API function.
*   Use Roc's built-in testing utilities (e.g., `expectEq`).

### 2. Test Vectors

*   **Source:** NIST publications (FIPS PUB 180-4, RFC 4634/6234).
*   **Cases:** Empty input, short inputs, padding variations (message lengths 55, 56, 63, 64, 111, 112 bytes), multi-block messages, longer messages, UTF-8 strings.

### 3. Coverage

*   All public API functions in `src/Sha256.roc`.
*   Internal logic indirectly verified via public API tests.

### 4. Hex Encoding Test

*   Dedicated unit tests for the byte-to-hex string conversion helper, covering known sequences, leading zeros, all-zeros, and all-0xFF inputs.

## Initial Documentation Plan

### 1. `README.md` Content

*   **Overview:** Library description and purpose.
*   **Installation/Integration:** How to add as a dependency (published, local, Git), noting Roc's evolving package system.
*   **Usage Examples:** Code snippets for all public functions, using `Stdout.line ... |> Task.await`.
*   **API Reference (Brief):** List of public functions with signatures and short descriptions.
*   **Build and Test Instructions:** How to build (as part of an app) and run tests (`roc test tests/TestSha256.roc`).
*   **License Information:** Placeholder for chosen license and link to `LICENSE` file.

### 2. In-Code Documentation

*   Use Roc's `##` comment syntax.
*   **Module-Level (`src/Sha256.roc`):** Overview, adherence to FIPS 180-4, input/output types, summary of exposed functions, necessary imports.
*   **Function-Level (public functions in `src/Sha256.roc`):** Detailed `##` comments covering description, parameters, return values, assumptions, and examples.

## Roc Specifics for Library Development

### 1. Package Management (`Package.roc`)

*   **Role:** Defines package identity, metadata, dependencies, exposures.
*   **Name & Version:** `authorName/packageName` (e.g., `roc-community/sha256`), semantic versioning, Roc compatibility version.
*   **Dependencies:** None for MVP.

### 2. Exposing Modules

*   `Sha256` module exposed via `exposes [Sha256]` in `Package.roc`.
*   Consumers import like `imports [roc-community.sha256.Sha256]`.

### 3. Purity & Immutability

*   Core logic will be pure functions with immutable data.
*   Benefits: Easier reasoning, testability, compiler optimizations, thread safety.

### 4. Error Handling (MVP)

*   `hash`, `hashToHex`: No explicit `Result` type.
*   `hashStrToHex`, `hashStrToBytes`: Assume Roc's `Str` is valid UTF-8 and `Utf8.toBytes` is infallible for MVP. No `Result` type.
*   Future: Consider `Result` for more complex error scenarios.

### 5. Performance Considerations (Future, not MVP)

*   MVP: Focus on correctness, clarity, idiomatic Roc.
*   Future: Benchmarking, compiler optimizations, lower-level Roc features if performance is critical.

### 6. UTF-8 Encoding Assumption

*   `Str` inputs are assumed to be UTF-8. Documented clearly.
*   Use standard Roc `Utf8.toBytes` for conversion. User responsibility for valid UTF-8 from external sources.

This plan aims for a well-behaved, idiomatic, and robust SHA-256 library within the Roc ecosystem.
