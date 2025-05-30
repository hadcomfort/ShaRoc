module Sha256.Internal exposing [rotr, shr, smallSigma0, smallSigma1, ch, maj, bigSigma0, bigSigma1, bytesToWordsBE, InvalidInput, generateMessageSchedule, processChunk, Sha256State, sha256Once, padMessage, u32sToBytes, bytesToHex]

# Placeholder for padMessage
padMessage : List U8 -> List U8
padMessage = \message -> message # Actual padding logic will be implemented later

# Placeholder for u32sToBytes
u32sToBytes : List U32 -> List U8
u32sToBytes = \_u32s -> List.repeat 0 32 # Actual conversion logic will be implemented later (expects 8 U32s, returns 32 U8s)

bytesToHex : List U8 -> Str
bytesToHex = \bytes ->
    bytes
        |> List.walk "" \acc, byte ->
            hexByte = Num.toHex byte
            if Str.countChars hexByte == 1 then
                acc |> Str.concat "0" |> Str.concat hexByte
            else
                acc |> Str.concat hexByte

Sha256State : {
    h0 : U32,
    h1 : U32,
    h2 : U32,
    h3 : U32,
    h4 : U32,
    h5 : U32,
    h6 : U32,
    h7 : U32,
}

# Initial Hash Values (H0-H7)
h0 : U32 = 0x6a09e667
h1 : U32 = 0xbb67ae85
h2 : U32 = 0x3c6ef372
h3 : U32 = 0xa54ff53a
h4 : U32 = 0x510e527f
h5 : U32 = 0x9b05688c
h6 : U32 = 0x1f83d9ab
h7 : U32 = 0x5be0cd19

# Round Constants (K)
kConstants : List U32 = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

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

ch : U32, U32, U32 -> U32
ch = \x, y, z ->
    (Bitwise.and x y)
        |> Bitwise.xor (Bitwise.and (Bitwise.not x) z)

maj : U32, U32, U32 -> U32
maj = \x, y, z ->
    (Bitwise.and x y)
        |> Bitwise.xor (Bitwise.and x z)
        |> Bitwise.xor (Bitwise.and y z)

bigSigma0 : U32 -> U32
bigSigma0 = \x ->
    (rotr 2 x)
        |> Bitwise.xor (rotr 13 x)
        |> Bitwise.xor (rotr 22 x)

bigSigma1 : U32 -> U32
bigSigma1 = \x ->
    (rotr 6 x)
        |> Bitwise.xor (rotr 11 x)
        |> Bitwise.xor (rotr 25 x)

sha256Once : List U8 -> List U8
sha256Once = \message ->
    # 1. Initialize hash values
    initialState : Sha256State = {
        h0: h0, # These refer to the global h0-h7 constants
        h1: h1,
        h2: h2,
        h3: h3,
        h4: h4,
        h5: h5,
        h6: h6,
        h7: h7,
    }

    # 2. Pad the message
    paddedMessage = padMessage message

    # 3. Process message in 512-bit (64-byte) chunks
    finalState =
        paddedMessage
            |> List.chunksOf 64 # Process in 64-byte chunks
            |> List.walk initialState \currentChunkState, chunk ->
                # a. Generate message schedule (W) for the current chunk
                when generateMessageSchedule chunk is
                    Ok scheduleW ->
                        # b. Process the chunk with the current hash state
                        processChunk currentChunkState scheduleW
                    Err InvalidInput ->
                        # This case should ideally not happen with correct padding
                        # For now, crash or return an error state; let's crash.
                        crash "Invalid input to generateMessageSchedule during sha256Once"

    # 4. Convert final hash state (List U32) to List U8
    # The Sha256State record needs to be converted to a list of U32 first.
    finalHashesU32 = [
        finalState.h0,
        finalState.h1,
        finalState.h2,
        finalState.h3,
        finalState.h4,
        finalState.h5,
        finalState.h6,
        finalState.h7,
    ]
    u32sToBytes finalHashesU32

processChunk : Sha256State, List U32 -> Sha256State
processChunk = \currentState, w ->
    # Initialize working variables from the current hash state
    workingVars = {
        a: currentState.h0,
        b: currentState.h1,
        c: currentState.h2,
        d: currentState.h3,
        e: currentState.h4,
        f: currentState.h5,
        g: currentState.h6,
        h: currentState.h7,
    }

    # Perform 64 rounds of computation
    finalWorkingVars =
        List.range 0 63 # Generates a list [0, 1, ..., 63]
        |> List.walk workingVars \t, currentIterVars ->
            # s1 = bigSigma1 e
            s1 = bigSigma1 currentIterVars.e

            # chVal = ch e f g
            chVal = ch currentIterVars.e currentIterVars.f currentIterVars.g

            # k_t = List.getUnsafe kConstants t
            k_t = List.getUnsafe kConstants t

            # w_t = List.getUnsafe w t
            w_t = List.getUnsafe w t

            # temp1 = h + s1 + chVal + k_t + w_t
            temp1 = currentIterVars.h + s1 + chVal + k_t + w_t # U32 addition wraps

            # s0 = bigSigma0 a
            s0 = bigSigma0 currentIterVars.a

            # majVal = maj a b c
            majVal = maj currentIterVars.a currentIterVars.b currentIterVars.c

            # temp2 = s0 + majVal
            temp2 = s0 + majVal # U32 addition wraps

            # Update working variables for the next iteration
            {
                a: temp1 + temp2, # a = temp1 + temp2
                b: currentIterVars.a, # b = a
                c: currentIterVars.b, # c = b
                d: currentIterVars.c, # d = c
                e: currentIterVars.d + temp1, # e = d + temp1
                f: currentIterVars.e, # f = e
                g: currentIterVars.f, # g = f
                h: currentIterVars.g, # h = g
            }

    # Compute new intermediate hash values
    {
        h0: currentState.h0 + finalWorkingVars.a,
        h1: currentState.h1 + finalWorkingVars.b,
        h2: currentState.h2 + finalWorkingVars.c,
        h3: currentState.h3 + finalWorkingVars.d,
        h4: currentState.h4 + finalWorkingVars.e,
        h5: currentState.h5 + finalWorkingVars.f,
        h6: currentState.h6 + finalWorkingVars.g,
        h7: currentState.h7 + finalWorkingVars.h,
    }

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
                wIMinus2 = List.getUnsafe currentSchedule (currentIndex - 2)
                wIMinus7 = List.getUnsafe currentSchedule (currentIndex - 7)
                wIMinus15 = List.getUnsafe currentSchedule (currentIndex - 15)
                wIMinus16 = List.getUnsafe currentSchedule (currentIndex - 16)

                s1 = smallSigma1 wIMinus2
                s0 = smallSigma0 wIMinus15

                newWord = s1 + wIMinus7 + s0 + wIMinus16

                nextSchedule = List.append currentSchedule newWord
                buildSchedule nextSchedule (currentIndex + 1)

        finalSchedule = buildSchedule initialWords 16
        Ok finalSchedule

#
# Inline Tests
#

expectU32Crash : U32, U32, Str -> {}
expectU32Crash = \actual, expected, description ->
    if actual == expected then
        {}
    else
        crash "Assertion failed: \(description). Expected 0x\(Num.toHex expected), got 0x\(Num.toHex actual)"

expectStrCrash : Str, Str, Str -> {}
expectStrCrash = \actual, expected, description ->
    if actual == expected then
        {}
    else
        crash "Assertion failed: \(description). Expected \"\(expected)\", got \"\(actual)\""

runBitwiseHelperTests : {}
runBitwiseHelperTests =
    # Tests for rotr
    expectU32Crash (rotr 8 0x12345678) 0x78123456 "rotr(8, 0x12345678)"
    expectU32Crash (rotr 0 0x12345678) 0x12345678 "rotr(0, 0x12345678)"
    expectU32Crash (rotr 32 0x12345678) 0x12345678 "rotr(32, 0x12345678)"
    expectU32Crash (rotr 4 0xABCDEF01) 0x1ABCDEF0 "rotr(4, 0xABCDEF01)"

    # Tests for shr
    expectU32Crash (shr 4 0x12345678) 0x01234567 "shr(4, 0x12345678)"
    expectU32Crash (shr 0 0x12345678) 0x12345678 "shr(0, 0x12345678)"
    expectU32Crash (shr 32 0x12345678) 0x00000000 "shr(32, 0x12345678)"
    expectU32Crash (shr 8 0xFF00FF00) 0x00FF00FF "shr(8, 0xFF00FF00)"

    # Tests for smallSigma0
    expectU32Crash (smallSigma0 0x6a09e667) 0x99a279a1 "smallSigma0(0x6a09e667)"

    # Tests for smallSigma1
    expectU32Crash (smallSigma1 0xbb67ae85) 0x0c0518c9 "smallSigma1(0xbb67ae85)"

    # Tests for ch
    expectU32Crash (ch 0x510e527f 0x9b05688c 0x1f83d9ab) 0x1f84198c "ch(H4,H5,H6 initial)"

    # Tests for maj
    expectU32Crash (maj 0x6a09e667 0xbb67ae85 0x3c6ef372) 0x306e0067 "maj(H0,H1,H2 initial)"

    # Tests for bigSigma0
    expectU32Crash (bigSigma0 0x6a09e667) 0x50864d0d "bigSigma0(0x6a09e667)"

    # Tests for bigSigma1
    expectU32Crash (bigSigma1 0x510e527f) 0x79c66d87 "bigSigma1(0x510e527f)"

    {}

runMessageScheduleTests : {}
runMessageScheduleTests =
    scheduleResult = generateMessageSchedule messageChunk_abc_bytes

    when scheduleResult is
        Err InvalidInput ->
            crash "generateMessageSchedule returned InvalidInput for 'abc' chunk"

        Ok actualScheduleWords ->
            if List.len actualScheduleWords != 64 then
                crash "generateMessageSchedule for 'abc' did not return 64 words. Got: \(List.len actualScheduleWords)"
            else
                List.walkWithIndex expected_schedule_abc_prefix {} \index, acc, expectedWord ->
                    actualWord = List.getUnsafe actualScheduleWords index
                    description = "W[\(Num.toStr index)] for 'abc'"
                    expectU32Crash actualWord expectedWord description
                    acc
    {}

runProcessChunkTests : {}
runProcessChunkTests =
    initialState : Sha256State = {
        h0: h0, h1: h1, h2: h2, h3: h3,
        h4: h4, h5: h5, h6: h6, h7: h7,
    }
    scheduleResult = generateMessageSchedule messageChunk_abc_bytes
    when scheduleResult is
        Err InvalidInput ->
            crash "processChunk test: generateMessageSchedule failed for 'abc' chunk"
        Ok schedule_W ->
            newState = processChunk initialState schedule_W
            expectU32Crash newState.h0 0x29019097 "processChunk 'abc' H0'"
            expectU32Crash newState.h1 0xf8355c50 "processChunk 'abc' H1'"
            expectU32Crash newState.h2 0x51092d3c "processChunk 'abc' H2'"
            expectU32Crash newState.h3 0x8a4d6170 "processChunk 'abc' H3'"
            expectU32Crash newState.h4 0x57690f29 "processChunk 'abc' H4'"
            expectU32Crash newState.h5 0x705cec03 "processChunk 'abc' H5'"
            expectU32Crash newState.h6 0x4e9f139d "processChunk 'abc' H6'"
            expectU32Crash newState.h7 0x4009f386 "processChunk 'abc' H7'"
    {}

runBytesToHexTests : {}
runBytesToHexTests =
    expectStrCrash (bytesToHex []) "" "bytesToHex []"
    expectStrCrash (bytesToHex [0x00]) "00" "bytesToHex [0x00]"
    expectStrCrash (bytesToHex [0x0A]) "0a" "bytesToHex [0x0A]"
    expectStrCrash (bytesToHex [0xFF]) "ff" "bytesToHex [0xFF]"
    expectStrCrash (bytesToHex [0xDE, 0xAD, 0xBE, 0xEF]) "deadbeef" "bytesToHex [0xDE, 0xAD, 0xBE, 0xEF]"
    expectStrCrash (bytesToHex [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]) "0123456789abcdef" "bytesToHex [0x01,...,0xEF]"
    expectStrCrash (bytesToHex [0x0C, 0x0A, 0x0F, 0x0E]) "0c0a0f0e" "bytesToHex [0x0C, 0x0A, 0x0F, 0x0E]"
    {}

messageChunk_abc_bytes : List U8
messageChunk_abc_bytes =
    [0x61, 0x62, 0x63, 0x80]
        |> List.concat (List.repeat 0x00 52)
        |> List.concat [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18]

expected_schedule_abc_prefix : List U32
expected_schedule_abc_prefix =
    [
        0x61626380, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000018,
        0x61626380, 0x000F0000,
    ]

# Run tests when module is loaded
_ = runBitwiseHelperTests
_ = runMessageScheduleTests
_ = runProcessChunkTests
_ = runBytesToHexTests
