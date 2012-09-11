socket = myName = playerList = pendingInviteToPlayer = null

ClientState =
	NOT_LOGGED_IN: 0
	IN_LOBBY: 1
	INVITE_SENT: 2
	INVITE_RECEIVED: 3
	READY_TO_PLAY: 4

myState = ClientState.NOT_LOGGED_IN

typeAndContent = (message) ->
	[ignore, type, content] = message.match /(.*?):(.*)/
	{type, content}

handleMessage = (message) ->
	{type, content} = typeAndContent message
	switch type
		when 'loginFail'
			$("#ssLogin").append "<h2>******* LOGIN FAILED!</h2>"
		when 'playerList'
			if myState isnt ClientState.NOT_LOGGED_IN
				console.log "************ ERROR: Wrong state at playerList: #{myState}"
				return
			plist = JSON.parse content
			playerList = plist.split(',')
			$("#ssLogin").remove()
			showPlayerList()
			myState = ClientState.IN_LOBBY
		when 'newPlayer'
			pname = JSON.parse content
			showPlayerList(pname)
		when 'removePlayer'
			pname = JSON.parse content
			console.log "******** removePlayer #{pname}"
			i = playerList.indexOf(pname)
			playerList.splice(i, 1) if i >= 0
			showPlayerList()
		when 'inviteFrom'
			handleInviteRequest(content)
		when 'inviteResponse'
			handleInviteResponse(content)

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

handleInviteRequest = (fromPlayer) ->
	if myState isnt ClientState.IN_LOBBY
		console.log "****** got invite from #{fromPlayer} but not in IN_LOBBY State"
		socket.emit 'inviteResponse:no'
		return
	myState = ClientState.INVITE_RECEIVED
	console.log "****** got invite from #{fromPlayer}"
	$('#ssLobby').html "<h1>#{fromPlayer} vill spila við þig</h1>"
	$('#ssLobby').append "<p><a href=\"javascript:sendInviteResponse(true)\">Já</a></p>"
	$('#ssLobby').append "<p><a href=\"javascript:sendInviteResponse(false)\">Nei</a></p>"

handleInviteResponse = (response) ->
	if myState isnt ClientState.INVITE_SENT or not pendingInviteToPlayer?
		console.log "******* ERROR: got invite response but state not INVITE_SENT. Player invited: #{pendingInviteToPlayer}"
		#TODO: Cleanup
		return
	if respons isnt 'yes' and response isnt 'no'
		console.log "******* ERROR: Got inviteResponse that is neiter yes or no. Player invited: #{pendingInviteToPlayer}"
		#TODO: Cleanup
		return
	if response is 'no'
		console.log "****** got invite decline from #{pendingInviteToPlayer}"
		$('#ssLobby').html "<h1>INVITE DECLINED BY #{pendingInviteToPlayer}</h1>"
		showPlayerList()
		pendingInviteToPlayer = null
		myState = ClientState.IN_LOBBY
	else
		console.log "****** got invite accepted from #{pendingInviteToPlayer} but not in IN_LOBBY State"
		$('#ssLobby').html "<h1>INVITE ACCEPTED BY #{pendingInviteToPlayer}</h1>"
		showPlayerList()
		pendingInviteToPlayer = null
		myState = ClientState.IN_LOBBY

sendInviteResponse = (yesIWantToPlay) ->
	if myState isnt ClientState.INVITE_RECEIVED
		console.log '************ ERROR - should be INVITE_RECEIVED'
		return
	if yesIWantToPlay
		myState = ClientState.READY_TO_PLAY
		socket.emit 'inviteResponse:yes'
	else
		myState = ClientState.IN_LOBBY
		socket.emit 'inviteResponse:no'

sendPlayerInvite = (toPlayer) ->
	console.log("****** sending invite to #{toPlayer}")
	$('#ssLobby').html "<h1>SENT INVITE TO #{toPlayer}</h1>"
	pendingInviteToPlayer = toPlayer
	myState = ClientState.INVITE_SENT
	socket.send "invite:#{toPlayer}"

root = exports ? window
root.login = login
root.sendPlayerInvite = sendPlayerInvite
