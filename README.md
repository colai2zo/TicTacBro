# TicTacBro
A simple Powershell Tic Tac Toe game over TCP sockets.

## Getting Started
In powershell, run TicTacBro.ps1

If you get an error like "Execution of scripts is disabled on this system", you can bypass your execution policy by running:

`Powershell -ExecutionPolicy Bypass -File TicTacBro.ps1

## Game Play
TicTacBro has two modes, "Start a game" and "Connect to existing game".

"Start a game" allows the user to host a server and wait for the opponent to connect to their game. It will let you know the IP address your opponent should connect to.

"Connect to existing game" allows the user to connect to someone who started a game, using their IP address.

Once a connection is established, players take turns placing X's and O's on the board until one player wins or the board is full.