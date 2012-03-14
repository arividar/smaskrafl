{Game} = require "./Game"

# Manages creation and deletion of games
class GameManager
	constructor: ->
		@games = []
		@words = null
	
	getNextAvailableGame: ->
		# if there aren't any games, create a new one
		if @games.length is 0
			@games.push new Game
			@words = @games[0].dictionary.originalWordList
		# or if all games are full, create a new one 		
		else if @games[@games.length - 1].isFull()
			@games.push new Game
		# otherwise check if we are re-using old game and reset if necessary
		else if @games[@games.length - 1].wasPlayed is true
			@games[@games.length - 1].reset()
		@games[@games.length - 1]
		
	getGameWithPlayer: (client) ->
		for game in @games
			for player in game.players
				return game if player.id is client.id
				
	numberOfPlayers: (game) ->
		count = 0
		count++ for player in game.players when player.id isnt null
		return count++
		
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
			playerToMove = 
				player for player in orphanedGames[1].players when player.id isnt null
			orphanedGames[0].addPlayer playerToMove.id
			# reset names and nums
			[player.name, player.num] = 
				["Player#{i}", "#{i}"] for player, i in orphanedGames[0]			
			# purge highest orphaned game and reset game for players
			@games.pop(orphanedGames[1])	
			orphanedGames[0].reset()	
			# welcome orphans to game		
			callback orphanedGames[0]
								
root = exports ? window
root.GameManager = GameManager
	
