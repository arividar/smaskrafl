socket = myNum = null
root = exports ? window

logincount=0

typeAndContent = (message) ->
	[ignore, type, content] = message.match /(.*?):(.*)/
	{type, content}

handleMessage = (message) ->
	{type, content} = typeAndContent message
	switch type
		when 'newPlayer'
			pname = JSON.parse content
			console.log "******** got newPlayer: #{pname} from server"
		when 'playerList'
			plist = JSON.parse content
			console.log "******** got playerlist: #{plist} from server"

login = (userNameField) ->
	logincount++
	$("#ssLobbyPage").html "<h1>************** L O G I N #{userNameField.value} </h1>"
	socket.emit 'lobbyLogin', { playername:userNameField.value }

$(document).ready ->
	console.log "************* R E A D Y! "
	socket = io.connect()
	socket.on 'message', handleMessage
