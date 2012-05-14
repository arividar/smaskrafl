{Dictionary} = require './Dictionary'
{Grid} = require './Grid'
{Player} = require './Player'
{Words} = require './nonfetlc.js'

class Game
	@TURN_TIME = 60000 # milliseconds
	@MAX_MOVES = 10

	constructor: (@player1, @player2) ->
		@grid = new Grid
		@dictionary = new Dictionary(Words, @grid)
		@currPlayer = @player1 = new Player(1, 'Player 1', @dictionary)
		@player2 = @otherPlayer = new Player(2, 'Player 2', @dictionary)
		@player1.id = @player2.id = null
		@players = [@player1, @player2]
		@wasPlayed = false
		@timer = @interval = null

	reset: ->
		# reset scores and grid
		for player in @players
			player.score = 0
			player.moveCount = 0
		@dictionary.setGrid(@grid)

	addPlayer: (sessionId, username) ->
		if !@player1.id
			@player1.id = sessionId
			@player1.name = username
		else
			@player2.id = sessionId
			@player2.name = username
			
	removePlayer: (sessionId) ->
		@playerWithId(sessionId).id = null
		
	isFull: ->
		if @player1.id and @player2.id
			true
		else
			false

	isGameOver: ->
		if (@player1.moveCount >= Game.MAX_MOVES) and (@player2.moveCount >= Game.MAX_MOVES)
			true
		else
			false
	
	# Returns the winner of the game. Null if there is no winner.
	winner: ->
		if not @isGameOver()
			null
		else if @player1.score > @player2.score
			@player1
		else if @player1.score < @player2.score
			@player2
		else
			null

	playerWithId: (sessionId) ->
		if sessionId is @player1.id
			@player1
		else if sessionId is @player2.id
			@player2

	endTurn: ->
		@wasPlayed = true
		if @currPlayer is @player1
			[@currPlayer, @otherPlayer] = [@player2, @player1]
		else
			[@currPlayer, @otherPlayer] = [@player1, @player2]

root = exports ? window
root.Game = Game
