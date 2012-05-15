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
		when 'removePlayer'
			pname = JSON.parse content
			console.log "******** removePlayer #{pname}"
			i = playerList.indexOf(pname)
			playerList.splice(i, 1) if i >= 0
			showPlayerList()
		when 'playerList'
			plist = JSON.parse content
			playerList = plist.split(',')
			$("#ssLogin").remove()
			showPlayerList()
		when 'invite'
			console.log "****** got invite from #{content}"
			$('#ssLobby').html "<h1>INVITE FROM #{content}"

login = (uname) ->
	myName = uname
	socket = io.connect()
	socket.on 'message', handleMessage
	socket.emit 'login', { playername:uname }

showPlayerList = (pname) ->
	console.log "******* showing playerlisthtml: #{playerListToHtml(playerList)}"
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
	socket.send "invite:#{JSON.stringify(toPlayer)}"

root = exports ? window
root.login = login
root.sendPlayerInvite = sendPlayerInvite
