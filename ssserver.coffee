# Requires
express = require 'express'
io = require('socket.io')
{Game} = require './Game'
{GameManager} = require './GameManager'

console.log('***** dirname: '+__dirname + '/client')

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

# Game server
gameManager = new GameManager
idClientMap = {}
pendingInvitations = []

# Bind socket to HTTP server
socket = io.listen app

# Handle client messages
socket.sockets.on 'connection', (client) =>
	client.on 'login', (loginInfo) =>
		if gameManager.login(client.id, loginInfo.playername)
			idClientMap[client.id] = client
			for id, c of idClientMap
				c.send "newPlayer:#{JSON.stringify(loginInfo.playername)}" if id isnt client.id
			client.send "playerList:#{JSON.stringify((p.name for p in gameManager.players).join(','))}"
			# assignToGame client, loginInfo.playername
		else
			client.send "loginFail"
			#TODO: Respond and handle failed loginxxx
	client.on 'message', (message) =>
		console.log "************** ssServer got message from client #{client.id}:#{message}"
		handleMessage client, message
	client.on 'disconnect', =>
		# removeFromGame client
		p = gameManager.getPlayerById(client.id)
		for id, c of idClientMap
			c.send "removePlayer:#{JSON.stringify(p.name)}" if id isnt client.id
		gameManager.logout client.id
		delete idClientMap[client.id]

assignToGame = (client, username) ->
	game = gameManager.getNextAvailableGame()
	game.addPlayer client.id, username
	if game.isFull()
		welcomePlayers(game)

removeFromGame = (client) ->
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
		idClientMap[player.id].send "gameOver:#{JSON.stringify(playerInfo)}"

welcomePlayers = (game) ->
	info =
		players: game.players
		tiles: game.grid.tiles
		currPlayerNum: game.currPlayer.num
		newWords: getWords(game.dictionary.usedWords)
		turnTime: Game.TURN_TIME/1000
	for player in game.players
		playerInfo = extend {}, info, {yourNum: player.num}
		idClientMap[player.id].send "welcome:#{JSON.stringify playerInfo}"
	# reset things just to be safe - could be an old game getting recycled
	resetTimer game.currPlayer, game.otherPlayer
	
handleMessage = (client, message) ->
	{type, content} = typeAndContent message
	switch type
		when 'invite'
			inviter = gameManager.getPlayerById(client.id)
			invitee = gameManager.getPlayerByName(content)
			if invitee? and inviter?
				forwardInvitation(inviter, invitee)
			else
				console.log("**************** ERROR: Missing inviter or invitee")
		when 'inviteResponse'
			inviter = gameManager.getPlayerById(client.id)
			if invitee? and inviter?
				handleInviteResponse(inviter.name, content)
			else
				console.log("**************** ERROR: Missing inviter or invitee")
		when 'move'
			game = gameManager.getGameWithPlayer client
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
	console.log "*********** The message is: #{message}"
	[ignore, type, content] = message.match /(.*?):(.*)/
	{type, content}

# adds props of arbitrary objs (others) to a
extend = (a, others...) ->
	for o in others
		a[key] = val for key, val of o
	a

forwardInvitation = (from, to) ->
	for i in pendingInvitations
		if from.name is i.from or from.name is i.to or to.name is i.from or to.name is i.to
			# TODO: Invitation exists and should not be forwarded
			idClientMap[from.id].send "inviteResponse:no"
			console.log "**** invitation already exists for either #{from} or #{to}"
			return false
	pendingInvitations.push { from: from.name, to: to.name }
	console.log "**** forwarding invite from #{from.name} to #{to.name}"
	idClientMap[to.id].send "inviteFrom:#{from.name}"
	return true

handleInviteResponse = (inviteeName, response) ->
	index = 0
	for invitation in pendingInvitations
		if invitation.from is inviteeName
			inviter = gameManager.getPlayerByName(inviteeName)
			idClientMap[from.id].send "inviteResponse:#{response}"
			index = pendingInvitations.indexOf(invitation)
			pendingInvitations.splice(index, 1) if i >= 0
			return true
		index = index + 1
	console.log "*********** ERROR: Missing invitation from #{from}"
	return false


