tileValues =
	a: 1, 'á': 3, b: 3, d: 2, 'ð': 2, e: 1, f: 4, g: 2, h: 4, i: 1, 'í': 3,
	j: 8, k: 5, l: 1, m: 3, n: 1, o: 1, 'ó': 3, p: 3, r: 1, s: 1,
	t: 1, u: 1, 'ú': 3, v: 4, x: 8, y: 4, 'ý': 3,
	z: 10, 'þ': 3, 'æ': 3, 'ö': 3

scoreMove = (dictionary, swapCoordinates) ->
	{x1, y1, x2, y2} = swapCoordinates
	words = dictionary.wordsThroughTile(x1, y1).concat dictionary.wordsThroughTile(x2, y2)
	moveScore = multiplier = 0
	newWords = []
	for word in words when dictionary.isWord(word) and dictionary.markUsed(word)
	  multiplier++
	  moveScore += tileValues[letter] for letter in word
	  newWords.push word
	moveScore *= multiplier
	{moveScore, newWords}

class Player
	constructor: (@num, @name, dictionary) ->
		@setDictionary dictionary if dictionary?
	
	setDictionary: (@dictionary) ->
		@score = 0
		@moveCount = 0
	
	makeMove: (swapCoordinates) ->
		@dictionary.grid.swap swapCoordinates
		@moveCount++
		result = scoreMove @dictionary, swapCoordinates
		@score += result.moveScore
		result
	
	toJSON: ->
		{@num, @name, @score}
	
root = exports ? window
root.Player = Player
