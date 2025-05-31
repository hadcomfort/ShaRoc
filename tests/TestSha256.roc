module TestSha256 exposes [main]

imports [
    roc/Test exposing [describe, test, expectEq],
    ../src/Sha256 exposing [Sha256],
    ../src/Sha256/Internal exposing [bytesToHex]
]

main =
    describe "Sha256 Library Tests" [
        describe "bytesToHex Tests" [
            test "empty list" <| \{} ->
                expectEq (bytesToHex []) "",

            test "single zero byte" <| \{} ->
                expectEq (bytesToHex [0x00]) "00",

            test "single byte with leading hex zero" <| \{} ->
                expectEq (bytesToHex [0x0A]) "0a",

            test "single byte max value" <| \{} ->
                expectEq (bytesToHex [0xFF]) "ff",

            test "four bytes 'deadbeef'" <| \{} ->
                expectEq (bytesToHex [0xDE, 0xAD, 0xBE, 0xEF]) "deadbeef",

            test "multiple bytes with leading hex zeros" <| \{} ->
                expectEq (bytesToHex [0x01, 0x02, 0x03]) "010203",

            test "eight bytes common sequence" <| \{} ->
                expectEq (bytesToHex [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]) "0123456789abcdef",

            test "list of all zeros (4 bytes)" <| \{} ->
                expectEq (bytesToHex [0x00, 0x00, 0x00, 0x00]) "00000000",

            test "list of all 0xFF (4 bytes)" <| \{} ->
                expectEq (bytesToHex [0xFF, 0xFF, 0xFF, 0xFF]) "ffffffff"
        ]
    ]
