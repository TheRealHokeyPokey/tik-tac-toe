const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;
const hash_map = std.hash_map;

const tic_tak_toe = @import("tic_tak_toe");

const Game = tic_tak_toe.Game;
const Board = Game.Board;
const Player = Game.Player;
const Cell = Game.Cell;
const addMove = Game.addMove;
const getWinner = Game.getWinner;
const readMove = Game.readMove;
const readValidMove = Game.readValidMove;

const MinMax = tic_tak_toe.MinMax;
const Agent = MinMax.Agent;

const Draw = tic_tak_toe.Draw;
const drawBoard = Draw.drawBoard;

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_file_reader: Io.File.Reader = .init(.stdin(), io, &stdin_buffer);
    const stdin_reader = &stdin_file_reader.interface;

    const allo = std.heap.smp_allocator;

    // safe allocator version:
    // const general_allocator = std.heap.smp_allocator;
    // var safe_allocator = std.heap.SafeAllocator.init(general_allocator, .{});
    // defer _ = safe_allocator.deinit();
    // const allo = safe_allocator.allocator();

    var board = Board{};

    const human_player = Player.x;

    const agent_2_player = Player.o;
    // var agent_2_board_value_map: hash_map.AutoHashMapUnmanaged(Board, i2) = .empty;
    // const agent_2: Agent = .init(&agent_2_board_value_map, agent_2_player, allo);
    // const agent_2: Agent = .init(agent_2_player, allo);
    //
    var agent_2_board_value_map: hash_map.AutoHashMap(Board, i2) = .init(allo);
    const agent_2: Agent = .init(&agent_2_board_value_map, agent_2_player, allo);
    defer agent_2.deinit();

    // var winner: ?Player = null;

    try drawBoard(board, stdout_writer);
    const result = for (0..9) |i| {
        try stdout_writer.print("Move {d}: No winner yet.\n", .{i});
        switch (board.next_player) {
            human_player => {
                const human_move = try readValidMove(stdout_writer, stdin_reader, board);
                try addMove(&board, human_move);
                try drawBoard(board, stdout_writer);
            },
            else => {
                const agent_move = try agent_2.getMinMaxMove(board);
                try addMove(&board, agent_move);
                try drawBoard(board, stdout_writer);
            },
        }
        try stdout_writer.flush();

        if (getWinner(board)) |winner| {
            break winner;
        }
    } else null;

    if (result) |winner| {
        switch (winner) {
            Player.x => try stdout_writer.print("Player X won!\n", .{}),
            Player.o => try stdout_writer.print("Player O won!\n", .{}),
        }
    } else {
        try stdout_writer.print("Draw.\n", .{});
    }
    try stdout_writer.flush();
}
