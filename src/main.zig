const std = @import("std");

const ArgIterator = std.process.ArgIterator;
const File = std.fs.File;

pub fn main() !void {
    var generalPurposeAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = generalPurposeAllocator.deinit();
    const allocator = generalPurposeAllocator.allocator();
    var argIterator = try ArgIterator.initWithAllocator(allocator);
    defer argIterator.deinit();
    _ = argIterator.next();
    const path = argIterator.next().?;
    const file = try std.fs.openFileAbsolute(path, .{});
    const source = try File.readToEndAlloc(file, allocator, std.math.maxInt(usize));
    defer allocator.free(source);
    var buffer = source;
    buffer.len = try uncomment(source, buffer);
    std.debug.print("{s}", .{buffer});
}

test "simple test" {

}

fn uncomment(source: []const u8, buffer: []u8) !usize {
    const State = enum {
        Transcribe,
        SearchComment,
        IgnoreComment,
    };

    var state: State = .Transcribe;
    var sourceIndex: usize = 0;
    var sourceStart: usize = 0;
    var bufferIndex: usize = 0;
    var bufferStart: usize = 0;
    var nonWhitespaceEncountered = false;
    while (sourceIndex < source.len) {
        switch (state) {
            .SearchComment => {
                switch (source[sourceIndex]) {
                    std.ascii.whitespace[0],
                    std.ascii.whitespace[1],
                    // std.ascii.whitespace[2],
                    std.ascii.whitespace[3],
                    std.ascii.whitespace[4],
                    std.ascii.whitespace[5] => {

                    },
                    '\n' => {
                        sourceStart = sourceIndex + 1;
                    },
                    '/' => {
                        if (sourceIndex < source.len - 1) {
                            if (source[sourceIndex + 1] == '/') {
                                state = .IgnoreComment;
                            }
                        } else {
                            buffer[bufferIndex] = source[sourceIndex];
                            bufferIndex = bufferIndex + 1;
                        }
                    },
                    else => {
                        state = .Transcribe;
                        bufferIndex = bufferStart;
                        std.mem.copy(u8, buffer[bufferIndex..], source[sourceStart..sourceIndex]);
                        bufferIndex = bufferIndex + sourceIndex - sourceStart;
                        buffer[bufferIndex] = source[sourceIndex];
                        bufferIndex = bufferIndex + 1;
                    }
                }
                sourceIndex = sourceIndex + 1;
            },
            .IgnoreComment => {
                switch (source[sourceIndex]) {
                    '\n' => {
                        sourceStart = sourceIndex + 1;
                        buffer[bufferIndex] = source[sourceIndex];
                        bufferIndex = bufferIndex + 1;
                        state = .SearchComment;
                    },
                    else => {
                    }
                }
                sourceIndex = sourceIndex + 1;
            },
            .Transcribe => {
                switch (source[sourceIndex]) {
                    std.ascii.whitespace[0],
                    std.ascii.whitespace[1],
                    // std.ascii.whitespace[2],
                    std.ascii.whitespace[3],
                    std.ascii.whitespace[4],
                    std.ascii.whitespace[5] => {
                        buffer[bufferIndex] = source[sourceIndex];
                        bufferIndex = bufferIndex + 1;
                    },
                    '\n' => {
                        sourceStart = sourceIndex + 1;
                        bufferStart = bufferIndex + 1;
                        buffer[bufferIndex] = source[sourceIndex];
                        bufferIndex = bufferIndex + 1;
                        nonWhitespaceEncountered = false;
                    },
                    '/' => {
                        if (sourceIndex < source.len - 1) {
                            if (source[sourceIndex + 1] == '/') {
                                state = .IgnoreComment;
                                if (nonWhitespaceEncountered)
                                    bufferStart = bufferIndex + 1;
                                nonWhitespaceEncountered = false;
                            }
                        } else {
                            buffer[bufferIndex] = source[sourceIndex];
                            bufferIndex = bufferIndex + 1;
                        }
                    },
                    else => {
                        nonWhitespaceEncountered = true;
                        buffer[bufferIndex] = source[sourceIndex];
                        bufferIndex = bufferIndex + 1;
                    }
                }
                sourceIndex = sourceIndex + 1;
            },
        }
    }
    return bufferIndex;
}
