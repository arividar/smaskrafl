util = require './ssutil'

socket = tiles = selectedCoordinates = myNum = myTurn = usedWords = turnTime = null
turnColorGreen = "#181"
turnColorRed = "#d32"
turnColorYellow = "#FFFFB6"
turnColor = turnColorGreen

# forced = true when last turn ended because a player took too long
startTurn = (player, forced = false) ->
	myTurn = true
	$('#grid').removeClass('turnColorRed turnColorYellow').addClass('turnColorGreen')
	$('#opponentTimer').hide()
	$('#meTimer').show()
	if forced
		$("#opponentTimer").html "0"
		showMoveResult player, null, 0, []
		showMessage 'yourTurnNow'
	else
		showMessage 'firstTile'

endTurn = (player, forced = false) ->
	selectedCoordinates = null
	myTurn = false
	$('#grid').removeClass('turnColorGreen turnColorYellow').addClass('turnColorRed')
	$('#meTimer').hide()
	$('#opponentTimer').show()
	if forced
		$('#meTimer').html "0"
		showMoveResult player, null, 0, []
		showMessage 'timeIsUp'
	else
		showMessage 'waitForMove'

drawTiles = (x1, y1, x2, y2) ->
	gridHtml = ''
	for x in [0...tiles.length]
		gridHtml += '<ul>'
		for y in [0...tiles.length]
			gridHtml += "<li id='tile#{x}_#{y}'>#{util.iceHTMLChar(tiles[x][y])}</li>"
		gridHtml += '</ul>'
	# draw the grid and highlight the recently swapped tiles
	$('#grid').html(gridHtml)
		.find("li#tile#{x1}_#{y1}").add("li#tile#{x2}_#{y2}")
		.effect("highlight", color: turnColor, 3000)
		
showMessage = (messageType) ->
	effectColor = "#FFF"
	switch messageType
		when 'waitForConnection'
			messageHtml = "Bíð eftir mótspilara"
			$('#usedwords, #grid, #opponentScore, #meScore').hide()
		when 'waitForMove'
			messageHtml = "Mótspilarinn á leik"
		when 'firstTile'
			messageHtml = "Veldu fyrri stafinn"
			effectColor = turnColorGreen
		when 'secondTile'
			messageHtml = "Veldu seinni stafinn"
			effectColor = turnColorGreen
		when 'timeIsUp'
			messageHtml = "Þú féllst á tíma"
			effectColor = turnColorRed
		when 'yourTurnNow'
			messageHtml = "Mótspilarinn féll á tíma"
			effectColor = turnColorGreen
		when 'opponentQuit'
			messageHtml = "Mótspilarinn hætti"
			$('#usedwords, #grid').hide()
		when 'gameOver'
			messageHtml = ""
			$('#usedwords, #meTimer, #opponentTimer').hide()
	$('#message').html messageHtml
	$('#message').effect("highlight", color: "#{effectColor}", 5500)

tileClick = ->
	return unless myTurn
	$this = $(this)
	if $this.hasClass 'selected'
		# undo
		selectedCoordinates = null
		$this.removeClass 'selected'
		showMessage 'firstTile'
	else
		[x, y] = @id.match(/(\d+)_(\d+)/)[1..]
		if selectedCoordinates is null
			selectedCoordinates = {x1: x, y1: y}
			$this.addClass 'selected'
			showMessage 'secondTile'
		else
			selectedCoordinates.x2 = x
			selectedCoordinates.y2 = y
			socket.send "move:#{JSON.stringify selectedCoordinates}"
			endTurn(null, false)

swapTiles = ({x1, y1, x2, y2}) ->
	[tiles[x1][y1], tiles[x2][y2]] = [tiles[x2][y2], tiles[x1][y1]]
	drawTiles(x1, y1, x2, y2)
	
updateUsedWords = (newWords) ->
	# if no usedwords, initialize with new words
	if Object.keys(usedWords).length is 0
		newWordsHtmlSorted = newWords.wordsHtml.split(", ")
					.sort((a, b) -> a.localeCompare b)
					.join(", ")
		[usedWords.wordsHtml, usedWords.defs] = [newWordsHtmlSorted, newWords.defs]
	# otherwise only update usedWords if there are newWords formed during move
	else if newWords.wordsHtml.length > 0
		allUsedWords = usedWords.wordsHtml.concat(", " + newWords.wordsHtml)
		usedWords.wordsHtml = allUsedWords.split(", ").sort().join(", ")
		usedWords.wordsHtml = allUsedWords.split(", ")
					.sort((a, b) -> a.localeCompare b)
					.join(", ")
	$('#usedwords').html usedWords.wordsHtml
	
handleMessage = (message) ->
	{type, content} = typeAndContent message
	switch type
		when 'welcome'
			{players, currPlayerNum, tiles, yourNum: myNum, newWords, turnTime} = JSON.parse content
			startGame players, currPlayerNum
			# update page
			$('#usedwords, #grid, #meScore, #opponentScore').show()
			$('#usedwords').html ""
			usedWords = {}
			updateUsedWords newWords
		when 'moveResult'
			{player, swapCoordinates, moveScore, newWords} = JSON.parse content
			showMoveResult player, swapCoordinates, moveScore, newWords
			updateUsedWords newWords
		when 'opponentQuit'
			showMessage 'opponentQuit'
		when 'timeIsUp'
			player = JSON.parse content
			endTurn(player, true)
		when 'yourTurnNow'
			player = JSON.parse content
			startTurn(player, true)
		when 'tick'
			# tick for first tick of turn, tock for others
			tick = JSON.parse content
			if myTurn
				turnTimer = "#meTimer"
				nonTurnTimer = "#opponentTimer"
			else
				turnTimer = "#opponentTimer"
				nonTurnTimer = "#meTimer"
			if tick is "tick"
				$(turnTimer).html turnTime
				$(nonTurnTimer).hide()
				$(turnTimer).show()
			else
				$(turnTimer).html parseInt($(turnTimer).html()) - 1
				if parseInt($(turnTimer).html()) <= 5
					$(turnTimer).removeClass('turnColorRed turnColorGreen').addClass('turnColorYellow')

		when 'gameOver'
			{winner, yourNum:myNum} = JSON.parse content
			endGame(winner)

typeAndContent = (message) ->
	[ignore, type, content] = message.match /(.*?):(.*)/
	{type, content}

toArray = (newWords) ->
	words = []
	words.push key for key, value of newWords.defs
	words
	
showNotice = (moveScore, newWords, player) ->
	words = toArray(newWords)
	$notice = $("<p class='notice'></p>")
	if moveScore is 0
		if player.num is myNum
			$notice.html "Þú fannst engin ný orð"
		else
			$notice.html "#{player.name} fann engin ný orð"
	else
		fannOrdTexti = "#{player.name} fann "
		messageLocation = '#opponentMoveList'
		if player.num is myNum
			fannOrdTexti = "Þú fannst "
			messageLocation = '#meMoveList'
		$notice.html """ 
			#{fannOrdTexti} #{words.length} orð:<br /> 
			<b>#{words.join(', ')}</b><br /> 
			sem gefur <b>#{moveScore / words.length}x#{words.length}
			= #{moveScore}</b> stig!
		"""
		$notice.insertAfter $(messageLocation)
		$notice.effect "highlight", color: "#eb4", 7500, -> $notice.remove()

startGame = (players, currPlayerNum) ->
	$("#meName").html players[myNum-1].name
	$("#meScore").html players[myNum-1].score
	$("#opponentName").html players[2-myNum].name
	$("#opponentScore").html players[2-myNum].score
	drawTiles()
	if myNum is currPlayerNum
		startTurn(players[2-myNum], false)
	else
		endTurn(players[myNum-1], false)

endGame = (winner) ->
	$("#grid").html """
		<center>
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		Leik lokið!
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		#{winner.name} vann!
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		<FORM>
		<INPUT type="button" value="Nýr leikur" onClick="history.go(-1);return true;">
		</FORM>
		</center>
	"""
	showMessage 'gameOver'

showMoveResult = (player, swapCoordinates, moveScore, newWords) ->
	words = toArray(newWords)
	moveString = "<b>#{player.moveCount}: 0</b><br/>"
	if words.length > 0
		moveString = "<b>#{player.moveCount}: #{moveScore}</b> - #{words.join(', ')}<br/>"
	console.log player
	if player.num is myNum
		$("#meScore").html player.score
		$("#meMoveList").prepend moveString
	else
		$("#opponentScore").html player.score
		$("#opponentMoveList").prepend moveString
	showNotice moveScore, newWords, player
	swapTiles swapCoordinates if swapCoordinates
	if player.num isnt myNum
		startTurn(player, false)

$(document).ready ->
	$('#grid li').live 'click', tileClick
	urlVars = util.getUrlVars()
	pname = util.Url.decode urlVars["player"]
	socket = io.connect()
	socket.emit 'login', { playername:pname }
	socket.on 'connect', ->
		showMessage 'waitForConnection'
	socket.on 'message', handleMessage
