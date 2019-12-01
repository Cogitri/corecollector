module corecollector.lz4;

import hunt.logging;

import core.stdc.stdlib;
import std.exception;
import std.format;
import std.stdio;

extern (C) {
    /// Determine the maximum size LZ4 is going to compress the data of size `inputSize` to
    /// in the worst case scenario
    int LZ4_compressBound(in int inputSize) @nogc;
    /// Compress data provided in `src` to the already allocated `dst`. srcSize is the size of the
    /// uncompressed data, `dstCapacity` is the size of the `dst`.
    int LZ4_compress_default(in char* src, char* dst, in int srcSize, in int dstCapacity) @nogc;
    /// Decompress the data provided in `src` to the already allocated `dst`. compressedSize is the size
    /// of the compressed data, `dstCapacity` is the size of `dst`
    int LZ4_decompress_safe(in char* src, char* dst, in int compressedSize, in int srcSize) @nogc;
}

/// Compress the data in `uncompressedData` with LZ4 compression.
ubyte[] compressData(in ubyte[] uncompressedData) {
    immutable int uncompressedDataSize = cast(int)uncompressedData.length * cast(int)ubyte.sizeof;
    immutable auto maxDstSize = LZ4_compressBound(uncompressedDataSize);
    char* compressedData = cast(char*)malloc(maxDstSize);

    if(!compressedData) {
        assert(0, "Out of memory!");
    }

    if (compressedData == null)
        assert(0, "Failed to allocate memory for *compressedData.");
    const auto compressedDataSize =
        LZ4_compress_default(cast(char*)uncompressedData.ptr, compressedData, uncompressedDataSize, maxDstSize);
    if (compressedDataSize <= 0) {
        enforce(0, "A 0 or negative result from LZ4_compress_default indicates a failure trying to compress the data.");
    } else {
        logDebugf(
            "We successfully compressed some data! Compressed: %d, Uncompressed %d\nCompressed data: %s",
            compressedDataSize,
            uncompressedDataSize,
            compressedData[0 .. (compressedDataSize / char.sizeof)],
        );
    }

    // Reallocate to make sure our array is only as big as the compressed object is
    auto compressedDataArr = realloc(compressedData, compressedDataSize)[0 .. (compressedDataSize / char.sizeof)];
    return cast(ubyte[])compressedDataArr;
}

/// Decompress LZ4 data in `compressedData`. The uncompressedData may only be `uncompressedDataSize`
/// big.
ubyte[] decompressData(in ubyte[] compressedData, in uint uncompressedDataSize) {
    immutable auto compressedDataSize = cast(int)compressedData.length * cast(int)char.sizeof;

    logDebugf("Trying to decompress data %s", cast(char[])compressedData);

    auto uncompressedData = cast(char*)malloc(uncompressedDataSize);
    auto decompressedDataSize =
        LZ4_decompress_safe(cast(char*)compressedData.ptr, uncompressedData, compressedDataSize, uncompressedDataSize);
    if (decompressedDataSize < 0) {
        enforce(0, "A 0 or negative result from LZ4_decompress_safe indicates a failure tying to decompress the data.");
    } else { 
        logDebugf(
            "We sucessfully decompressed some data! Uncompressed: %d, Compressed: %d\n",
            decompressedDataSize,
            compressedDataSize,
        );
    }
    return cast(ubyte[])uncompressedData[0..(decompressedDataSize / char.sizeof)];
}

unittest {
    import std.format : format;

    const char[] testString =
        "11111111111111111111111111111111112222222222222221111111111111111110000000000000011111111111111111111";

    const auto compressedString = compressData(cast(ubyte[])testString);
    const ubyte[] expectedCompressedVal =
        [31, 49, 1, 0, 14, 26, 50, 1, 0, 14, 48, 0, 25, 48, 1, 0, 11, 32, 0, 80, 49, 49, 49, 49, 49];
    assert(
        expectedCompressedVal == compressedString,
        format("Expected %s, got %s", expectedCompressedVal, compressedString),
    );

    const auto uncompressedDataSize = cast(int)testString.length * cast(int)char.sizeof;
    const auto reDecompressedString = cast(char[])decompressData(compressedString, uncompressedDataSize);
    assert(
        testString == reDecompressedString,
        format("Expected %s, got %s", testString, reDecompressedString),
    );
}

unittest {
    static import std.file;
    import std.format: format;

    immutable auto testString = "111112312dsjaidwaoüo2ji1ü32222";
    const auto compressedTestString = compressData(cast(ubyte[])testString);

    const auto testFile = std.file.deleteme();
    scope(exit)
        std.file.remove(testFile);
    auto file = File(testFile, "w");
    
    file.rawWrite(compressedTestString);
    file.close();
    auto testFileHandle = File(testFile, "r");

    const auto readCompressedTestString = testFileHandle.rawRead(new char[4096]);

    assert(compressedTestString == readCompressedTestString,
        format("Expected %s, got %s", compressedTestString, readCompressedTestString));

    const auto decompressedString =
        cast(char[])decompressData(cast(ubyte[])readCompressedTestString, testString.length * char.sizeof);

    assert(testString == decompressedString,
        format("Expected %s, got %s", testString, decompressedString));
}
