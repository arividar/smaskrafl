socket = myName = playerList = null
root = exports ? window

typeAndContent = (message) ->
	[ignore, type, content] = message.match /(.*?):(.*)/
	{type, content}

handleMessage = (message) ->
	{type, content} = typeAndContent message
	switch type
		when 'loginFail'
			$("#ssLogin").append "<h2>******* LOGIN FAILED!</h2>"
		when 'newPlayer'
			pname = JSON.parse content
			showPlayerList(pname)
		when 'playerList'
			plist = JSON.parse content
			playerList = plist.split(',')
			$("#ssLogin").remove()
			showPlayerList()

login = (uname) ->
	myName = uname
	socket = io.connect()
	socket.on 'message', handleMessage
	socket.emit 'login', { playername:uname }

showPlayerList = (pname) ->
	playerList.push(pname) if pname?
	$('#ssLobby').show()
	$('#playerList').html playerListToHtml(playerList)

playerListToHtml = (plist) ->
	plistHtml = ''
	for player in plist.sort()
		if player isnt myName
			playerHtml = "<a href=\"javascript:sendPlayerInvite(\'#{player}\')\">#{player}</a>"
			if plistHtml is ''
				plistHtml = playerHtml
			else
				plistHtml = "#{plistHtml}, #{playerHtml}"
	plistHtml

sendPlayerInvite = (toPlayer) ->
	console.log("****** sending invite to #{toPlayer}")

root = exports ? window
root.login = login
root.sendPlayerInvite = sendPlayerInvite
