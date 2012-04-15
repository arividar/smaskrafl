# Requires
express = require 'express'
io = require('socket.io')
{Game} = require './Game'
{GameManager} = require './GameManager'

# Create server
app = express.createServer()
app.use express.static(__dirname + '/client')
app.use express.errorHandler { showStacktrace: true, dumpExceptions: true }
app.use express.bodyParser()

# Process client requests
app.get "/", (req, res) ->
	res.sendfile "client/index.html"

app.post "/send", (req, res) ->
	res.redirect "/game.html\?player=#{req.body.userName}"

# Start server
port = process.env.PORT || 3000
console.log 'Listening to port '+port
app.listen port
console.log "Browse to http://localhost:#{port} to play"

# Bind socket to HTTP server
socket = io.listen app

# Handle client messages
socket.sockets.on 'connection', (client) ->
	client.on 'login', (loginInfo) ->
		assignToGame client, loginInfo.playername
	client.on 'message', (message) ->
		handleMessage client, message
	client.on 'disconnect', ->
		removeFromGame client

# Game server
gameManager = new GameManager
idClientMap = {}

assignToGame = (client, username) ->
	idClientMap[client.id] = client
	game = gameManager.getNextAvailableGame()
	game.addPlayer client.id, username
	if game.isFull()
		welcomePlayers(game)

removeFromGame = (client) ->
	delete idClientMap[client.id]
	#remove player from game
	game = gameManager.getGameWithPlayer client
	game.removePlayer client.id
	# remove timer and interval when player disconects and notify remaining player
	clearTimeout game.timer
	clearInterval game.interval
	for player in game.players
		idClientMap[player.id].send "opponentQuit: blank" if player.id
	# two players in games where opponent quit can be connected automatically
	gameManager.connectOrphanedPlayers(welcomePlayers)

# player loses turn if they take too long
startTimer = (currPlayer, otherPlayer) ->
	game = gameManager.getGameWithPlayer currPlayer
	# interval ticker for each second - fire before timer for safety's sake
	game.interval = setInterval ->
		if game.isGameOver()
			clearInterval game.interval
			sendGameOver game
		else
			for player in game.players
				idClientMap[player.id].send "tick:#{JSON.stringify('tock')}"
	, 1000
	# fire off first tick
	for player in game.players
		idClientMap[player.id].send "tick:#{JSON.stringify('tick')}"
	# timer for turn
	game.timer = setTimeout ->
		currPlayer.moveCount++
		if game.isGameOver()
			sendGameOver
		else
			resetTimer otherPlayer, currPlayer
			idClientMap[currPlayer.id].send "timeIsUp: #{JSON.stringify(currPlayer)}"
			idClientMap[otherPlayer.id].send "yourTurnNow: #{JSON.stringify(currPlayer)}"
			game.endTurn()
			resetTimer otherPlayer, currPlayer
	, Game.TURN_TIME

resetTimer = (currPlayer, otherPlayer) ->
	game = gameManager.getGameWithPlayer currPlayer
	clearTimeout game.timer
	clearInterval game.interval
	startTimer currPlayer, otherPlayer
		
sendGameOver = (theGame) ->
	info = {winner:theGame.winner()}
	for player in theGame.players
		playerInfo = extend {}, info, {yourNum: player.num}
		idClientMap[player.id].send "gameOver: #{JSON.stringify(playerInfo)}"

welcomePlayers = (game) ->
	info =
		players: game.players
		tiles: game.grid.tiles
		currPlayerNum: game.currPlayer.num
		newWords: getWords(game.dictionary.usedWords)
		turnTime: Game.TURN_TIME/1000}
	for player in game.players
		playerInfo = extend {}, info, {yourNum: player.num}
		idClientMap[player.id].send "welcome:#{JSON.stringify playerInfo}"
	# reset things just to be safe - could be an old game getting recycled
	resetTimer game.currPlayer, game.otherPlayer
	
handleMessage = (client, message) ->
	{type, content} = typeAndContent message
	game = gameManager.getGameWithPlayer client
	if type is 'move'
		return unless client.id is game.currPlayer.id #no cheating
		if game.isGameOver()
			clearInterval game.interval
			sendGameOver
		else
			swapCoordinates = JSON.parse content
			{moveScore, newWords} = game.currPlayer.makeMove swapCoordinates
			result = {swapCoordinates, moveScore, player: game.currPlayer, newWords: getWords(newWords)}
			# only send results to players, reset timer since move has been made
			for player in game.players
				idClientMap[player.id].send "moveResult:#{JSON.stringify result}"
			game.endTurn()
			resetTimer game.currPlayer, game.otherPlayer

# gather used words and defs - only send new ones
getWords = (newWords) ->
	wordsHtml = []
	defs = {}
	for word in newWords
		wordsHtml.push "<strong>#{word}</strong>"
		defs[word] = gameManager.words[word]
	{wordsHtml: wordsHtml.join(", "), defs}
	
typeAndContent = (message) ->
	[ignore, type, content] = message.match /(.*?):(.*)/
	{type, content}

# adds props of arbitrary objs (others) to a
extend = (a, others...) ->
	for o in others
		a[key] = val for key, val of o
	a
