{Dictionary} = require './Dictionary'
{Grid} = require './Grid'
{Player} = require './Player'
{Words} = require './nonfetlc.js'

class Game
	@TURN_TIME = 30000 #milliseconds
	constructor: ->
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
		player.score = 0 for player in @players
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
		if @player1.id and @player2.id then true else false

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
