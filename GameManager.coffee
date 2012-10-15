{Player} = require "./Player"
{Game} = require "./Game"


# Manages creation and deletion of games
class GameManager

	constructor: ->
		@players = []
		@games = []
		@words = null

	login: (id, name) ->
		if not (name in @players)
			@players.push(new Player(id, name))
			true
		else
			false

	logout: (id) ->
		i = @players.indexOf(id)
		@players.splice(i, 1) if i >= 0
		#todo: remove from games if any!
		
	getPlayerById: (id) ->
		for player in @players
			return player if player.id is id

	getPlayerByName: (name) ->
		console.log "******** #{name}"
		for player in @players
			console.log "****** #{player.name} is maybe #{name}"
			return player if player.name is name
		null

	getNewGame: ->
		game = null
		for g in @games
			if g.wasPlayed
				g.reset
				game = g
				break
		if !game?
			game = new Game
		console.log "**** getNewGame the game is: #{game.wasPlayed}"
		@words = game.dictionary.originalWordList if !@words?
		@games.push game
		game

	getNextAvailableGame: ->
		# if there aren't any games, create a new one
		if @games.length is 0
			@games.push new Game
			@words = @games[0].dictionary.originalWordList
		# or if all games are full, create a new one 		
		else if @games[@games.length - 1].isFull()
			@games.push new Game(new Player(1, 'Player 1'), new Player(1, 'Player 1'))
		# otherwise check if we are re-using old game and reset if necessary
		else if @games[@games.length - 1].wasPlayed is true
			@games[@games.length - 1].reset()
		@games[@games.length - 1]

	getGameByPlayerName: (pname) ->
		for game in @games
			for player in game.players
				return game if player.name is pname
		return null

	getGameByPlayerId: (client) ->
		for game in @games
			for player in game.players
				return game if player.id is client.id

	numberOfPlayers: (game) ->
		count = 0
		if game?.players?
			count++ for player in game.players when player.id isnt null
			count++
		count
		
	pruneEmptyGames: ->
		for game in @games
			@games.pop game if @numberOfPlayers(game) is 0
				
	connectOrphanedPlayers: (callback) ->
		# first make sure there are no empty games hanging around
		@pruneEmptyGames()
	
		# find games with 1 player, i.e. orphans
		orphanedGames = []
		for game in @games
			orphanedGames.push game if @numberOfPlayers(game) is 1

		if orphanedGames.length is 2 # two games with 1 player each = 1 full game 
			# move high player to low game
			playerToMove = player for player in orphanedGames[1].players when player.id isnt null
			orphanedGames[0].addPlayer playerToMove.id
			# reset names and nums
			[player.name, player.num] = ["Player#{i}", "#{i}"] for player, i in orphanedGames[0]
			# purge highest orphaned game and reset game for players
			@games.pop(orphanedGames[1])
			orphanedGames[0].reset()
			# welcome orphans to game		
			callback orphanedGames[0]
								
root = exports ? window
root.GameManager = GameManager
