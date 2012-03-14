tileCounts =
	a: 5, 'á': 3, b: 2, d: 4, 'ð': 2, e: 5, 'é': 3, f: 2, g: 3, h: 2,
	i: 5, 'í': 3, j: 1, k: 1, l: 4, m: 2, n: 6, o: 5, 'ó': 3, p: 2,
	r: 5, s: 4, t: 5, u: 4, 'ú': 3, v: 2, x: 1, y: 4, 'ý': 3, z: 1,
	'þ': 3, 'æ': 3, 'ö': 3
		
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
		@size = size = 6
		@tiles = for x in [0...size]
			for y in [0...size]
				randomLetter()

	inRange: (x, y) ->
		0 <= x < @size and 0 <= y < @size

	swap: ({x1, y1, x2, y2}) ->
		[@tiles[x1][y1], @tiles[x2][y2]] = [@tiles[x2][y2], @tiles[x1][y1]]

root = exports ? window
root.Grid = Grid
