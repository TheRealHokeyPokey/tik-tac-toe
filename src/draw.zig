const std = @import("std");

const Io = std.Io;
const assert = std.debug.assert;
const sort = std.sort;
const hash_map = std.hash_map;

const Game = @import("game.zig");

const Board = Game.Board;
const Player = Game.Player;
const Cell = Game.Cell;
const MoveTuple = Game.MoveTuple;
const addMove = Game.addMove;
const getWinner = Game.getWinner;
const readMove = Game.readMove;

const Coord = struct {
    i: usize,
    j: usize,
};

const xFormat =
    \\\   /
    \\ \ /
    \\  X
    \\ / \
    \\/   \
;
const oFormat =
    \\ ---
    \\|   |
    \\| | |
    \\|   |
    \\ ---
;
const emptyFormat =
    \\
    \\  .
    \\
    \\  .
    \\
;

pub fn drawBoard(board: Board, writer: *Io.Writer) !void {
    assert(@TypeOf(board.cells) == [3][3]Cell);
    // try drawX(writer, .{ .i = 0, .j = 0 });
    var output_array: [15][15]u8 = undefined;
    knitBoard(board, &output_array);
    try printKnittedArray(writer, &output_array);
}

fn printKnittedArray(writer: *Io.Writer, array: *[15][15]u8) !void {
    for (0..array.len) |i| {
        for (0..array[i].len) |j| {
            try writer.writeByte(array[i][j]);
        }
        try writer.writeByte('\n');
    }
}

fn knitBoard(board: Board, knitted_array: *[15][15]u8) void {
    var symbol_array: [5][5]u8 = undefined;

    for (0..3) |i| {
        for (0..3) |j| {
            const cell_format = switch (board.cells[i][j]) {
                Cell.x => xFormat,
                Cell.o => oFormat,
                Cell.empty => emptyFormat,
            };
            try formatToSymbolArray(cell_format, &symbol_array);
            writeFormatToKnittedArray(i, j, &symbol_array, knitted_array);
        }
    }
}

fn writeFormatToKnittedArray(row: usize, col: usize, format: *[5][5]u8, knitted_array: *[15][15]u8) void {
    for (0..5) |i| {
        for (0..5) |j| {
            const knit_i = i + row * 5;
            const knit_j = j + col * 5;
            knitted_array[knit_i][knit_j] = format[i][j];
        }
    }
}

fn moveCursorToCell(writer: *Io.Writer, coord: Coord) !void {
    _ = coord;
    const row = 0;
    const col = 0;
    try moveCursorToPosition(row, col, writer);
}

fn formatToSymbolArray(format_string: []const u8, array: *[5][5]u8) !void {
    array.* = @splat(@splat(' '));
    var i: usize = 0;
    var j: usize = 0;
    for (format_string) |char| {
        if (char != '\n') {
            array[i][j] = char;
            j += 1;
        } else {
            j = 0;
            i += 1;
        }
    }
}

fn drawLineDown(writer: *Io.Writer, length: usize) !void {
    for (0..length) |_| {
        try writer.print("|", .{});
        try moveCursorLeftNCol(writer, 1);
        try moveCursorDownNRow(writer, 1);
    }
}

// moves the cursor to (colNumber, lineNumber)
fn moveCursorToPosition(row: usize, col: usize, writer: *Io.Writer) !void {
    assert(row < 128);
    assert(col < 128);
    try writer.print("\x1B[{d};{d}H", .{ row, col });
}

fn scrollUpNRow(writer: *Io.Writer, n_rows: usize) !void {
    for (0..n_rows) |_| {
        try writer.print("\x1B M", .{});
    }
}

fn moveCursorUpNRow(writer: *Io.Writer, n_rows: usize) !void {
    try writer.print("\x1B[{d}A", .{n_rows});
}

fn moveCursorDownNRow(writer: *Io.Writer, n_rows: usize) !void {
    try writer.print("\x1B[{d}B", .{n_rows});
}

fn moveCursorRightNCol(writer: *Io.Writer, n_cols: usize) !void {
    try writer.print("\x1B[{d}C", .{n_cols});
}

fn moveCursorLeftNCol(writer: *Io.Writer, n_cols: usize) !void {
    try writer.print("\x1B[{d}D", .{n_cols});
}

// saves the cursor position, to be restored with
// `restoreCursorPosition()`
fn saveANSICursorPosition(writer: *Io.Writer) !void {
    try writer.print("\x1B[s", .{});
}

// restores the cursor position that was saved with
// `saveCursorPosition`
fn restoreANSICursorPosition(writer: *Io.Writer) !void {
    try writer.print("\x1B[u", .{});
}

fn eraseLine(writer: *Io.Writer) !void {
    try writer.print("\x1B[2K", .{});
}
