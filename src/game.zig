const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;
const ascii = std.ascii;
const fmt = std.fmt;

pub const Cell = enum { empty, x, o };
pub const Player = enum { x, o };

pub const MoveError = error{ OutOfBounds, CellFull, Unrecoverable };
const OutOfBounds = MoveError.OutOfBounds;
const CellFull = MoveError.CellFull;
const Unrecoverable = MoveError.Unrecoverable;

const InvalidCharacter = fmt.ParseIntError.InvalidCharacter;

pub const MoveTuple = struct {
    i: u2,
    j: u2,
};

pub const Board = struct {
    const Self = @This();

    cells: [3][3]Cell = @splat(@splat(Cell.empty)),
    next_player: Player = Player.x,

    pub fn format(self: Self, writer: *Io.Writer) !void {
        assert(@TypeOf(self.cells) == [3][3]Cell);
        const cells = self.cells;

        for (0..3) |i| {
            try writer.print("{t: <5}", .{cells[i][0]});
            for (1..3) |j| {
                try writer.print(", {t: <5}", .{cells[i][j]});
            }
            try writer.print("\n", .{});
        }
    }
};

pub fn readValidMove(
    writer: *Io.Writer,
    reader: *Io.Reader,
    board: Board,
) !MoveTuple {
    while (true) {
        const move = readMove(writer, reader, board);
        if (move) |valid_move| {
            return valid_move;
        } else |err| {
            switch (err) {
                OutOfBounds, CellFull, InvalidCharacter => {
                    std.log.err(
                        "{}, selected move was invalid",
                        .{err},
                    );
                    continue;
                },
                else => return Unrecoverable,
            }
        }
    }
}

// prompts the player to enter a move, read from stdin
pub fn readMove(
    writer: *Io.Writer,
    reader: *Io.Reader,
    board: Board,
) !MoveTuple {
    const next_player_code: u8 = if (board.next_player == Player.x) 'X' else 'O';
    try writer.print(
        "Next player: {c}\n" ++
            "Please enter your move as coordinates in [0..2]\n" ++
            "Format: <row>_<col>\n",
        .{next_player_code},
    );
    try writer.flush();

    const raw_row_bytes = try reader.takeDelimiter(' ');
    const row = try parseBytesAsIndex(raw_row_bytes);

    const raw_col_bytes = try reader.takeDelimiter('\n');
    const col = try parseBytesAsIndex(raw_col_bytes);

    if (board.cells[row][col] != Cell.empty) {
        return CellFull;
    }

    try writer.print("\nMove selected: ({}, {})\n", .{ row, col });
    try writer.flush();

    return .{ .i = row, .j = col };
}

fn parseBytesAsIndex(raw_bytes: ?[]u8) !u2 {
    if (raw_bytes == null) {
        return InvalidCharacter;
    }
    const bytes = raw_bytes.?;
    const index = std.fmt.parseInt(u2, bytes, 10) catch |err| switch (err) {
        std.fmt.ParseIntError.Overflow => return OutOfBounds,
        else => return err,
    };
    if (2 < index or index < 0) {
        return OutOfBounds;
    }
    return index;
}

// returns the Cell corresponding to the first line of length 3 of the
// same Cell type, or null if there is no winner
pub fn getWinner(board: Board) ?Player {
    assert(@TypeOf(board.cells) == [3][3]Cell);
    const cells = board.cells;

    const winning_cell = blk: {
        // check horizonal lines
        for (0..3) |i| {
            if (cells[i][0] == cells[i][1] and cells[i][1] == cells[i][2]) {
                break :blk cells[i][2];
            }
        }
        // check vertical lines
        for (0..3) |j| {
            if (cells[0][j] == cells[1][j] and cells[1][j] == cells[2][j])
                break :blk cells[2][j];
        }
        // check down-right diagonal lines
        if (cells[0][0] == cells[1][1] and cells[1][1] == cells[2][2]) {
            break :blk cells[2][2];
        }
        // check up-right diagonal lines
        if (cells[2][0] == cells[1][1] and cells[1][1] == cells[0][2]) {
            break :blk cells[0][2];
        }
        break :blk null;
    };

    if (winning_cell == Cell.x) {
        return Player.x;
    } else if (winning_cell == Cell.o) {
        return Player.o;
    }
    return null;
}

// adds a move to the board, changes the cell to match the player
pub fn addMove(board: *Board, move_tuple: MoveTuple) MoveError!void {
    const i = move_tuple.i;
    const j = move_tuple.j;
    var cells = &board.cells;
    const next_player = board.next_player;

    if (i > 2 or j > 2) {
        return OutOfBounds;
    }
    if (cells[i][j] != Cell.empty) {
        return CellFull;
    }
    const player_cell = if (next_player == Player.x) Cell.x else Cell.o;
    cells[i][j] = player_cell;
    board.next_player = if (next_player == Player.x) Player.o else Player.x;
}
