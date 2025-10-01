tileValues =
	a: 1, 'á': 4, b: 4, d: 3, 'ð': 2, e: 2, 'é': 9, f: 3, g: 2, h: 3,
	i: 1, 'í': 7, j: 4, k: 2, l: 1, m: 2, n: 1, o: 5, 'ó': 4, p: 5,
	r: 1, s: 1, t: 1, u: 1, 'ú': 7, v: 3, x: 10, y: 6, 'ý': 8,
	'þ': 8, 'æ': 6, 'ö': 6

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
	constructor: (@id, @name, @dictionary) ->
		@score = 0
		@moveCount = 0

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
		{@id, @name, @score, @moveCount, @num}

root = exports ? window
root.Player = Player
