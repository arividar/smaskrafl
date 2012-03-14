class Dictionary
	@MIN_WORD_LENGTH: 2

	constructor: (@originalWordList, grid) ->
		@setGrid grid if grid?
	
	setGrid: (@grid) ->
		@wordList = @originalWordList #make a copy of wordlist
		@wordList = (word for word of @wordList when word.length <= @grid.size and word.length >= Dictionary.MIN_WORD_LENGTH)
		@usedWords = []
		for x in [0...@grid.size]
			for y in [0...@grid.size]
				@markUsed word for word in @wordsThroughTile x,y
	
	MinWordLength: ->
		Dictionary_Word_Length
		
	markUsed: (str) ->
		if str in @usedWords
			false
		else
			@usedWords.push str
			true
	
	isWord: (str) ->
		str in @wordList

	isNewWord: (str) ->
		str in @wordList and str not in @usedWords

	wordsThroughTile: (x,y) ->
		# numbers in JSON come back as strings so coerce into nums
		[x, y] = [+x, +y]
		grid = @grid
		strings = []
		for length in [Dictionary.MIN_WORD_LENGTH..grid.size]
			range = parseInt(length) - 1
			addTiles = (func) ->
				strings.push (func(i) for i in [0..range]).join ''
			for offset in [0...length]
				# Vertical
				if grid.inRange(x - offset, y) and grid.inRange(x - offset + range, y)
					addTiles (i) -> grid.tiles[x - offset + i][y]
				# Horizontal
				if grid.inRange(x, y - offset) and grid.inRange(x, y - offset + range)
					addTiles (i) -> grid.tiles[x][y - offset + i]
				# Diagonal (upper-left to lower-right)
				if grid.inRange(x - offset, y - offset) and grid.inRange(x - offset + range, y - offset + range)
					addTiles (i) -> grid.tiles[x - offset + i][y - offset + i]
				# Diagonal (lower-left to upper-right)
				# fixed code from book
				if grid.inRange(x + offset, y - offset) and grid.inRange(x + offset - range, y - offset + range)
					addTiles (i) -> grid.tiles[x + offset - i][y - offset + i]
				# original code
				# if grid.inRange(x - offset, y + offset) and 
				# 	 grid.inRange(x - offset + range, y + offset - range) 
				# 	addTiles (i) -> grid.tiles[x - offset + i][y + offset - i]
		str for str in strings when @isWord str	
root = exports ? window
root.Dictionary = Dictionary
