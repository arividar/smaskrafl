socket = tiles = selectedCoordinates = myNum = myTurn = usedWords = turnTime = null
turnColorGreen = "#181"
turnColorRed = "#d32"
turnColorYellow = "#FFFFB6"
turnColor = turnColorGreen

iceHTMLChar = (c) ->
	switch c
		when 'Á' then '&Aacute;'
		when 'Ð' then '&ETH;'
		when 'É' then '&Eacute;'
		when 'Í' then '&Iacute;'
		when 'Ó' then '&Oacute;'
		when 'Ú' then '&Uacute;'
		when 'Ý' then '&Yacute;'
		when 'Þ' then '&THORN;'
		when 'Æ' then '&AElig;'
		when 'Ö' then '&Ouml;'
		when 'á' then '&#225;'
		when 'ð' then '&#240;'
		when 'é' then '&#233;'
		when 'í' then '&#237;'
		when 'ó' then '&#243;'
		when 'ý' then '&#253;'
		when 'þ' then '&#254;'
		when 'æ' then '&#230;'
		when 'ö' then '&#246;'
		else c

# forced = true when last turn ended because a player took too long
startTurn = (forced = false) ->
	myTurn = true
	$('#grid').removeClass('turnColorRed turnColorYellow').addClass('turnColorGreen')
	$('#meScore').removeClass('colorRed colorYellow').addClass('colorGreen')
	$('#opponentScore').removeClass('colorGreen colorYellow').addClass('colorRed')
	if forced is false
		showMessage 'firstTile'
	else
		showMessage 'yourTurnNow'

endTurn = (forced = false) ->
	selectedCoordinates = null
	myTurn = false
	$('#grid').removeClass('turnColorGreen turnColorYellow').addClass('turnColorRed')
	$('#meScore').removeClass('colorGreen').addClass('colorRed')
	$('#opponentScore').removeClass('colorRed').addClass('colorGreen')
	if forced is false
		showMessage 'waitForMove'
	else
		showMessage 'timeIsUp'

drawTiles = (x1, y1, x2, y2) ->
	gridHtml = ''
	for x in [0...tiles.length]
		gridHtml += '<ul>'
		for y in [0...tiles.length]
			gridHtml += "<li id='tile#{x}_#{y}'>#{iceHTMLChar(tiles[x][y])}</li>"
		gridHtml += '</ul>'
	# draw the grid and highlight the recently swapped tiles
	$('#grid').html(gridHtml)
		.find("li#tile#{x1}_#{y1}").add("li#tile#{x2}_#{y2}")
		.effect("highlight", color: turnColor, 5500)
		
showMessage = (messageType) ->
	effectColor = "#FFF"
	switch messageType
		when 'waitForConnection'
			messageHtml = "Bíð eftir að mótspilara."
			$('#usedwords, #grid, #scores #opponentScore #meScore').hide()
		when 'waitForMove'
			messageHtml = "Bíð eftir að mótspilarinn leiki."
		when 'firstTile'
			messageHtml = "Veldu fyrri stafinn."
			effectColor = turnColorGreen
		when 'secondTile'
			messageHtml = "Veldu seinni stafinn."
			effectColor = turnColorGreen
		when 'timeIsUp'
			messageHtml = "þú féllst á tíma. Mótspilarinn á leik."
			effectColor = turnColorRed
		when 'yourTurnNow'
			messageHtml = "Þú átt leik. Mótspilarinn féll á tíma."
			effectColor = turnColorGreen
		when 'opponentQuit'
			messageHtml = "Mótspilari þinn er hættur. Bíð eftur nýjum mótspilara."
			$('#usedwords, #grid, #scores').hide()
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
			endTurn()

swapTiles = ({x1, y1, x2, y2}) ->
	[tiles[x1][y1], tiles[x2][y2]] = [tiles[x2][y2], tiles[x1][y1]]
	drawTiles(x1, y1, x2, y2)
	
updateUsedWords = (newWords) ->
	# if no usedwords, initialize with new words
	if Object.keys(usedWords).length is 0
		[usedWords.wordsHtml, usedWords.defs] = [newWords.wordsHtml, newWords.defs]
	# otherwise only update usedWords if there are newWords formed during move
	else if newWords.wordsHtml.length > 0
		usedWords.wordsHtml = usedWords.wordsHtml.concat(", " + newWords.wordsHtml)
	$('#usedwords').html usedWords.wordsHtml
	
handleMessage = (message) ->
	{type, content} = typeAndContent message
	switch type
		when 'welcome'
			{players, currPlayerNum, tiles, yourNum: myNum, newWords, turnTime} = JSON.parse content
			startGame players, currPlayerNum
			# update page
			$('#usedwords, #grid, #scores #meScore #opponentScore').show()
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
			endTurn(true)
		when 'yourTurnNow'
			startTurn(true)
		when 'tick'
			tick = JSON.parse content
			# tick for first tick of turn, tock for others
			if tick is "tick"
				$('#timer').html turnTime
				if turnTime <= 5
					$('#grid').removeClass('turnColorRed turnColorGreen')
						.addClass('turnColorYellow')
			else
				$('#timer').html parseInt($('#timer').html()) - 1
			
typeAndContent = (message) ->
	[ignore, type, content] = message.match /(.*?):(.*)/
	{type, content}

getPlayerName = (player) ->
	name = null
	if player.num is myNum
		name = "Þú"
	else
		name = "Mótspilari"

toArray = (newWords) ->
	words = []
	words.push key for key, value of newWords.defs
	words
	
showNotice = (moveScore, newWords, player) ->
	words = toArray(newWords)
	$notice = $("<p class='notice'></p>")
	if moveScore is 0
		if player.num is myNum
			$notice.html "Þú fannst engin ný orð í þetta sinn."
		else
			$notice.html "#{getPlayerName player} fann engin ný orð."
	else
		fannOrdTexti = "#{getPlayerName player} fann "
		if player.num is myNum
			fannOrdTexti = "Þú fannst "
		$notice.html """ 
			#{fannOrdTexti} #{words.length} orð:<br /> 
			<b>#{words.join(', ')}</b><br /> 
			sem gefur <b>#{moveScore / words.length}x#{words.length}
			= #{moveScore}</b> stig!
		"""
	showThenFade $notice

showThenFade = ($elem) ->
	$elem.insertAfter $('#grid')
	$elem.effect "highlight", color: "#eb4", 5500, -> $elem.remove()
	
startGame = (players, currPlayerNum) ->
	$("#meName").html getPlayerName players[myNum-1]
	$("#meScore").html players[myNum-1].score
	$("#opponentName").html getPlayerName players[2-myNum]
	$("#opponentScore").html players[2-myNum].score
	drawTiles()
	if myNum is currPlayerNum
		startTurn()
	else
		endTurn()

showMoveResult = (player, swapCoordinates, moveScore, newWords) ->
	if player.num is myNum
		$("#meScore").html player.score
	else
		$("#opponentScore").html player.score
	showNotice moveScore, newWords, player
	swapTiles swapCoordinates
	if player.num isnt myNum
		startTurn()

$(document).ready ->
	$('#grid li').live 'click', tileClick
	$
	socket = io.connect()
	socket.on 'connect', -> showMessage 'waitForConnection'
	socket.on 'message', handleMessage
