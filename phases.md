**Phase 1: Ensuring Core Roc Spec Compliance & Robustness**

*   **Context:** This phase addresses the primary potential deviation from the provided `rocdocs.txt` and ensures internal logic is robust.
*   **Tasks:**

    1.  **Clarify/Replace `Num.toHex` Usage:**
        *   **File:** `src/Sha256/Internal.roc` (function `bytesToHex`) and `tests/TestSha256.roc` (helper `expectU32Crash`).
        *   **Task:**
            1.  **Verify:** Determine if `Num.toHex` is a standard Roc builtin function available across common platforms/Roc versions, or if it's an extension (e.g., specific to `basic-cli`). The `rocdocs.txt` does not list it.
            2.  **If Standard/Commonly Available Extension:** Add a comment in `bytesToHex` clarifying its origin or assumed availability if not directly in the core `Num` spec per generic `rocdocs`.
            3.  **If Not Standard/To Ensure Purity:** Implement a pure Roc helper function within `src/Sha256/Internal.roc`, for example:
                `byteToHexChars : U8 -> { high : U8, low : U8 }` (returning ASCII bytes for hex chars) or `byteToSingleHexStr : U8 -> Str` (if small string concatenations are fine). Then, refactor `bytesToHex` to use this internal helper. This would make the library fully self-contained regarding hex conversion logic based purely on standard Roc types and operations found in `rocdocs.txt`.
                Update `expectU32Crash` similarly if needed, or simplify its string formatting.
        *   **Why:** Ensures the library relies only on documented Roc features or provides its own implementations for full portability and spec adherence.
        *   **Context Needed:** Access to broader Roc documentation or knowledge about `Num.toHex`'s status.

    2.  **Confirm Invariant for `sha256Once` Error Handling:**
        *   **File:** `src/Sha256/Internal.roc` (function `sha256Once`).
        *   **Task:** Add an explicit comment above the `crash` site in `sha256Once` stating the invariant: "This crash should be unreachable if `padMessage` is implemented correctly, as `generateMessageSchedule` will only receive 64-byte chunks, thus `bytesToWordsBE` will not return `Err InvalidInput`."
        *   **Why:** Makes the design decision clear and documents the expectation for internal consistency.
        *   **Context Needed:** Understanding that `padMessage` is intended to always produce validly sized blocks for `generateMessageSchedule`.

    3.  **Final Review of Type Annotations and Docstrings:**
        *   **Files:** `src/Sha256.roc`, `src/Sha256/Internal.roc`.
        *   **Task:** Perform a quick pass over all function signatures and `##` docstrings.
            *   Ensure type annotations accurately reflect the data types being used and are consistent with types available in `rocdocs.txt` (e.g., `List U8`, `Str`, `U32`, `Result`, etc.).
            *   Verify clarity and accuracy of explanations, especially for parameters and return values in `Sha256.roc`.
        *   **Why:** Enhances maintainability, usability, and ensures documentation matches the code.
        *   **Context Needed:** Familiarity with the SHA-256 algorithm and Roc's type system.

---

**Phase 2: Testing Finalization and Best Practices**

*   **Context:** The testing setup is already very good. This phase is for minor polish.
*   **Tasks:**

    1.  **Standardize Test Assertions (Optional Polish):**
        *   **File:** `tests/TestSha256.roc`.
        *   **Task:** Consider replacing calls to the adapted `expectU32Crash` and `expectStrCrash` helpers with direct `roc/Test.expectEq actual expected "description"` calls. The current adapted helpers returning `Result {} Str` and then using `runChecks` is functional, but direct `expectEq` is slightly more idiomatic `roc/Test` style.
        *   **Why:** Minor improvement for idiomatic test style. The current approach is not incorrect.
        *   **Context Needed:** Current `expectU32Crash` and `expectStrCrash` implementations.

    2.  **Ensure Test Data is Self-Contained or Clearly Sourced:**
        *   **File:** `tests/TestSha256.roc`.
        *   **Task:** Briefly review `messageChunk_abc_bytes` and `expected_schedule_abc_prefix`. They seem to be correctly defined locally. Ensure any other non-trivial test data is either generated or its source (e.g., "NIST FIPS 180-4 Appendix X") is clear.
        *   **Why:** Test clarity and reproducibility.
        *   **Context Needed:** Test data definitions.

---

**Phase 3: Documentation & Repository Presentation**

*   **Context:** Finalizing user-facing documentation and repository structure.
*   **Tasks:**

    1.  **Confirm License Statement in `README.md`:**
        *   **File:** `README.md`.
        *   **Task:** The `README.md` correctly states "MIT License", matching the `LICENSE` file. This item from your previous `phases.md` (referring to an Unlicense/MIT mismatch) is resolved in the current code state. No action needed here other than acknowledging it's correct.
        *   **Why:** Legal clarity for users.
        *   **Context Needed:** Current `README.md` and `LICENSE` files.

    2.  **Organize Development Artifacts:**
        *   **Files:** `phases.md`, `sha256-roc-library-plan.md`.
        *   **Task:** Move these planning/development-specific markdown files into a subdirectory, e.g., `docs/dev/` or `meta/planning/`.
        *   **Why:** Keeps the root directory cleaner for users primarily interested in the library itself, rather than its development history.
        *   **Context Needed:** Repository root directory structure.

    3.  **Enhance `README.md` (Minor):**
        *   **File:** `README.md`.
        *   **Task:**
            *   Under "Running Tests", the commands `roc test` and `roc test tests/TestSha256.roc` are already good.
            *   Consider adding a "Compliance" or "Standards" section briefly mentioning adherence to FIPS 180-4.
            *   Review installation instructions for any updates based on Roc's package manager evolution (current placeholder is good).
        *   **Why:** Improves user information and confidence.
        *   **Context Needed:** `README.md` content.

---

**Phase 4: Final Review & Release Preparation**

*   **Context:** Last checks before considering the library ready for a stable release.
*   **Tasks:**

    1.  **Apply Code Formatting:**
        *   **Files:** All `.roc` files.
        *   **Task:** Run `roc format .` (or equivalent) at the project root to ensure all Roc code adheres to standard formatting.
        *   **Why:** Code consistency and readability.
        *   **Context Needed:** Roc formatting tool installed.

    2.  **Conduct a Final Code Review:**
        *   **Files:** Primarily `src/` and `tests/`.
        *   **Task:** Perform a final read-through of the codebase, looking for:
            *   Any remaining `TODO` comments or placeholders.
            *   Clarity of variable names and logic flow.
            *   Correct and idiomatic use of Roc standard library functions (cross-referencing `rocdocs.txt` for functions used).
            *   Potential unhandled edge cases (though NIST vectors are good, a quick mental check).
            *   Ensure all functions exposed by `Sha256.Internal` are truly necessary for `Sha256.roc` and that their purpose is clear (current exposure seems fine).
        *   **Why:** Catches any overlooked issues and polishes the overall code quality.
        *   **Context Needed:** Entire codebase.

    3.  **Validate `Package.roc` for Release:**
        *   **File:** `Package.roc`.
        *   **Task:** Confirm that the `package` name (e.g., `"roc-community/sha256"` or your preferred name), `version` (e.g., `"0.1.0"` seems appropriate for a first stable release after this plan), and `exposes` fields are accurate and ready for publishing/tagging.
        *   **Why:** Ensures the package is correctly defined for the Roc ecosystem.
        *   **Context Needed:** `Package.roc` content and desired package identity.

    4.  **Tag Release (Post-Completion):**
        *   **Task:** After all phases are completed and verified, create a Git tag (e.g., `v0.1.0`).
        *   **Why:** Marks a stable, versioned point for users to depend on.
        *   **Context Needed:** Git version control.
