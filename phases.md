**Phase 1: Core Algorithm Implementation (Internal Logic)**

1.  **Define Constants & Bitwise Helpers:**
    *   Action: In a new file (e.g., `src/Sha256/Internal.roc`), define the SHA-256 initial hash values (H0-H7) and round constants (K).
    *   Action: Implement the required bitwise helper functions (`rotr`, `shr`, `ch`, `maj`, `bigSigma0`, `bigSigma1`, `smallSigma0`, `smallSigma1`) working on `U32`. Ensure all additions correctly handle modulo 2^32 (Roc's `U32` addition naturally does this).
2.  **Implement Message Preprocessing (Padding):**
    *   Action: In `src/Sha256/Internal.roc`, create a pure Roc function that takes a `List U8` (message) and returns a `List U8` (padded message). This involves appending '1' bit, then '0' bits, then the 64-bit big-endian message length.
3.  **Implement Message Schedule Generation:**
    *   Action: In `src/Sha256/Internal.roc`, create a function that takes a 64-byte message_chunk (`List U8`) and generates the 64-word message schedule `w` (`List U32`). This involves converting the first 16 words and then calculating `w[16..63]` using `smallSigma0`, `smallSigma1`.
4.  **Implement the Main Compression Loop:**
    *   Action: In `src/Sha256/Internal.roc`, create a function that takes the current hash values (`h0..h7` as a list or record of `U32`) and the message schedule `w` (`List U32`). It should perform the 64 rounds of SHA-256 computation and return the updated hash values.
5.  **Implement the Core `sha256Once` Function:**
    *   Action: In `src/Sha256/Internal.roc`, combine the padding, message schedule, and compression loop. This function will take a `List U8` (original message), perform all SHA-256 steps, and output the final 32-byte hash as a `List U8`.

**Phase 2: Public API and Utility Functions**

6.  **Design and Implement the Public `Sha256.roc` Module (Initial):**
    *   Action: Create `src/Sha256.roc`. Expose the core `hash : List U8 -> List U8` function by calling the internal `sha256Once` function.
7.  **Implement Byte-to-Hex String Conversion:**
    *   Action: In `src/Sha256/Internal.roc` (or directly in `Sha256.roc` if simple enough), create a function `bytesToHex : List U8 -> Str` to convert a list of bytes into a lowercase hexadecimal string.
8.  **Implement Public Convenience Functions:**
    *   Action: In `src/Sha256.roc`, add `hashToHex : List U8 -> Str` (uses `hash` and `bytesToHex`).
    *   Action: In `src/Sha256.roc`, add `hashStr : Str -> Str` (uses `Str.toUtf8`, then `hashToHex`).
    *   Action: (Optional, as discussed) In `src/Sha256.roc`, add `hashStrToBytes : Str -> List U8`.

**Phase 3: Testing**

9.  **Set up Test File and Basic Test Harness:**
    *   Action: Create `tests/TestSha256.roc`. Import the `Sha256` module and Roc's testing utilities.
10. **Implement Tests for `bytesToHex`:**
    *   Action: In `tests/TestSha256.roc`, write tests specifically for your byte-to-hexadecimal string conversion utility using known byte/hex pairs.
11. **Implement Tests using NIST Vectors (String Inputs):**
    *   Action: In `tests/TestSha256.roc`, add test cases using `hashStr` (or `hashToHex` with `Str.toUtf8`) and known SHA-256 test vectors for various string inputs (empty string, "abc", longer strings, strings requiring different padding scenarios). Compare against expected hex outputs.
12. **Implement Tests using NIST Vectors (Byte Inputs):**
    *   Action: In `tests/TestSha256.roc`, add test cases using `hash` (comparing `List U8` outputs) and/or `hashToHex` (comparing hex string outputs) with known test vectors provided as byte arrays. This ensures the core byte-level hashing is correct.

**Phase 4: Packaging and Documentation**

13. **Create `README.md` (Initial Draft):**
    *   Action: Write an initial `README.md` with a project description, simple usage examples for the main functions, and a list of the public API functions.
14. **Add In-Code Documentation:**
    *   Action: Go through `src/Sha256.roc` and `src/Sha256/Internal.roc` adding Roc `##` documentation comments for modules, public functions, and complex internal functions, explaining their purpose, parameters, and return values.
15. **Create `Package.roc` (or equivalent manifest):**
    *   Action: Create the Roc package manifest file (e.g., `Package.roc` or whatever the current standard is). Define the package name, version (e.g., "0.1.0"), dependencies (likely none for this pure library), and what modules it exposes (the `Sha256` module).
16. **Refine `README.md` with Build/Integration Instructions:**
    *   Action: Update `README.md` to include instructions on how another Roc project can depend on and use this library, based on how Roc's package manager works
