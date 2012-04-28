(function() {
  var handleMessage, login, myNum, playerList, root, socket, typeAndContent;

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
    var content, player, plist, pname, type, _i, _len, _ref, _results;
    _ref = typeAndContent(message), type = _ref.type, content = _ref.content;
    switch (type) {
      case 'newPlayer':
        pname = JSON.parse(content);
        $("#ssLogin").remove();
        return $("#ssLobby").append("<h2>******* NewPlayer: " + pname + " </h2>");
      case 'loginFail':
        return $("#ssLogin").append("<h2>******* LOGIN FAILED!</h2>");
      case 'playerList':
        plist = JSON.parse(content);
        playerList = plist.split(',');
        $("#ssLobby").append("<h4>" + plist + "</h4>");
        _results = [];
        for (_i = 0, _len = playerList.length; _i < _len; _i++) {
          player = playerList[_i];
          _results.push($("#ssLobby").append("<p>" + player + "</p>"));
        }
        return _results;
    }
  };

  login = function(uname) {
    socket = io.connect();
    socket.on('message', handleMessage);
    return socket.emit('lobbyLogin', {
      playername: uname
    });
  };

  root = typeof exports !== "undefined" && exports !== null ? exports : window;

  root.login = login;

}).call(this);
