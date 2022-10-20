<# 
    TIC-TAC-BRO is an interactive 2-Player Tic-Tac-Toe game between two Powershell clients across the network.
    Authors: Joseph Colaizzo, Jon Allen, Jared Baker, Rylee Nazareno
    Date: 19 October 2022
#>

# Initialize Variables
$port = 31337
$board = @("_", "_", "_", "_", "_", "_", "_", "_", "_")
$myTurn = $false

# Prints the current board layout in 3x3 human readable format
function PrintBoard {
    Write-Host "Current Game Board:"
    for ($i = 0; $i -lt 9; $i++) { 
        if ($i -eq 3 -or $i -eq 6) {
            "`n"
        }
        $element = $board[$i]
        Write-Host -nonewline "$element   " 
    }
}

# Prints a sample board layout so players know which numbers correspond to which spaces
function PrintSampleBoard {
    Write-Output "`n`nNumbers Corresponding to space inputs:"
    Write-Output "`n`n0   1   2"
    Write-Output "`n3   4   5"
    Write-Output "`n6   7   8"
}

# Checks that user input is between 0 and 8 and not already filled on the board
# Return $true if input validation conditions met, false otherwise
function InputValidation($elementnumber) {
    if ($elementnumber -ge 0 -and $elementnumber -le 8) {
        if($board[$elementnumber] -eq "_") {
            return $true
        }    
    }
    return $false
}     
      
# Checks if the win condition is met for a given gamepiece (X or O)
# Return true if the player with the gamepiece won the game, false otherwise
function Win ($gamePiece) {
    $row1win = $board[0] -eq $gamePiece -and $board[1] -eq $gamePiece -and $board[2] -eq $gamePiece
    $row2win = $board[3] -eq $gamePiece -and $board[4] -eq $gamePiece -and $board[5] -eq $gamePiece
    $row3win = $board[6] -eq $gamePiece -and $board[7] -eq $gamePiece -and $board[8] -eq $gamePiece
    $column1win = $board[0] -eq $gamePiece -and $board[3] -eq $gamePiece -and $board[6] -eq $gamePiece
    $column2win = $board[1] -eq $gamePiece -and $board[4] -eq $gamePiece -and $board[7] -eq $gamePiece
    $column3win = $board[2] -eq $gamePiece -and $board[5] -eq $gamePiece -and $board[8] -eq $gamePiece
    $backslashwin = $board[0] -eq $gamePiece -and $board[4] -eq $gamePiece -and $board[8] -eq $gamePiece
    $frontslashwin = $board[2] -eq $gamePiece -and $board[4] -eq $gamePiece -and $board[6] -eq $gamePiece
    
    if($row1win -or $row2win -or $row3win -or $column1win -or $column2win -or $column3win -or $backslashwin -or $frontslashwin) {
        return $true
    }
    else {
        return $false
    }
}

# Checks if the game is a draw
# Return true if all squares on the board filled, false otherwise
function Draw {
    foreach ($i in $board) {
        if ($i -eq "_") {
            return $False
        }
    }
    return $true
}

# Prints a given type of ASCII art
function PrintAsciiArt ($type) {
    switch ($type) {
        "Win" {
            "
            __     ______  _    _  __          _______ _   _ _  
            \ \   / / __ \| |  | | \ \        / /_   _| \ | | | 
             \ \_/ / |  | | |  | |  \ \  /\  / /  | | |  \| | | 
              \   /| |  | | |  | |   \ \/  \/ /   | | | . ` | | 
               | | | |__| | |__| |    \  /\  /   _| |_| |\  |_| 
               |_|  \____/ \____/      \/  \/   |_____|_| \_(_) 
            "
        }
        "Loss" {
            "
            __     ______  _    _   _      ____   _____ ______ 
            \ \   / / __ \| |  | | | |    / __ \ / ____|  ____|
             \ \_/ / |  | | |  | | | |   | |  | | (___ | |__   
              \   /| |  | | |  | | | |   | |  | |\___ \|  __|  
               | | | |__| | |__| | | |___| |__| |____) | |____ 
               |_|  \____/ \____/  |______\____/|_____/|______|
            "
        }
        "Draw" {
            "
             _____  _____       __          __
            |  __ \|  __ \     /\ \        / /
            | |  | | |__) |   /  \ \  /\  / / 
            | |  | |  _  /   / /\ \ \/  \/ /  
            | |__| | | \ \  / ____ \  /\  /   
            |_____/|_|  \_\/_/    \_\/  \/ 
            "
        }
        "Welcome" {
            ".___________. __    ______    .___________.    ___       ______    .______   .______        ______        _______."
            "|           ||  |  /      |   |           |   /   \     /      |   |   _  \  |   _  \      /  __  \      /       |"
            "----|  |-----|  | |  ,----'   ----|  |-----  /  ^  \   |  ,----'   |  |_)  | |  |_)  |    |  |  |  |    |   (-----"
            "    |  |     |  | |  |            |  |      /  /_\  \  |  |        |   _  <  |      /     |  |  |  |     \   \    "
            "    |  |     |  | |  -----.       |  |     /  _____  \ |  -----.   |  |_)  | |  |\  \----.|  ---'  | .----)   |   "
            "    |__|     |__|  \______|       |__|    /__/     \__\ \______|   |______/  | _|  ._____| \______/  |_______/    "
        }
    }
}

# Sends a string of data over a given TCP socket
function SendString ($socket, $data) {
    $encoding = [System.Text.Encoding]::UTF8
    $dataBytes = $encoding.GetBytes($data)
    $socket.Send($dataBytes)
}

# Receives a string of data over a given TCP socket
# This function will block until a string is received
function ReceiveString ($socket) {
    [byte[]] $buffer = New-Object System.Byte[] 1
    $bytesReceived = $socket.Receive($buffer)
    $encoding = New-Object System.Text.ASCIIEncoding
    $stringReceived = $encoding.GetString($buffer, 0, $bytesReceived)
    return $stringReceived 
}

# Game logic goes here
# $server is the TCPListener instance running, if this is the server
# $socket is the Socket instance we will communicate over
function PlayGame ($server, $socket) {

    $gamePiece = ""
    $opponentGamePiece = ""
    if (-not $null -eq $server) {
        $gamePiece = "X"
        $opponentGamePiece = "O"
    } else {
        $gamePiece = "O"
        $opponentGamePiece = "X"
    }
    "Instructions: You will be $gamePiece and your opponent will be $opponentGamePiece. Take turns placing your plays on the board. Have fun!"
    
    while ($true) {
        PrintBoard
        if ($myTurn) { 
            Printsampleboard 
            
            do
            {
                [int]$play= read-host "`nWhere do you want to go? Please enter a valid number 0-8 that is not already taken" #asks the user to re-input if the inputvalidation kicks in
                $isvalid = Inputvalidation $play
            } while (-not $isvalid)

            $board[$play] = $gamePiece

            [string] $playString = $play
            SendString $socket $play
            $myTurn = $false
        } else {
            Write-Output "`n`nWaiting for opponent to make move..."
            $opponentPlayString = receiveString $socket
            [int] $opponentPlay = $opponentPlayString
            
            $board[$opponentPlay] = $opponentGamePiece

            $myTurn = $true
        }

        $win = Win $gamePiece
        $loss = Win $opponentGamePiece
        $draw = Draw
        if ($win -or $loss -or $draw)
        {
            Write-Output "`n"
            PrintBoard
            if ($win) {
                PrintAsciiArt "Win"
            } elseif ($loss) {
                PrintAsciiArt "Loss"
            } else {
                PrintAsciiArt "Draw"
            }
            break
        }
        Write-Output "`n"
    }
    $socket.close()
    if ($null -ne $server) {
        $server.Stop()
    }
    
}

# Starts the socket connection, either as a Server or a Client
function startConnection ($clientOrServer) {
    # Server
    if ($clientOrServer -eq "1") {
        $server = New-Object System.Net.Sockets.TcpListener -ArgumentList $port
        $server.Start()
        $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi).IPAddress
        Write-Output "Waiting for opponent to connect...please tell your opponent to connect to $ipAddress"
        $socket = $server.AcceptSocket()
        Write-Output "Successfully established connection. Let's begin..."
        playGame $server $socket
    }
    # Client
    elseif ($clientOrServer -eq "2") {
        $ipAddress = Read-Host "What is the IP address of your opponent?"
        $client = New-Object System.Net.Sockets.TCPClient($ipAddress, $port)
        $socket = $client.Client
        $myTurn = $true
        playGame $null $socket
    } 
}

# Main Program
printAsciiArt "Welcome"
$clientOrServer = Read-Host "Welcome to Tic-Tac-Bros Network Edition. Please choose from the following menu: `n(1) Start a new game.`n(2) Connect to an existing game.`nEnter your choice here"
startConnection $clientOrServer
