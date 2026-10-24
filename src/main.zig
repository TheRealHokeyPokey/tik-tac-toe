const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;
const hash_map = std.hash_map;
const eql = std.mem.eql;
const stringToEnum = std.meta.stringToEnum;

const build_options = @import("build_options");
const player_x_human = build_options.player_x_human;
const player_o_human = build_options.player_o_human;

const tic_tak_toe = @import("tic_tak_toe");

const Game = tic_tak_toe.Game;
const Board = Game.Board;
const Player = Game.Player;
const Cell = Game.Cell;
const addMove = Game.addMove;
const getWinner = Game.getWinner;
const readMove = Game.readMove;
const readValidMove = Game.readValidMove;
const MoveTuple = Game.MoveTuple;

const MinMax = tic_tak_toe.MinMax;
const Agent = MinMax.Agent;

const Draw = tic_tak_toe.Draw;
const drawBoard = Draw.drawBoard;

const HumanPolicy = struct {
    const Self = @This();
    writer: *Io.Writer,
    reader: *Io.Reader,

    pub fn deinit(self: Self) void {
        _ = self;
        return;
    }

    pub fn getMove(self: @This(), board: Board) !MoveTuple {
        return try readValidMove(self.writer, self.reader, board);
    }
};

const AgentPolicy = struct {
    const Self = @This();
    agent: *Agent,

    pub fn init(agent: *Agent) Self {
        return .{ .agent = agent };
    }

    pub fn deinit(self: Self) void {
        self.agent.deinit();
    }

    pub fn getMove(self: @This(), board: Board) !MoveTuple {
        return try self.agent.getMinMaxMove(board);
    }
};

// fn makePlayerPolicy(comptime is_human: bool)

pub fn main(init: std.process.Init) !void {

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_file_reader: Io.File.Reader = .init(.stdin(), io, &stdin_buffer);
    const stdin_reader = &stdin_file_reader.interface;

    // fast allocator
    const allo = std.heap.smp_allocator;

    // safe allocator (reports memory problems)
    // const general_allocator = std.heap.smp_allocator;
    // var safe_allocator = std.heap.SafeAllocator.init(general_allocator, .{});
    // defer _ = safe_allocator.deinit();
    // const allo = safe_allocator.allocator();

    var board = Board{};

    const player_x = blk: {
        if (player_x_human) {
            const policy: HumanPolicy = .{ .writer = stdout_writer, .reader = stdin_reader };
            break :blk policy;
        } else {
            var agent_board_value_map: hash_map.AutoHashMap(Board, i2) = .init(allo);
            var agent: Agent = .init(&agent_board_value_map, Player.x, allo);
            const policy: AgentPolicy = .{ .agent = &agent };
            break :blk policy;
        }
    };
    defer player_x.deinit();

    const player_o = blk: {
        if (player_o_human) {
            const policy: HumanPolicy = .{ .writer = stdout_writer, .reader = stdin_reader };
            break :blk policy;
        } else {
            var agent_board_value_map: hash_map.AutoHashMap(Board, i2) = .init(allo);
            var agent: Agent = .init(&agent_board_value_map, Player.o, allo);
            const policy: AgentPolicy = .{ .agent = &agent };
            break :blk policy;
        }
    };
    defer player_o.deinit();

    try drawBoard(board, stdout_writer);
    const result = for (0..9) |i| {
        try stdout_writer.print("Move {d}: No winner yet.\n", .{i});

        const move = switch (board.next_player) {
            Player.x => try player_x.getMove(board),
            Player.o => try player_o.getMove(board),
        };

        try addMove(&board, move);
        try drawBoard(board, stdout_writer);
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
