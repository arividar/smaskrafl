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
	$('#ssLobby').html "<h2>#{fromPlayer} vill spila við þig. Viltu spila?</h2>"
	$('#ssLobby').append "<h3><a href=\"javascript:sendInviteResponse(true)\">Já</a></h3>"
	$('#ssLobby').append "<h3><a href=\"javascript:sendInviteResponse(false)\">Nei</a></h3>"

handleInviteResponse = (response) ->
	if myState isnt ClientState.INVITE_SENT or not pendingInviteToPlayer?
		console.log "******* ERROR: got invite response but state not INVITE_SENT. Player invited: #{pendingInviteToPlayer}"
		$('#ssLobby').html "<h1>ERROR - got initation response when no invite sent! #{pendingInviteToPlayer}</h1>"
		showPlayerList()
		pendingInviteToPlayer = null
		myState = ClientState.IN_LOBBY
		return
	if response isnt 'yes'
		console.log "****** got invite decline from #{pendingInviteToPlayer}"
		$('#ssLobby').html "<h1>INVITE DECLINED BY #{pendingInviteToPlayer}</h1>"
		showPlayerList()
		pendingInviteToPlayer = null
		myState = ClientState.IN_LOBBY
		return
	# Invitation response is 'yes':
	console.log "****** got invite accepted from #{pendingInviteToPlayer}  - should redirect to ssClient"
	$('#ssLobby').html "<h1>INVITE ACCEPTED BY #{pendingInviteToPlayer} - should redirect to ssClient</h1>"
	self.location = "game.html"
	showPlayerList()
	pendingInviteToPlayer = null
	myState = ClientState.READY_TO_PLAY

sendInviteResponse = (yesIWantToPlay) ->
	if myState isnt ClientState.INVITE_RECEIVED
		console.log '************ ERROR - should be INVITE_RECEIVED'
		$('#ssLobby').html "<h1>ERROR - should be INVITE_RECEIVED #{pendingInviteToPlayer}</h1>"
		return
	if yesIWantToPlay
		console.log '********** YES I will play - redirect to ssClient'
		$('#ssLobby').html "<h1>YES will play - should redirect to ssClient"
		myState = ClientState.READY_TO_PLAY
		socket.emit 'inviteResponse:yes'
		self.location="game.html"
	else
		console.log '********** NO I will not play'
		$('#ssLobby').html "<h1>NO will play"
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
root.sendInviteResponse = sendInviteResponse
