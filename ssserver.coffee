# Requires
express = require 'express'
io = require('socket.io')
{Game} = require './Game'
{GameManager} = require './GameManager'

console.log('***** dirname: '+__dirname + '/client')

# Create server
app = express()
app.use express.static(__dirname + '/client')
app.use express.urlencoded({ extended: true })

# Process client requests
app.get "/", (req, res) ->
	res.sendFile __dirname + "/client/index.html"

app.post "/send", (req, res) ->
	res.redirect "/game.html\?player=#{req.body.userName}"

# Start server
port = process.env.PORT || 3000
console.log 'Listening to port '+port
server = app.listen port
console.log "Browse to http://localhost:#{port} to play"

# Game server
gameManager = new GameManager
idClientMap = {}
pendingInvitations = []

# Bind socket to HTTP server
socket = io(server)

# Handle client messages
socket.on 'connection', (client) =>
	client.on 'login', (loginInfo) =>
		if gameManager.login(client.id, loginInfo.playername)
			idClientMap[client.id] = client
			console.log "************** login - climap=#{idClientMap}"
			for id, c of idClientMap
				console.log "************** login - climapid - id=#{id}, c.id=#{c.id}, len=#{(val for key, val of idClientMap).length}"
				c.emit "newPlayer", JSON.stringify(loginInfo.playername) if id isnt client.id
			logClientIdMap()
			client.emit "playerList", JSON.stringify((p.name for p in gameManager.players).join(','))
		else
			client.emit "loginFail"
			#TODO: Respond and handle failed loginxxx
	client.on 'newGame', (thePlayers) =>
		console.log "************** ssServer got newGame from client #{client.id}:#{thePlayers}"
		{ p1, p2 } = JSON.parse thePlayers
		console.log "************** on.newgame p1=#{p1}, p2=#{p2}"
		console.log "************* on.newGame idclimap.len=#{(val for key, val of idClientMap).length}"
		logClientIdMap()
		for id, c of idClientMap
			console.log "************** on newgame - climapid - c.id=#{c.id}, id=#{id}"
		newGame(client, p1, p2)
	client.on 'invite', (targetPlayer) =>
		console.log "************** ssServer got invite from client #{client.id} to #{targetPlayer}"
		inviter = gameManager.getPlayerById(client.id)
		invitee = gameManager.getPlayerByName(targetPlayer)
		if invitee? and inviter?
			forwardInvitation(inviter, invitee)
		else
			console.log("**************** ERROR: Missing inviter or invitee")

	client.on 'inviteResponse', (response) =>
		console.log "************** ssServer got inviteResponse from client #{client.id}: #{response}"
		invitee = gameManager.getPlayerById(client.id)
		if invitee?
			handleInviteResponse(invitee.name, response)
		else
			console.log("**************** ERROR: Missing invitee")

	client.on 'move', (moveData) =>
		console.log "************** ssServer got move from client #{client.id}: #{moveData}"
		game = gameManager.getGameByPlayerId client
		if not game?
			console.log "************** ERROR: Player #{client.id} tried to move but is not in any game"
			return
		return unless client.id is game.currPlayer.id #no cheating
		if game.isGameOver()
			clearInterval game.interval
			sendGameOver game
		else
			swapCoordinates = JSON.parse moveData
			{moveScore, newWords} = game.currPlayer.makeMove swapCoordinates
			result = {swapCoordinates, moveScore, player: game.currPlayer, newWords: getWords(newWords)}
			# only send results to players, reset timer since move has been made
			for player in game.players
				if player.id and idClientMap[player.id]
					idClientMap[player.id].emit "moveResult", JSON.stringify(result)
			game.endTurn()
			resetTimer game.currPlayer, game.otherPlayer
	client.on 'disconnect', =>
		# removeFromGame client
		console.log "***** disconnect"
		p = gameManager.getPlayerById(client.id)
		if p
			for id, c of idClientMap
				c.emit "removePlayer", JSON.stringify(p.name) if id isnt client.id
		gameManager.logout client.id
		delete idClientMap[client.id]
		logClientIdMap()

logClientIdMap = ->
	console.log "************** logclimapid - LEN=#{(val for key, val of idClientMap).length}"
	for id, c of idClientMap
		console.log "************** logclimapid - id=#{id}, c.id=#{c.id}, len=#{(val for key, val of idClientMap).length}"

newGame = (client, username, opponent) ->
	console.log "************** newGame - player1=#{username}, player2=#{opponent}"
	console.log "************** newGame -  idclimap.len=#{(val for key, val of idClientMap).length}"
	for i, c of idClientMap
		console.log "*******newGame - #{client.id} sama og #{c.id}?"
		if c.id is client.id 
			console.log "********newGAme - found client: #{client.id}"
	# TBD: hér þarf að breyta til að gangsetja leikinn!!!
	game = gameManager.getGameByPlayerName(opponent)
	if !game?
		console.log "**** newGame1: getting another game"
		game = gameManager.getNewGame() 
	console.log "**** newGame2: the game is: #{game.wasPlayed}"
	game.addPlayer(client.id, username)
	if game.isFull()
		welcomePlayers(game)

removeFromGame = (client) ->
	#remove player from game
	game = gameManager.getGameByPlayerId client
	game.removePlayer client.id
	# remove timer and interval when player disconects and notify remaining player
	clearTimeout game.timer
	clearInterval game.interval
	for player in game.players
		if player.id and idClientMap[player.id]
			idClientMap[player.id].emit "opponentQuit", "blank"
	# two players in games where opponent quit can be connected automatically
	gameManager.connectOrphanedPlayers(welcomePlayers)

# player loses turn if they take too long
startTimer = (currPlayer, otherPlayer) ->
	game = gameManager.getGameByPlayerId currPlayer
	# interval ticker for each second - fire before timer for safety's sake
	game.interval = setInterval ->
		if game.isGameOver()
			clearInterval game.interval
			sendGameOver game
		else
			for player in game.players
				if player.id and idClientMap[player.id]
					idClientMap[player.id].emit "tick", JSON.stringify('tock')
	, 1000
	# fire off first tick
	for player in game.players
		if player.id and idClientMap[player.id]
			idClientMap[player.id].emit "tick", JSON.stringify('tick')
	# timer for turn
	game.timer = setTimeout ->
		currPlayer.moveCount++
		if game.isGameOver()
			sendGameOver
		else
			resetTimer otherPlayer, currPlayer
			if currPlayer.id and idClientMap[currPlayer.id]
				idClientMap[currPlayer.id].emit "timeIsUp", JSON.stringify(currPlayer)
			if otherPlayer.id and idClientMap[otherPlayer.id]
				idClientMap[otherPlayer.id].emit "yourTurnNow", JSON.stringify(currPlayer)
			game.endTurn()
			resetTimer otherPlayer, currPlayer
	, Game.TURN_TIME

resetTimer = (currPlayer, otherPlayer) ->
	game = gameManager.getGameByPlayerId currPlayer
	clearTimeout game.timer
	clearInterval game.interval
	startTimer currPlayer, otherPlayer
		
sendGameOver = (theGame) ->
	info = {winner:theGame.winner()}
	for player in theGame.players
		if player.id and idClientMap[player.id]
			playerInfo = extend {}, info, {yourNum: player.num}
			idClientMap[player.id].emit "gameOver", JSON.stringify(playerInfo)

welcomePlayers = (game) ->
	console.log "******** welcomePlayers: currPlayer.num=#{game.currPlayer.num}"
	console.log "******** welcomePlayers: game.player1.id=#{game.player1.id}"
	console.log "******** welcomePlayers: game.player1.name=#{game.player1.name}"
	console.log "******** welcomePlayers: game.player1.num=#{game.player1.num}"
	console.log "******** welcomePlayers: game.player2.id=#{game.player2.id}"
	console.log "******** welcomePlayers: game.player2.name=#{game.player2.name}"
	console.log "******** welcomePlayers: game.player2.num=#{game.player2.num}"
	for i, c of idClientMap
		console.log "*** welcome iclimap, i=#{i}, c.id=#{c.id}"
	info =
		players: game.players
		tiles: game.grid.tiles
		currPlayerNum: game.currPlayer.num
		newWords: getWords(game.dictionary.usedWords)
		turnTime: Game.TURN_TIME/1000
	for player in game.players
		if player.id and idClientMap[player.id]
			playerInfo = extend {}, info, {yourNum: player.num}
			idClientMap[player.id].emit "welcome", JSON.stringify(playerInfo)
	# reset things just to be safe - could be an old game getting recycled
	resetTimer game.currPlayer, game.otherPlayer
	
# handleMessage function removed - replaced with individual event listeners above


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
	# Check if clients are still connected
	if not idClientMap[from.id]?
		console.log "**** ERROR: Inviter #{from.name} is no longer connected"
		return false
	if not idClientMap[to.id]?
		console.log "**** ERROR: Invitee #{to.name} is no longer connected"
		return false

	for i in pendingInvitations
		if from.name is i.from or from.name is i.to or to.name is i.from or to.name is i.to
			# TODO: Invitation exists and should not be forwarded
			idClientMap[from.id].emit "inviteResponse", "no"
			console.log "**** invitation already exists for either #{from} or #{to}"
			return false
	pendingInvitations.push { from: from.name, to: to.name }
	console.log "**** forwarding invite from #{from.name} to #{to.name}"
	idClientMap[to.id].emit "inviteFrom", from.name
	return true

handleInviteResponse = (inviteeName, response) ->
	for invitation in pendingInvitations
		if invitation.to is inviteeName
			inviter = gameManager.getPlayerByName(invitation.from)
			if not inviter?
				console.log "*********** ERROR: Inviter #{invitation.from} not found in game manager"
				index = pendingInvitations.indexOf(invitation)
				pendingInvitations.splice(index, 1) if index >= 0
				return false
			if not idClientMap[inviter.id]?
				console.log "*********** ERROR: Inviter #{invitation.from} is no longer connected"
				index = pendingInvitations.indexOf(invitation)
				pendingInvitations.splice(index, 1) if index >= 0
				return false
			idClientMap[inviter.id].emit "inviteResponse", response
			index = pendingInvitations.indexOf(invitation)
			pendingInvitations.splice(index, 1) if index >= 0
			return true
	console.log "*********** ERROR: Missing invitation from #{inviteeName}"
	return false