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

const InvalidArgumentsError = error{InvalidArgumentsError};

pub const PlayerType = enum { human, bot };

// comptime if (player_x_human) {
//     const PlayerXPolicy = struct {
//     const Self = @This();
//     writer: *Io.Writer,
//     reader: *Io.Reader,
//     pub fn getMove(self: Self, board: Board) !MoveTuple {
//         return try readValidMove(self.writer, self.reader, board);
//     }
// }
// }
//
// const playerXPolicy = struct {
//     const Self = @This();
//     writer: *Io.Writer,
//     reader: *Io.Reader,
//     agent: ?*Agent,
//
//     pub fn getMove(self: Self, board: Board) !MoveTuple {
//         if (player_x_human) {
//             return try readValidMove(self.writer, self.reader, board);
//         } else {
//             return try self.agent.?.getMinMaxMove(board);
//         }
//     }
// };
//
// const playerOPolicy = struct {
//     const Self = @This();
//     writer: *Io.Writer,
//     reader: *Io.Reader,
//     agent: ?*Agent,
//
//     pub fn getMove(self: Self, board: Board) !MoveTuple {
//         if (player_o_human) {
//             return try readValidMove(self.writer, self.reader, board);
//         } else {
//             return try self.agent.?.getMinMaxMove(board);
//         }
//     }
// };

fn makePlayerPolicyType(comptime is_human: bool) type {
    if (is_human) {
        return struct {
            writer: *Io.Writer,
            reader: *Io.Reader,
            pub fn getMove(self: @This(), board: Board) !MoveTuple {
                return try readValidMove(self.writer, self.reader, board);
            }
        };
    } else {
        return struct {
            agent: *Agent,
            pub fn getMove(self: @This(), board: Board) !MoveTuple {
                return try self.agent.getMinMaxMove(board);
            }
        };
    }
}

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

    // var x_player: PlayerType = undefined;
    // var o_player: PlayerType = undefined;

    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }
    // if (args.len <= 1) {
    //     std.log.info("no args", .{});
    //     x_player = .human;
    //     o_player = .bot;
    // } else if (eql(u8, args[1], "--help")) {
    //     try stdout_writer.print("Usage: tic_tak_toe [options]\n" ++
    //         "Options:\n" ++
    //         "-x=<human|bot> X player type\n" ++
    //         "-o=<human|bot> O player type\n\n" ++
    //         "The default is x=human o=bot\n", .{});
    //     try stdout_writer.flush();
    //     return;
    // } else {
    //     x_player = try getXPlayer(args);
    //     o_player = try getOPlayer(args);
    // }
    //
    // std.log.info("X Player: {}", .{x_player});
    // std.log.info("O Player: {}", .{o_player});

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

    // var x_agent: Agent = undefined;
    // if (x_player == .bot) {
    //     var x_agent_board_value_map: hash_map.AutoHashMap(Board, i2) = .init(allo);
    //     x_agent = .init(&x_agent_board_value_map, Player.x, allo);
    //     defer x_agent.deinit();
    // }
    //
    // var o_agent: Agent = undefined;
    // if (o_player == .bot) {
    //     var o_agent_board_value_map: hash_map.AutoHashMap(Board, i2) = .init(allo);
    //     o_agent = .init(&o_agent_board_value_map, Player.o, allo);
    //     defer o_agent.deinit();
    // }

    // const human_move = try readValidMove(writer, reader, board);
    // const agent_2_player = Player.o;
    // var agent_2_board_value_map: hash_map.AutoHashMapUnmanaged(Board, i2) = .empty;
    // const agent_2: Agent = .init(&agent_2_board_value_map, agent_2_player, allo);
    // const agent_2: Agent = .init(agent_2_player, allo);

    // fn getHumanMove(writer: *Io.Writer, reader: *Io.Reader, board: Board) !MoveTuple {
    //     const human_move = try readValidMove(writer, reader, board);
    //     try addMove(&board, human_move);
    //     try drawBoard(board, writer);
    // }
    //
    // fn getAgentMove(writer: *Io.Writer, board: Board, agent: *Agent) !MoveTuple {
    //     const agent_move = try agent.getMinMaxMove(board);
    //     try addMove(&board, agent_move);
    //     try drawBoard(board, writer);
    // }
    // comptime getPlayerXPolicy
    const player_x = blk: {
        if (player_x_human) {
            const policy: HumanPolicy = .{ .writer = stdout_writer, .reader = stdin_reader };
            break :blk policy;
        } else {
            var agent_board_value_map: hash_map.AutoHashMap(Board, i2) = .init(allo);
            const agent = .init(&agent_board_value_map, Player.x, allo);
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
            var agent: Agent = .init(&agent_board_value_map, Player.x, allo);
            const policy: AgentPolicy = .{ .agent = &agent };
            break :blk policy;
        }
    };
    defer player_o.deinit();

    try drawBoard(board, stdout_writer);
    const result = for (0..9) |i| {
        try stdout_writer.print("Move {d}: No winner yet.\n", .{i});

        // const move = blk: switch (board.next_player) {
        //     Player.x => {
        //         if (x_player == .bot) {
        //             break :blk try x_agent.getMinMaxMove(board);
        //         } else {
        //             break :blk try readValidMove(stdout_writer, stdin_reader, board);
        //         }
        //     },
        //     Player.o => {
        //         if (o_player == .bot) {
        //             break :blk try o_agent.getMinMaxMove(board);
        //         } else {
        //             break :blk try readValidMove(stdout_writer, stdin_reader, board);
        //         }
        //     },
        // };
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
        // if (winner == Player.x) {
        //     try stdout_writer.print("Player X won!\n", .{});
        // } else if (winner == Player.o) {
        //     try stdout_writer.print("Player O won!\n", .{});
        // }
        switch (winner) {
            Player.x => try stdout_writer.print("Player X won!\n", .{}),
            Player.o => try stdout_writer.print("Player O won!\n", .{}),
        }
    } else {
        try stdout_writer.print("Draw.\n", .{});
    }
    try stdout_writer.flush();
}

fn getXPlayer(args: []const []const u8) !PlayerType {
    assert(args.len > 1);
    if (eql(u8, args[1][0..3], "-x=")) {
        return stringToEnum(PlayerType, args[1][3..]).?;
    } else if (eql(u8, args[2][0..3], "-x=")) {
        return stringToEnum(PlayerType, args[2][3..]).?;
    } else {
        return InvalidArgumentsError.InvalidArgumentsError;
    }
}

fn getOPlayer(args: []const []const u8) !PlayerType {
    assert(args.len > 1);
    if (eql(u8, args[1][0..3], "-o=")) {
        return stringToEnum(PlayerType, args[1][3..]).?;
    } else if (eql(u8, args[2][0..3], "-o=")) {
        return stringToEnum(PlayerType, args[2][3..]).?;
    } else {
        return InvalidArgumentsError.InvalidArgumentsError;
    }
}

// fn getHumanMove(writer: *Io.Writer, reader: *Io.Reader, board: Board) !MoveTuple {
//     const human_move = try readValidMove(writer, reader, board);
//     try addMove(&board, human_move);
//     try drawBoard(board, writer);
// }
//
// fn getAgentMove(writer: *Io.Writer, board: Board, agent: *Agent) !MoveTuple {
//     const agent_move = try agent.getMinMaxMove(board);
//     try addMove(&board, agent_move);
//     try drawBoard(board, writer);
// }
