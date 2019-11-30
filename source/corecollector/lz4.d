module corecollector.lz4;

import hunt.logging;

import core.stdc.stdlib;
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
    int LZ4_decompress_safe(in char* src, char* dst, in int compressedSize, in int dstCapacity) @nogc;
}

/// Compression
ubyte[] compressData(const ubyte[] uncompressedData) {
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
        assert(0, "A 0 or negative result from LZ4_compress_default indicates a failure trying to compress the data.");
    } else {
        logDebugf(
            "We successfully compressed some data! Compressed: %d, Uncompressed %d\n",
            compressedDataSize,
            uncompressedDataSize
        );
    }

    immutable auto arrayLength = compressedDataSize / char.sizeof;
    return cast(ubyte[])compressedData[0..arrayLength];
}

/// Decompression
ubyte[] decompressData(const ubyte[] compressedData, uint uncompressedDataSize) {
    immutable auto compressedDataSize = cast(int)compressedData.length * cast(int)char.sizeof;

    auto uncompressedData = cast(char*)malloc(uncompressedDataSize);
    LZ4_decompress_safe(cast(char*)compressedData.ptr, uncompressedData, compressedDataSize, uncompressedDataSize);
    return cast(ubyte[])uncompressedData[0..(uncompressedDataSize / char.sizeof)];
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
