module TestSha256 exposes [main]

imports [
    roc/Test exposing [describe, test, expect, expectEq],
    # Assuming Sha256 will be exposed by a package in the future,
    # or that the build system handles relative paths appropriately.
    # For now, this import path might need adjustment based on how
    # the project is built/structured locally.
    # Consider using a placeholder if direct relative import is problematic
    # e.g. app "org.example.sha256" provides [Sha256] to "./app.roc"
    # For a library, this might be handled by the package system.
    # Using a relative path for now as a common starting point.
    ../src/Sha256 exposing [Sha256] # Adjust if needed for actual Roc project structure
]

main =
    describe "Sha256 Library Tests" [
        test "Initial placeholder test" <| \{} ->
            expectEq 1 1
    ]
