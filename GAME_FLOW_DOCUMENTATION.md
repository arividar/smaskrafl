# Smákrafl Game Flow Documentation

This document provides comprehensive documentation of the complete game flow for Smákrafl, an Icelandic word game similar to Scrabble.

## Game Overview

Smákrafl is a multiplayer word game where players compete to find Icelandic nouns (4+ letters, nominative case, singular, without articles) by swapping letters on an 8x8 grid. Games are turn-based with 60-second time limits and end after each player makes 10 moves.

---

## Phase 1: Player Entry & Login

### User Experience
1. **Landing Page** (`index.html`)
   - Player sees game title "SMÁKRAFL"
   - Game rules displayed in Icelandic:
     - Find 4+ letter Icelandic nouns
     - Words must be in nominative case, singular, without articles
   - Username input field
   - "Innskráning" (Login) button

2. **Login Process**
   - Player enters username and clicks login button
   - Client establishes WebSocket connection
   - Username validation occurs server-side

### Technical Flow

**Client Side** (`sslobby.coffee`):
```javascript
// Initial state
myState = ClientState.NOT_LOGGED_IN

// Login function called on button click
login = (uname) ->
    myName = uname
    socket = io.connect()                    // Establish WebSocket connection
    socket.on 'message', handleMessage       // Set up message handler
    socket.emit 'login', { playername: uname } // Send login request
```

**Server Side** (`ssserver.coffee`):
```coffeescript
client.on 'login', (loginInfo) =>
    if gameManager.login(client.id, loginInfo.playername)
        // Success: Add to player list and notify others
        idClientMap[client.id] = client
        // Broadcast new player to existing players
        for id, c of idClientMap
            c.send "newPlayer:#{JSON.stringify(loginInfo.playername)}" if id isnt client.id
        // Send current player list to new player
        client.send "playerList:#{JSON.stringify((p.name for p in gameManager.players).join(','))}"
    else
        client.send "loginFail"  // Username taken or other error
```

**Message Flow**:
- Client → Server: `login: {playername: "username"}`
- Server → Client: `playerList: "player1,player2,..."` (success)
- Server → Other Clients: `newPlayer: "newusername"`
- Server → Client: `loginFail` (failure)

**State Transition**: `NOT_LOGGED_IN` → `IN_LOBBY`

---

## Phase 2: Lobby & Matchmaking

### User Experience
1. **Lobby Display**
   - Login form disappears
   - Player list appears with clickable names
   - Message: "Smelltu á þann sem þú vilt keppa við" (Click who you want to compete with)

2. **Invitation System**
   - **Sending Invitation**: Click on player name → "SENT INVITE TO [player]"
   - **Receiving Invitation**: See "[player] vill spila við þig. Viltu spila?" with "Já/Nei" buttons
   - **Response Handling**: Accept redirects to game, decline returns to lobby

### Technical Flow

**Client State Management** (`sslobby.coffee`):
```javascript
ClientState =
    NOT_LOGGED_IN: 0
    IN_LOBBY: 1
    INVITE_SENT: 2
    INVITE_RECEIVED: 3
    READY_TO_PLAY: 4
```

**Sending Invitation**:
```coffeescript
sendPlayerInvite = (toPlayer) ->
    $('#ssLobby').html "<h1>SENT INVITE TO #{toPlayer}</h1>"
    pendingInviteToPlayer = toPlayer
    myState = ClientState.INVITE_SENT
    socket.send "invite:#{toPlayer}"
```

**Server Invitation Handling**:
```coffeescript
when 'invite'
    inviter = gameManager.getPlayerById(client.id)
    invitee = gameManager.getPlayerByName(content)
    if invitee? and inviter?
        forwardInvitation(inviter, invitee)  // Check for existing invites, prevent duplicates

forwardInvitation = (from, to) ->
    # Prevent duplicate invitations
    for i in pendingInvitations
        if from.name is i.from or from.name is i.to or to.name is i.from or to.name is i.to
            idClientMap[from.id].send "inviteResponse:no"
            return false

    pendingInvitations.push { from: from.name, to: to.name }
    idClientMap[to.id].send "inviteFrom:#{from.name}"
```

**Receiving and Responding to Invitations**:
```coffeescript
// Client receives invitation
when 'inviteFrom'
    handleInviteRequest(content)  // Shows accept/decline buttons
    myState = ClientState.INVITE_RECEIVED

// Client responds to invitation
sendInviteResponse = (yesIWantToPlay, opponent) ->
    if yesIWantToPlay
        myState = ClientState.READY_TO_PLAY
        socket.send 'inviteResponse:yes'
        self.location = "game.html?player=#{myName}&opponent=#{opponent}"
    else
        myState = ClientState.IN_LOBBY
        socket.send 'inviteResponse:no'
```

**Message Flow**:
- Client A → Server: `invite: "playerB"`
- Server → Client B: `inviteFrom: "playerA"`
- Client B → Server: `inviteResponse: yes/no`
- Server → Client A: `inviteResponse: yes/no`
- Both Clients: Redirect to `game.html?player=name&opponent=othername`

---

## Phase 3: Game Initialization

### User Experience
1. **Game Page Load** (`game.html`)
   - Game board layout appears
   - "Bíð eftir mótspilara" (Waiting for opponent) message
   - UI elements hidden until game starts

2. **Game Start**
   - Grid populated with Icelandic letters
   - Player names and scores (0-0) displayed
   - Word list area appears
   - Turn timer starts for current player

### Technical Flow

**Client Game Initialization** (`ssclient.coffee`):
```coffeescript
$(document).ready ->
    $('#grid li').live 'click', tileClick
    urlVars = getUrlVars()                      // Parse URL parameters
    pname = Url.decode urlVars["player"]        // Get player names
    oname = Url.decode urlVars["opponent"]
    players = {p1: pname, p2: oname}
    socket = io.connect()
    socket.emit "newGame", "#{JSON.stringify players}"  // Request new game
    socket.on 'connect', ->
        showMessage 'waitForConnection'
    socket.on 'message', handleMessage
```

**Server Game Creation** (`ssserver.coffee`):
```coffeescript
client.on 'newGame', (thePlayers) =>
    { p1, p2 } = JSON.parse thePlayers
    newGame(client, p1, p2)

newGame = (client, username, opponent) ->
    game = gameManager.getGameByPlayerName(opponent)  // Find existing game
    if !game?
        game = gameManager.getNewGame()               // Or create new one

    game.addPlayer(client.id, username)               // Add player to game
    if game.isFull()                                  // Both players joined
        welcomePlayers(game)                          // Start the game
```

**Game Object Creation** (`Game.coffee`):
```coffeescript
constructor: (@player1, @player2) ->
    @grid = new Grid                                  // 8x8 letter grid
    @dictionary = new Dictionary(Words, @grid)        // Icelandic word list
    @currPlayer = @player1 = new Player(1, 'Player 1', @dictionary)
    @player2 = @otherPlayer = new Player(2, 'Player 2', @dictionary)
    @players = [@player1, @player2]
    @wasPlayed = false
    @timer = @interval = null
```

**Grid Generation** (`Grid.coffee`):
```coffeescript
// Weighted Icelandic letter distribution
tileCounts =
    a: 10, 'á': 1, b: 1, d: 2, 'ð': 3, e: 4, 'é': 1, f: 3, g: 4, h: 2,
    i: 8, 'í': 1, j: 1, k: 4, l: 6, m: 4, n: 9, o: 1, 'ó': 2, p: 1,
    r: 9, s: 7, t: 5, u: 6, 'ú': 1, v: 2, x: 1, y: 1, 'ý': 1,
    'þ': 1, 'æ': 1, 'ö': 1

constructor: ->
    @size = 8
    @tiles = for x in [0...8]
        for y in [0...8]
            randomLetter()  // Weighted random selection
```

**Welcome Players** (`ssserver.coffee`):
```coffeescript
welcomePlayers = (game) ->
    info =
        players: game.players           // Player objects with names, scores
        tiles: game.grid.tiles         // 8x8 letter grid
        currPlayerNum: game.currPlayer.num  // Who goes first
        newWords: getWords(game.dictionary.usedWords)  // Pre-existing words
        turnTime: Game.TURN_TIME/1000  // 60 seconds

    for player in game.players
        playerInfo = extend {}, info, {yourNum: player.num}
        idClientMap[player.id].send "welcome:#{JSON.stringify playerInfo}"

    resetTimer game.currPlayer, game.otherPlayer  // Start turn timer
```

**Message Flow**:
- Both Clients → Server: `newGame: {p1: "name1", p2: "name2"}`
- Server → Both Clients: `welcome: {players, tiles, currPlayerNum, yourNum, newWords, turnTime}`

---

## Phase 4: Active Gameplay

### User Experience

#### Turn-Based Play
1. **Your Turn**
   - Grid border turns green
   - Timer shows 60 seconds counting down
   - Message: "Veldu fyrri stafinn" (Choose first letter)
   - Click first tile → becomes highlighted, message: "Veldu seinni stafinn" (Choose second letter)
   - Click second tile → letters swap, move submitted

2. **Opponent's Turn**
   - Grid border turns red
   - Opponent timer visible
   - Message: "Mótspilarinn á leik" (Opponent's turn)
   - Wait for opponent's move result

3. **Move Results**
   - Letters animate swap on grid
   - Score updates shown
   - New words found displayed with definitions
   - Move history updated

#### Scoring System
- **Letter Values** (from `Player.coffee`):
  ```coffeescript
  tileValues =
      a: 1, 'á': 4, b: 4, d: 3, 'ð': 2, e: 2, 'é': 9, f: 3, g: 2, h: 3,
      i: 1, 'í': 7, j: 4, k: 2, l: 1, m: 2, n: 1, o: 5, 'ó': 4, p: 5,
      r: 1, s: 1, t: 1, u: 1, 'ú': 7, v: 3, x: 10, y: 6, 'ý': 8,
      'þ': 8, 'æ': 6, 'ö': 6
  ```
- **Scoring Formula**: `(sum of letter values in all new words) × (number of new words formed)`

### Technical Flow

#### Client Turn Management
```coffeescript
startTurn = (player, forced = false) ->
    myTurn = true
    $('#grid').removeClass('turnColorRed turnColorYellow').addClass('turnColorGreen')
    $('#opponentTimer').hide()
    $('#meTimer').show()
    showMessage 'firstTile'

endTurn = (player, forced = false) ->
    selectedCoordinates = null
    myTurn = false
    $('#grid').removeClass('turnColorGreen turnColorYellow').addClass('turnColorRed')
    $('#meTimer').hide()
    $('#opponentTimer').show()
    showMessage 'waitForMove'
```

#### Move Processing
```coffeescript
// Client tile click handler
tileClick = ->
    return unless myTurn
    $this = $(this)
    if selectedCoordinates is null
        # First tile selection
        [x, y] = @id.match(/(\d+)_(\d+)/)[1..]
        selectedCoordinates = {x1: x, y1: y}
        $this.addClass 'selected'
        showMessage 'secondTile'
    else
        # Second tile selection - submit move
        selectedCoordinates.x2 = x
        selectedCoordinates.y2 = y
        socket.send "move:#{JSON.stringify selectedCoordinates}"
        endTurn(null, false)
```

**Server Move Validation**:
```coffeescript
when 'move'
    game = gameManager.getGameByPlayerId client
    return unless client.id is game.currPlayer.id  // Prevent cheating

    if game.isGameOver()
        clearInterval game.interval
        sendGameOver game
    else
        swapCoordinates = JSON.parse content
        {moveScore, newWords} = game.currPlayer.makeMove swapCoordinates
        result = {swapCoordinates, moveScore, player: game.currPlayer, newWords}

        # Send results to both players
        for player in game.players
            idClientMap[player.id].send "moveResult:#{JSON.stringify result}"

        game.endTurn()                        // Switch active player
        resetTimer game.currPlayer, game.otherPlayer
```

#### Word Validation and Scoring
```coffeescript
// Player.coffee - makeMove method
makeMove: (swapCoordinates) ->
    @dictionary.grid.swap swapCoordinates     // Physically swap letters
    @moveCount++
    result = scoreMove @dictionary, swapCoordinates
    @score += result.moveScore
    result

// Scoring algorithm
scoreMove = (dictionary, swapCoordinates) ->
    {x1, y1, x2, y2} = swapCoordinates
    words = dictionary.wordsThroughTile(x1, y1).concat dictionary.wordsThroughTile(x2, y2)
    moveScore = multiplier = 0
    newWords = []

    for word in words when dictionary.isWord(word) and dictionary.markUsed(word)
        multiplier++
        moveScore += tileValues[letter] for letter in word  // Sum letter values
        newWords.push word

    moveScore *= multiplier  // Score = total letter value × word count
    {moveScore, newWords}
```

#### Timer System
```coffeescript
// Server-side timer (60 seconds per turn)
startTimer = (currPlayer, otherPlayer) ->
    game = gameManager.getGameByPlayerId currPlayer

    # Tick every second
    game.interval = setInterval ->
        if game.isGameOver()
            clearInterval game.interval
            sendGameOver game
        else
            for player in game.players
                idClientMap[player.id].send "tick:#{JSON.stringify('tock')}"
    , 1000

    # Main timer (60 seconds)
    game.timer = setTimeout ->
        currPlayer.moveCount++  // Count as a move
        if game.isGameOver()
            sendGameOver game
        else
            resetTimer otherPlayer, currPlayer
            idClientMap[currPlayer.id].send "timeIsUp: #{JSON.stringify(currPlayer)}"
            idClientMap[otherPlayer.id].send "yourTurnNow: #{JSON.stringify(currPlayer)}"
            game.endTurn()
    , Game.TURN_TIME  # 60000 milliseconds
```

**Message Flow (Per Turn)**:
- Client → Server: `move: {x1, y1, x2, y2}`
- Server → Both Clients: `moveResult: {swapCoordinates, moveScore, player, newWords}`
- Server → Both Clients: `tick: "tick"` (start of turn), `tick: "tock"` (every second)
- Server → Clients: `timeIsUp: player` / `yourTurnNow: player` (timeout)

---

## Phase 5: Game Completion

### User Experience
1. **End Condition Reached**
   - Both players complete 10 moves each
   - Timers stop, word list hidden
   - Final scores displayed

2. **Winner Announcement**
   - Grid replaced with winner message
   - "Leik lokið!" (Game over!)
   - "[Winner name] vann!" (Winner won!)
   - "Nýr leikur" (New game) button to return to lobby

### Technical Flow

#### End Game Detection
```coffeescript
// Game.coffee - End condition check
isGameOver: ->
    if (@player1.moveCount >= Game.MAX_MOVES) and (@player2.moveCount >= Game.MAX_MOVES)
        true
    else
        false

# Winner determination
winner: ->
    if not @isGameOver()
        null
    else if @player1.score > @player2.score
        @player1
    else if @player1.score < @player2.score
        @player2
    else
        null  # Tie game
```

#### Server End Game Handling
```coffeescript
sendGameOver = (theGame) ->
    info = {winner: theGame.winner()}
    for player in theGame.players
        playerInfo = extend {}, info, {yourNum: player.num}
        idClientMap[player.id].send "gameOver:#{JSON.stringify(playerInfo)}"
```

#### Client End Game Display
```coffeescript
// Handle game over message
when 'gameOver'
    {winner, yourNum: myNum} = JSON.parse content
    endGame(winner)

endGame = (winner) ->
    $("#grid").html """
        <center>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        Leik lokið!
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        #{winner.name} vann!
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <FORM>
        <INPUT type="button" value="Nýr leikur" onClick="history.go(-1);return true;">
        </FORM>
        </center>
    """
    showMessage 'gameOver'
```

**Message Flow**:
- Server → Both Clients: `gameOver: {winner: playerObject, yourNum: 1/2}`

---

## Advanced Technical Details

### Game Session Management

**Game Recycling System**:
```coffeescript
# GameManager.coffee - Efficient game reuse
getNewGame: ->
    game = null
    for g in @games
        if g.wasPlayed          # Reuse completed games
            g.reset()
            game = g
            break
    if !game?
        game = new Game         # Create new if none available
    @games.push game
    game
```

**Player Connection Management**:
```coffeescript
# Handle disconnections
client.on 'disconnect', =>
    p = gameManager.getPlayerById(client.id)
    # Notify other players
    for id, c of idClientMap
        c.send "removePlayer:#{JSON.stringify(p.name)}" if id isnt client.id
    gameManager.logout client.id
    delete idClientMap[client.id]
```

### Word Dictionary System

**Dictionary Initialization**:
```coffeescript
# Dictionary.coffee - Word validation
constructor: (@originalWordList, grid) ->
    @setGrid grid if grid?

setGrid: (@grid) ->
    # Filter words by grid size and minimum length
    @wordList = (word for word of @originalWordList when word.length <= @grid.size and word.length >= Dictionary.MIN_WORD_LENGTH)
    @usedWords = []

    # Pre-mark existing words on grid
    for x in [0...@grid.size]
        for y in [0...@grid.size]
            @markUsed word for word in @wordsThroughTile x, y
```

**Word Finding Algorithm**:
```coffeescript
# Find words through specific tile in all directions
wordsThroughTile: (x, y) ->
    strings = []
    for length in [Dictionary.MIN_WORD_LENGTH..grid.size]
        for offset in [0...length]
            # Check all four directions:
            # Vertical, Horizontal, Diagonal (\), Diagonal (/)
            if grid.inRange(x - offset, y) and grid.inRange(x - offset + range, y)
                addTiles (i) -> grid.tiles[x - offset + i][y]  # Vertical
            # ... similar for other directions
    str for str in strings when @isWord str
```

### Performance Optimizations

1. **Game Object Reuse**: Completed games are reset and reused rather than creating new instances
2. **Efficient Word Lookup**: Dictionary pre-computed on grid generation
3. **Incremental Word Tracking**: Only new words are processed and scored
4. **Client-Side State Caching**: Game state maintained locally to reduce server queries

This comprehensive documentation covers the complete flow of Smákrafl from initial login through game completion, including all technical implementation details and message flows.