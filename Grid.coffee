tileCounts =
	'a': 10, 'á': 1, 'b': 1, 'd': 2, 'ð': 3, 'e': 4,
    'é': 1,  'f': 3, 'g': 4, 'h': 2, 'i': 8, 'í': 1,
    'j': 1,  'k': 4, 'l': 6, 'm': 4, 'n': 9, 'o': 1,
    'ó': 2,  'p': 1, 'r': 9, 's': 7, 't': 5, 'u': 6,
    'ú': 1,  'v': 2, 'x': 1, 'y': 1, 'ý': 1, 'þ': 1,
    'æ': 1,  'ö': 1

totalTiles = 0
totalTiles += count for letter, count of tileCounts
alphabet = (letter for letter of tileCounts).sort()

randomLetter = ->
	randomNumber = Math.ceil Math.random() * totalTiles
	x = 1
	for letter in alphabet
		x += tileCounts[letter]
		return letter if x > randomNumber

class Grid
	constructor: ->
		@size = size = 8
		@tiles = for x in [0...size]
			for y in [0...size]
				randomLetter()

	inRange: (x, y) ->
		0 <= x < @size and 0 <= y < @size

	swap: ({x1, y1, x2, y2}) ->
		[@tiles[x1][y1], @tiles[x2][y2]] = [@tiles[x2][y2], @tiles[x1][y1]]

root = exports ? window
root.Grid = Grid
