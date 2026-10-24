const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;
const ascii = std.ascii;

pub const Cell = enum { empty, x, o };
pub const Player = enum { x, o };

pub const InvalidMoveError = error{ OutOfBounds, CellFull };

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

pub fn readMove(writer: *Io.Writer, reader: *Io.Reader, board: Board) !MoveTuple {
    try writer.print("Next player: {}\nPlease enter your move <row> <col>: ", .{board.next_player});
    try writer.flush();

    const row_bytes_optional = try reader.takeDelimiter(' ');
    const row_bytes = row_bytes_optional.?;
    const row = try std.fmt.parseInt(u2, row_bytes, 10);
    assert(row <= 2);

    const col_bytes_optional = try reader.takeDelimiter('\n');
    const col_bytes = col_bytes_optional.?;
    const col = try std.fmt.parseInt(u2, col_bytes, 10);
    assert(col <= 2);

    try writer.print("\nMove selected: ({}, {})\n", .{ row, col });
    try writer.flush();

    return .{ .i = row, .j = col };
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
pub fn addMove(board: *Board, move_tuple: MoveTuple) InvalidMoveError!void {
    const i = move_tuple.i;
    const j = move_tuple.j;
    var cells = &board.cells;
    const next_player = board.next_player;

    if (i > 2 or j > 2) {
        return InvalidMoveError.OutOfBounds;
    }
    if (cells[i][j] != Cell.empty) {
        return InvalidMoveError.CellFull;
    }
    const player_cell = if (next_player == Player.x) Cell.x else Cell.o;
    cells[i][j] = player_cell;
    board.next_player = if (next_player == Player.x) Player.o else Player.x;
}
