# Readme

This is a simple terminal based tic tac toe game. There are two players, player
x and player o. Each player can be human or AI, set through flags at compile time.

Human players make moves by entering coordinates through the command line. AI
players use search to make optimal moves automatically.

Two AI players can play each other.

## Compilation options

```sh
zig build --help
```

## How to run (default - player x is human and player o is AI)

```sh
zig build run
```

## How to run (set players explicitly)

```sh
zig build -Dplayer_x_human=false -Dplayer_o_human=true run
```

## How to play

Human players enter a pair of zero indexed coordinates for where their next move
should occur as <row>_<col>. For example, to place make a move in the top left
square, you could type the sequence: "`0 0\n`".
