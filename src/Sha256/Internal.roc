module Sha256.Internal exposes [rotr, shr, smallSigma0, smallSigma1, bytesToWordsBE, InvalidInput, generateMessageSchedule]

InvalidInput : []

rotr : U8, U32 -> U32
rotr = \n, val ->
    (Bitwise.shiftRightBy val n) |> Bitwise.or (Bitwise.shiftLeftBy val (32 - n))

shr : U8, U32 -> U32
shr = \n, val ->
    Bitwise.shiftRightBy val n

smallSigma0 : U32 -> U32
smallSigma0 = \val ->
    (rotr 7 val)
        |> Bitwise.xor (rotr 18 val)
        |> Bitwise.xor (shr 3 val)

smallSigma1 : U32 -> U32
smallSigma1 = \val ->
    (rotr 17 val)
        |> Bitwise.xor (rotr 19 val)
        |> Bitwise.xor (shr 10 val)

bytesToWordsBE : List U8 -> Result (List U32) InvalidInput
bytesToWordsBE = \messageChunk ->
    if List.len messageChunk == 64 then
        words =
            messageChunk
                |> List.chunksOf 4
                |> List.map \chunk ->
                    b1 = List.get chunk 0 |> Result.withDefault 0
                    b2 = List.get chunk 1 |> Result.withDefault 0
                    b3 = List.get chunk 2 |> Result.withDefault 0
                    b4 = List.get chunk 3 |> Result.withDefault 0

                    (Bitwise.shiftLeftBy (Num.toU32 b1) 24)
                        |> Bitwise.or (Bitwise.shiftLeftBy (Num.toU32 b2) 16)
                        |> Bitwise.or (Bitwise.shiftLeftBy (Num.toU32 b3) 8)
                        |> Bitwise.or (Num.toU32 b4)

        Ok words
    else
        Err InvalidInput

generateMessageSchedule : List U8 -> Result (List U32) InvalidInput
generateMessageSchedule = \messageChunk ->
    bytesToWordsBE messageChunk
    |> Result.try \initialWords ->
        # Helper function to recursively build the schedule
        buildSchedule = \currentSchedule, currentIndex ->
            if currentIndex == 64 then
                currentSchedule
            else
                # Indices for w[i-2], w[i-7], w[i-15], w[i-16]
                # Need to handle potential out-of-bounds if using List.get directly,
                # but currentSchedule will grow, so List.getUnsafe is an option if careful.
                # Or, ensure currentSchedule is accessed safely.
                # Roc's List.get returns a Result, which is safer.

                # For List.get, need to handle the Result if a value might not exist,
                # though for this algorithm, they should always exist after the initial 16 words.
                # Using List.getUnsafe for simplicity here, assuming valid indices based on algorithm logic.
                # A production system might prefer List.get and error handling or safer indexing.

                wIMinus2 = List.getUnsafe currentSchedule (currentIndex - 2)
                wIMinus7 = List.getUnsafe currentSchedule (currentIndex - 7)
                wIMinus15 = List.getUnsafe currentSchedule (currentIndex - 15)
                wIMinus16 = List.getUnsafe currentSchedule (currentIndex - 16)

                s1 = smallSigma1 wIMinus2
                s0 = smallSigma0 wIMinus15

                # U32 addition wraps by default in Roc
                newWord = s1 + wIMinus7 + s0 + wIMinus16

                nextSchedule = List.append currentSchedule newWord
                buildSchedule nextSchedule (currentIndex + 1)

        # Start building the schedule from the initial 16 words,
        # beginning calculation for index 16.
        finalSchedule = buildSchedule initialWords 16
        Ok finalSchedule

#
# Inline Tests for Bitwise Helpers
#

expectU32Crash : U32, U32, Str -> {}
expectU32Crash = \actual, expected, description ->
    if actual == expected then
        {}
    else
        crash "Assertion failed: \(description). Expected 0x\(Num.toHex expected), got 0x\(Num.toHex actual)"

runBitwiseHelperTests : {}
runBitwiseHelperTests =
    # Tests for rotr
    expectU32Crash (rotr 8 0x12345678) 0x78123456 "rotr(8, 0x12345678)"
    expectU32Crash (rotr 0 0x12345678) 0x12345678 "rotr(0, 0x12345678)"
    expectU32Crash (rotr 32 0x12345678) 0x12345678 "rotr(32, 0x12345678)"
    # Test with a value where bits shifted out from right are different from bits shifted in from left
    expectU32Crash (rotr 4 0xABCDEF01) 0x1ABCDEF0 "rotr(4, 0xABCDEF01)"

    # Tests for shr
    expectU32Crash (shr 4 0x12345678) 0x01234567 "shr(4, 0x12345678)"
    expectU32Crash (shr 0 0x12345678) 0x12345678 "shr(0, 0x12345678)"
    expectU32Crash (shr 32 0x12345678) 0x00000000 "shr(32, 0x12345678)"
    expectU32Crash (shr 8 0xFF00FF00) 0x00FF00FF "shr(8, 0xFF00FF00)"

    # Tests for smallSigma0
    # x = 0x6a09e667
    # rotr(7,x)  = 0x0d413ccd (Note: prompt had 'u' suffix, Roc U32 literal doesn't use it)
    # rotr(18,x) = 0x99a279a1
    # shr(3,x)   = 0x0d413ccd
    # Expected: 0x0d413ccd XOR 0x99a279a1 XOR 0x0d413ccd = 0x99a279a1
    expectU32Crash (smallSigma0 0x6a09e667) 0x99a279a1 "smallSigma0(0x6a09e667)"

    # Tests for smallSigma1
    # x = 0xbb67ae85
    # rotr(17,x) = 0x5d9d75dd
    # rotr(19,x) = 0x75ddbb67
    # shr(10,x)  = 0x2ee1ebba
    # Expected: 0x5d9d75dd XOR 0x75ddbb67 XOR 0x2ee1ebba = 0x0c0518c9
    expectU32Crash (smallSigma1 0xbb67ae85) 0x0c0518c9 "smallSigma1(0xbb67ae85)"

    {} # Return empty record to match type

# Run tests when module is loaded (useful for development feedback)
# If this causes issues in a library context, it might be commented out or handled differently.
_ = runBitwiseHelperTests

#
# Inline Tests for Message Schedule Generation
#

messageChunk_abc_bytes : List U8
messageChunk_abc_bytes =
    [0x61, 0x62, 0x63, 0x80]
        |> List.concat (List.repeat 0x00 52)
        |> List.concat [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18]

expected_schedule_abc_prefix : List U32
expected_schedule_abc_prefix =
    [
        0x61626380, # W[0]
        0x00000000, # W[1]
        0x00000000, # W[2]
        0x00000000, # W[3]
        0x00000000, # W[4]
        0x00000000, # W[5]
        0x00000000, # W[6]
        0x00000000, # W[7]
        0x00000000, # W[8]
        0x00000000, # W[9]
        0x00000000, # W[10]
        0x00000000, # W[11]
        0x00000000, # W[12]
        0x00000000, # W[13]
        0x00000000, # W[14]
        0x00000018, # W[15]
        0x61626380, # W[16] = s1(W[14]) + W[7] + s0(W[1]) + W[0]
                    # s1(0) = 0; W[7]=0; s0(0)=0; W[0]=0x61626380 => 0x61626380
        0x000F0000, # W[17] = s1(W[15]) + W[8] + s0(W[2]) + W[1]
                    # s1(0x18) = 0x000F0000; W[8]=0; s0(0)=0; W[1]=0 => 0x000F0000
    ]

runMessageScheduleTests : {}
runMessageScheduleTests =
    scheduleResult = generateMessageSchedule messageChunk_abc_bytes

    when scheduleResult is
        Err InvalidInput ->
            crash "generateMessageSchedule returned InvalidInput for 'abc' chunk"

        Ok actualScheduleWords ->
            # Check length of the whole schedule
            if List.len actualScheduleWords != 64 then
                crash "generateMessageSchedule for 'abc' did not return 64 words. Got: \(List.len actualScheduleWords)"
            else
                # Check prefix
                List.walkWithIndex expected_schedule_abc_prefix {} \index, acc, expectedWord ->
                    actualWord = List.getUnsafe actualScheduleWords index # Safe due to length check of expected_schedule_abc_prefix
                    description = "W[\(Num.toStr index)] for 'abc'"
                    expectU32Crash actualWord expectedWord description
                    acc

    {} # Return empty record

_ = runMessageScheduleTests
