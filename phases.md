**Phase 1: Core Logic Completion & Critical Fixes**

This phase focuses on implementing missing critical functionality and resolving immediate code issues.

1.  **Implement `padMessage` Function:**
    *   **File:** `src/Sha256/Internal.roc`
    *   **Task:** Replace the placeholder `padMessage` function with the full SHA-256 padding logic according to FIPS 180-4, Section 5.1.1:
        1.  Append a single '1' bit (i.e., byte `0x80`).
        2.  Append '0' bits (i.e., `0x00` bytes) until the message length in bits is congruent to 448 (mod 512). This means the length in bytes should be 56 (mod 64) *before* appending the length.
        3.  Append the original message length (before padding) as a 64-bit big-endian integer representing the length in *bits*.
    *   **Why:** This is essential for the SHA-256 algorithm to work correctly for all input sizes.

2.  **Implement `u32sToBytes` Function:**
    *   **File:** `src/Sha256/Internal.roc`
    *   **Task:** Replace the placeholder `u32sToBytes` function. It should take a `List U32` (expected to be the 8 final hash words) and convert it into a 32-byte `List U8`. Each U32 word must be converted to 4 bytes in big-endian order.
        *   For a U32 `w`, the bytes are `(w >> 24) & 0xFF`, `(w >> 16) & 0xFF`, `(w >> 8) & 0xFF`, `w & 0xFF`.
    *   **Why:** This is needed to produce the final byte-based hash output.

3.  **Remove Duplicate Function Definitions:**
    *   **File:** `src/Sha256/Internal.roc`
    *   **Task:** You have duplicate definitions for `bytesToWordsBE` and `generateMessageSchedule` towards the end of the file (before the "Inline Tests" section). Remove these latter definitions, keeping the primary ones at the top of the file.
    *   **Why:** Reduces confusion and potential for unsynchronized code.

4.  **Review `sha256Once` Error Handling:**
    *   **File:** `src/Sha256/Internal.roc`
    *   **Task:** The `sha256Once` function currently `crash`es if `generateMessageSchedule` returns `Err InvalidInput`.
        *   Verify that with a correct `padMessage` implementation, `generateMessageSchedule` will *never* receive a chunk that isn't 64 bytes long (thus `bytesToWordsBE` within it won't return `Err InvalidInput`).
        *   If this invariant holds, the `crash` acts as an assertion for an internal library bug, which might be acceptable for "minimal".
        *   For increased robustness, consider if `sha256Once` (even as internal) should propagate a `Result` type. However, if the public API functions don't return `Result`, this error would still need to be handled (e.g., by crashing, which is what happens now, or by returning a fixed error hash/empty list, which is generally not good for crypto).
        *   **Recommendation for now:** Focus on making `padMessage` robust. If it's correct, the error path leading to the crash shouldn't be hit with valid API usage.
    *   **Why:** Ensures library stability and predictable behavior.

**Phase 2: Testing Enhancements & Consistency**

This phase aims to make your tests more robust, idiomatic, and consolidated.

1.  **Correct Test Function Calls:**
    *   **File:** `tests/TestSha256.roc`
    *   **Task:** In "`describe "hashStr NIST Vector Tests"`", you're calling `Sha256.hashStr`. The public API in `src/Sha256.roc` exposes `hashStrToHex`. Update these test calls to use `Sha256.hashStrToHex` to accurately test the exposed API.
    *   **Why:** Ensures tests are validating the actual public interface.

2.  **Migrate Inline Tests to `TestSha256.roc`:**
    *   **File:** `src/Sha256/Internal.roc` and `tests/TestSha256.roc`
    *   **Task:**
        1.  Move the test logic from the "Inline Tests" section of `Internal.roc` (including `expectU32Crash`, `expectStrCrash`, `runBitwiseHelperTests`, `runMessageScheduleTests`, `runProcessChunkTests`, and associated test data like `messageChunk_abc_bytes`, `expected_schedule_abc_prefix`) into `tests/TestSha256.roc`.
        2.  Adapt these tests to use the standard `roc/Test` framework (e.g., replace `expectU32Crash` with `expectEq`).
        3.  Remove the `_ = run...Tests` lines from `Internal.roc` so tests don't run on module load.
        4.  Ensure `Internal.roc` exposes any functions that these tests need (it seems to do so already).
    *   **Why:** Consolidates all tests, uses the standard Roc testing mechanism, and prevents tests from running during normal module import.

3.  **Add Tests for New/Critical Logic:**
    *   **File:** `tests/TestSha256.roc`
    *   **Task:**
        *   Write specific unit tests for the `padMessage` function. Test cases: empty message, short message ("abc"), messages with lengths around the block boundary (55, 56, 63, 64 bytes), and a message longer than 64 bytes. Verify the padding bits and the appended length are correct.
        *   Write unit tests for the `u32sToBytes` function with known U32 values and their expected byte representations.
    *   **Why:** Ensures correctness of the newly implemented critical components.

**Phase 3: Documentation, Licensing & API Polish**

This phase focuses on making the library professional and easy for others to use.

1.  **Resolve License Inconsistency:**
    *   **Files:** `README.md`, `LICENSE`
    *   **Task:** Your `LICENSE` file specifies "Unlicense", but your `README.md` (at the bottom) states "MIT License". Choose one license (Unlicense seems to be your primary choice) and make both files consistent.
    *   **Why:** Crucial for legal clarity and professionalism.

2.  **Refine `README.md`:**
    *   **File:** `README.md`
    *   **Task:**
        *   Update the "License" section to match your chosen license.
        *   Under "Running Tests", add the explicit command: `roc test` (or `roc test tests/TestSha256.roc` if more specific).
        *   Review usage examples for clarity. The current examples for printing `Stdout.line "... (Str.toUtf8 ...)"!` are correct for Roc but can be a bit verbose. Consider if simply showing the hash assignment and a comment about how to use/print it would be cleaner for a library README.
        *   Ensure installation instructions are still relevant to current Roc package management practices. (They look like good placeholders).
    *   **Why:** Improves user experience and clarity.

3.  **Review In-Code Documentation:**
    *   **Files:** `src/Sha256.roc`, `src/Sha256/Internal.roc`
    *   **Task:** Briefly review all `##` documentation comments for accuracy, completeness, and clarity, especially for public API functions in `Sha256.roc`. Ensure parameters, return values, and any assumptions (like UTF-8 input for string functions) are clearly stated.
    *   **Why:** Essential for maintainability and usability by others.

4.  **Consider Development Artifacts:**
    *   **Files:** `phases.md`, `sha256-roc-library-plan.md`
    *   **Task:** These files document your development process. For a public release, they are not typically part of the user-facing library documentation. Consider moving them into a `docs/development/` subdirectory or simply leaving them in the root if you prefer. The `README.md` should be the primary entry point for users.
    *   **Why:** Keeps the root directory cleaner for users focusing on the library itself. (Minimal effort: leave as is).

**Phase 4: Final Review & Release Preparation**

This is the last check before considering the library ready for a `0.1.0` release.

1.  **Code Formatting:**
    *   **Files:** All `.roc` files.
    *   **Task:** Run `roc format` on all your Roc source files to ensure consistent formatting.
    *   **Why:** Improves code readability and adheres to community standards.

2.  **Final Code Review:**
    *   **Files:** Primarily `src/` and `tests/`
    *   **Task:** Do a pass over the codebase, looking for:
        *   Any remaining placeholders or `TODO`s.
        *   Clarity of variable names and logic.
        *   Correct usage of Roc idioms.
        *   Potential edge cases not covered by tests (though your NIST vectors are good).
        *   Ensure all exposed functions in `Internal.roc` that are *not* intended for external use (even within the package by other modules than `Sha256.roc`) are clearly marked as such in their docs, or consider if they truly need to be in the module's `exposing` list. (Current setup seems fine as only `Sha256.roc` uses them).
    *   **Why:** Catches any last-minute issues and polishes the code.

3.  **Validate `Package.roc`:**
    *   **File:** `Package.roc`
    *   **Task:** Ensure the package name (`"roc-community/sha256"`), version (`"0.1.0"`), and exposed modules (`[Sha256]`) are correct and ready for a potential public release.
    *   **Why:** Ensures the package is correctly defined for Roc's ecosystem.

4.  **Tag Release:**
    *   **Task:** Once all steps are complete and you're satisfied, create a Git tag for your `v0.1.0` release.
    *   **Why:** Marks a stable version for users to depend on
