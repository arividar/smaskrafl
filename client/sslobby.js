(function() {
  var handleMessage, login, logincount, myNum, root, socket, typeAndContent;

  socket = myNum = null;

  root = typeof exports !== "undefined" && exports !== null ? exports : window;

  logincount = 0;

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
      case 'newPlayer':
        pname = JSON.parse(content);
        return console.log("******** got newPlayer: " + pname + " from server");
      case 'playerList':
        plist = JSON.parse(content);
        return console.log("******** got playerlist: " + plist + " from server");
    }
  };

  login = function(userNameField) {
    logincount++;
    $("#ssLobbyPage").html("<h1>************** L O G I N " + userNameField.value + " </h1>");
    return socket.emit('lobbyLogin', {
      playername: userNameField.value
    });
  };

  $(document).ready(function() {
    console.log("************* R E A D Y! ");
    socket = io.connect();
    return socket.on('message', handleMessage);
  });

  root = typeof exports !== "undefined" && exports !== null ? exports : window;

  root.login = login;

}).call(this);
