socket = myNum = null

Url =
  encode: (string) ->
    escape @_utf8_encode(string)

  decode: (string) ->
    @_utf8_decode unescape(string)

  _utf8_encode: (string) ->
    string = string.replace(/\r\n/g, "\n")
    utftext = ""
    n = 0

    while n < string.length
      c = string.charCodeAt(n)
      if c < 128
        utftext += String.fromCharCode(c)
      else if (c > 127) and (c < 2048)
        utftext += String.fromCharCode((c >> 6) | 192)
        utftext += String.fromCharCode((c & 63) | 128)
      else
        utftext += String.fromCharCode((c >> 12) | 224)
        utftext += String.fromCharCode(((c >> 6) & 63) | 128)
        utftext += String.fromCharCode((c & 63) | 128)
      n++
    utftext

  _utf8_decode: (utftext) ->
    string = ""
    i = 0
    c = c1 = c2 = 0
    while i < utftext.length
      c = utftext.charCodeAt(i)
      if c < 128
        string += String.fromCharCode(c)
        i++
      else if (c > 191) and (c < 224)
        c2 = utftext.charCodeAt(i + 1)
        string += String.fromCharCode(((c & 31) << 6) | (c2 & 63))
        i += 2
      else
        c2 = utftext.charCodeAt(i + 1)
        c3 = utftext.charCodeAt(i + 2)
        string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63))
        i += 3
    string


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

getUrlVars = ->
	  vars = {}
	  parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/g, (m, key, value) ->
		    vars[key] = value
	  )
	  vars

$(document).ready ->
	$('#grid li').live 'click', tileClick
	urlVars = getUrlVars()
	pname = Url.decode urlVars["player"]
	socket = io.connect()
	socket.emit 'login', { playername:pname }
	socket.on 'connect', ->
		showMessage 'waitForConnection'
	socket.on 'message', handleMessage
