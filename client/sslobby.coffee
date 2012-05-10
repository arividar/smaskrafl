socket = myNum = playerList = null
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
			console.log '****** got playerlist'
			plist = JSON.parse content
			playerList = plist.split(',')
			$("#ssLogin").remove()
			showPlayerList()

login = (uname) ->
	console.log '****** logging in!'
	socket = io.connect()
	socket.on 'message', handleMessage
	socket.emit 'login', { playername:uname }

showPlayerList = (pname) ->
	console.log '************ showing player list'
	playerList.push(pname) if pname?
	$('#ssLobby').html playerListToHtml(playerList)

playerListToHtml = (plist) ->
	plistHtml = ''
	for player in plist.sort()
		plistHtml = "#{plistHtml}, <a href=\"javascript:sendPlayerInvite(\'#{player}\')\">#{player}</a>"
	plistHtml

sendPlayerInvite = (toPlayer) ->
	console.log("****** sending invite to #{toPlayer}")

root = exports ? window
root.login = login
