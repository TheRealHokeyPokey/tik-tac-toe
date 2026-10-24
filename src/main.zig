const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;
const hash_map = std.hash_map;

const tic_tak_toe = @import("tic_tak_toe");

const Game = tic_tak_toe.Game;
const Board = Game.Board;
const Player = Game.Player;
const Cell = Game.Cell;
const MoveTuple = Game.MoveTuple;
const addMove = Game.addMove;
const getWinner = Game.getWinner;
const readMove = Game.readMove;

const MinMax = tic_tak_toe.MinMax;
const getPossibleMoves = MinMax.getPossibleMoves;
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
    try stdout_writer.print("{f}\n", .{board});

    var move_array: [9]MoveTuple = undefined;

    // var agent_board_value_map: hash_map.AutoHashMapUnmanaged(Board, i2) = .empty;
    const agent_player = Player.x;
    // const agent: Agent = .init(&agent_board_value_map, agent_player, allo);
    // defer agent.deinit();

    var agent_2_board_value_map: hash_map.AutoHashMapUnmanaged(Board, i2) = .empty;
    const agent_2_player = Player.o;
    const agent_2: Agent = .init(&agent_2_board_value_map, agent_2_player, allo);
    defer agent_2.deinit();

    var human_move = try readMove(stdout_writer, stdin_reader, board);
    try addMove(&board, human_move);
    try stdout_writer.print("Human chose move: {}\n", .{human_move});

    try drawBoard(board, stdout_writer);
    // std.log.info("I got here", .{});

    human_move = try readMove(stdout_writer, stdin_reader, board);
    try addMove(&board, human_move);
    try stdout_writer.print("Human chose move: {}\n", .{human_move});

    try drawBoard(board, stdout_writer);
    while (true) {
        // try stdout_writer.print("Possible moves: {any}\n", .{possible_moves});
        switch (board.next_player) {
            agent_player => {
                // const agent_move = try agent.getMinMaxMove(board);
                // try addMove(&board, agent_move);
                // try stdout_writer.print("Agent chose move: {}\n", .{agent_move});
                // try stdout_writer.print("{f}\n", .{board});
                human_move = try readMove(stdout_writer, stdin_reader, board);
                try addMove(&board, human_move);
                // try stdout_writer.print("Human chose move: {}\n", .{human_move});
                try drawBoard(board, stdout_writer);
                try stdout_writer.flush();
            },
            else => {
                const agent_move = try agent_2.getMinMaxMove(board);
                try addMove(&board, agent_move);
                // try stdout_writer.print("Agent 2 chose move: {}\n", .{agent_move});
                // try stdout_writer.print("{f}\n", .{board});
                try drawBoard(board, stdout_writer);
                try stdout_writer.flush();
            },
        }

        const possible_moves = getPossibleMoves(board, &move_array);
        if (possible_moves.len == 0) {
            try stdout_writer.print("Draw!\n", .{});
            break;
        }
        const winner = getWinner(board);
        if (winner) |player| {
            try stdout_writer.print("Player: {} won!\n", .{player});
            break;
        } else {
            try stdout_writer.print("No winner yet.\n", .{});
        }
        try stdout_writer.flush();
    }
    try stdout_writer.flush();
}
