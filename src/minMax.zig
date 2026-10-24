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

pub const Agent = struct {
    const Self = @This();

    board_value_map: *hash_map.AutoHashMapUnmanaged(Board, i2),
    agent_player: Player,
    allocator: std.mem.Allocator,

    pub fn init(agent_board_value_map: *hash_map.AutoHashMapUnmanaged(Board, i2), agent_player: Player, allocator: std.mem.Allocator) Self {
        return .{ .board_value_map = agent_board_value_map, .agent_player = agent_player, .allocator = allocator };
    }

    pub fn deinit(self: Self) void {
        self.board_value_map.deinit(self.allocator);
    }

    pub fn getMinMaxMove(self: Self, board: Board) !MoveTuple {
        var move_array: [9]MoveTuple = undefined;
        const possible_moves = getPossibleMoves(board, &move_array);
        var move_value_array: [9]i2 = undefined;
        var move_values = move_value_array[0..possible_moves.len];
        for (0.., possible_moves) |index, move| {
            var localBoard = board;
            try addMove(&localBoard, move);
            move_values[index] = try self.minMax(localBoard);
        }
        const bestMoveIndex = sort.argMax(i2, move_values, {}, std.sort.asc(i2)).?;
        return possible_moves[bestMoveIndex];
    }

    pub fn minMax(self: Self, board: Board) !i2 {
        const cachedValue = self.board_value_map.get(board);
        if (cachedValue) |value| {
            return value;
        }

        const winner = getWinner(board);
        if (winner) |winning_player| {
            return if (winning_player == self.agent_player) 1 else -1;
        }

        var move_array: [9]MoveTuple = undefined;
        const possible_moves = getPossibleMoves(board, &move_array);

        if (possible_moves.len == 0) {
            return 0;
        }

        var move_value_array: [9]i2 = undefined;
        var move_values = move_value_array[0..possible_moves.len];

        for (0.., possible_moves) |index, move| {
            var localBoard = board;
            try addMove(&localBoard, move);
            move_values[index] = try self.minMax(localBoard);
        }
        const boardValue = blk: {
            if (board.next_player == self.agent_player) {
                break :blk sort.max(i2, move_values, {}, std.sort.asc(i2)).?;
            } else {
                break :blk sort.min(i2, move_values, {}, std.sort.asc(i2)).?;
            }
        };
        try self.board_value_map.put(self.allocator, board, boardValue);
        return boardValue;
    }
};

pub fn getPossibleMoves(board: Board, move_array: *[9]MoveTuple) []const MoveTuple {
    assert(@TypeOf(board.cells) == [3][3]Cell);
    const cells = board.cells;
    var move_index: u4 = 0;

    for (0..3) |i| {
        for (0..3) |j| {
            if (cells[i][j] == Cell.empty) {
                const move: MoveTuple = .{ .i = @intCast(i), .j = @intCast(j) };
                move_array[move_index] = move;
                move_index += 1;
            }
        }
    }
    return move_array[0..move_index];
}
