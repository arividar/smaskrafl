(function() {
  var handleMessage, login, myNum, playerList, playerListToHtml, root, sendPlayerInvite, showPlayerList, socket, typeAndContent;

  socket = myNum = playerList = null;

  root = typeof exports !== "undefined" && exports !== null ? exports : window;

  typeAndContent = function(message) {
    var content, ignore, type, _ref;
    _ref = message.match(/(.*?):(.*)/), ignore = _ref[0], type = _ref[1], content = _ref[2];
    return {
      type: type,
      content: content
    };
  };

  handleMessage = function(message) {
    var content, plist, pname, type, _ref;
    _ref = typeAndContent(message), type = _ref.type, content = _ref.content;
    switch (type) {
      case 'loginFail':
        return $("#ssLogin").append("<h2>******* LOGIN FAILED!</h2>");
      case 'newPlayer':
        pname = JSON.parse(content);
        return showPlayerList(pname);
      case 'playerList':
        plist = JSON.parse(content);
        playerList = plist.split(',');
        $("#ssLogin").remove();
        return showPlayerList();
    }
  };

  login = function(uname) {
    socket = io.connect();
    socket.on('message', handleMessage);
    return socket.emit('login', {
      playername: uname
    });
  };

  showPlayerList = function(pname) {
    if (pname != null) playerList.push(pname);
    return $('#playerList').html(playerListToHtml(playerList));
  };

  playerListToHtml = function(plist) {
    var player, plistHtml, _i, _len, _ref;
    plistHtml = '';
    _ref = plist.sort();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      player = _ref[_i];
      plistHtml = "" + plistHtml + ", <a href=\"javascript:sendPlayerInvite(\'" + player + "\')\">" + player + "</a>";
    }
    return plistHtml;
  };

  sendPlayerInvite = function(toPlayer) {
    return console.log("****** sending invite to " + toPlayer);
  };

  root = typeof exports !== "undefined" && exports !== null ? exports : window;

  root.login = login;

}).call(this);
