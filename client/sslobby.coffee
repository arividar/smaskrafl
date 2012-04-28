socket = myNum = playerList = null
root = exports ? window

typeAndContent = (message) ->
	[ignore, type, content] = message.match /(.*?):(.*)/
	{type, content}

handleMessage = (message) ->
	{type, content} = typeAndContent message
	switch type
		when 'newPlayer'
			pname = JSON.parse content
			$("#ssLogin").remove()
			$("#ssLobby").append "<h2>******* NewPlayer: #{pname} </h2>"
		when 'loginFail'
			$("#ssLogin").append "<h2>******* LOGIN FAILED!</h2>"
		when 'playerList'
			plist = JSON.parse content
			playerList = plist.split(',')
			$("#ssLobby").append "<h4>#{plist}</h4>"
			for player in playerList
				$("#ssLobby").append "<p>#{player}</p>"

login = (uname) ->
	socket = io.connect()
	socket.on 'message', handleMessage
	socket.emit 'lobbyLogin', { playername:uname }

root = exports ? window
root.login = login
