(function() {
  var drawTiles, endTurn, getPlayerName, handleMessage, iceHTMLChar, myNum, myTurn, selectedCoordinates, showMessage, showMoveResult, showNotice, showThenFade, socket, startGame, startTurn, swapTiles, tileClick, tiles, toArray, turnColor, turnColorGreen, turnColorRed, turnColorYellow, turnTime, typeAndContent, updateUsedWords, usedWords;

  socket = tiles = selectedCoordinates = myNum = myTurn = usedWords = turnTime = null;

  turnColorGreen = "#181";

  turnColorRed = "#d32";

  turnColorYellow = "#FFFFB6";

  turnColor = turnColorGreen;

  iceHTMLChar = function(c) {
    switch (c) {
      case 'Á':
        return '&Aacute;';
      case 'Ð':
        return '&ETH;';
      case 'É':
        return '&Eacute;';
      case 'Í':
        return '&Iacute;';
      case 'Ó':
        return '&Oacute;';
      case 'Ú':
        return '&Uacute;';
      case 'Ý':
        return '&Yacute;';
      case 'Þ':
        return '&THORN;';
      case 'Æ':
        return '&AElig;';
      case 'Ö':
        return '&Ouml;';
      case 'á':
        return '&#225;';
      case 'ð':
        return '&#240;';
      case 'é':
        return '&#233;';
      case 'í':
        return '&#237;';
      case 'ó':
        return '&#243;';
      case 'ý':
        return '&#253;';
      case 'þ':
        return '&#254;';
      case 'æ':
        return '&#230;';
      case 'ö':
        return '&#246;';
      default:
        return c;
    }
  };

  startTurn = function(forced) {
    if (forced == null) forced = false;
    myTurn = true;
    $('#grid').removeClass('turnColorRed turnColorYellow').addClass('turnColorGreen');
    $('#opponentTimer').hide();
    $('#meTimer').show();
    if (forced) {
      $("#opponentTimer").html("0");
      return showMessage('yourTurnNow');
    } else {
      return showMessage('firstTile');
    }
  };

  endTurn = function(forced) {
    if (forced == null) forced = false;
    selectedCoordinates = null;
    myTurn = false;
    $('#grid').removeClass('turnColorGreen turnColorYellow').addClass('turnColorRed');
    $('#meTimer').hide();
    $('#opponentTimer').show();
    if (forced) {
      $('#meTimer').html("0");
      return showMessage('timeIsUp');
    } else {
      return showMessage('waitForMove');
    }
  };

  drawTiles = function(x1, y1, x2, y2) {
    var gridHtml, x, y, _ref, _ref2;
    gridHtml = '';
    for (x = 0, _ref = tiles.length; 0 <= _ref ? x < _ref : x > _ref; 0 <= _ref ? x++ : x--) {
      gridHtml += '<ul>';
      for (y = 0, _ref2 = tiles.length; 0 <= _ref2 ? y < _ref2 : y > _ref2; 0 <= _ref2 ? y++ : y--) {
        gridHtml += "<li id='tile" + x + "_" + y + "'>" + (iceHTMLChar(tiles[x][y])) + "</li>";
      }
      gridHtml += '</ul>';
    }
    return $('#grid').html(gridHtml).find("li#tile" + x1 + "_" + y1).add("li#tile" + x2 + "_" + y2).effect("highlight", {
      color: turnColor
    }, 5500);
  };

  showMessage = function(messageType) {
    var effectColor, messageHtml;
    effectColor = "#FFF";
    switch (messageType) {
      case 'waitForConnection':
        messageHtml = "Bíð eftir að mótspilara.";
        $('#usedwords, #grid, #scores #opponentScore #meScore').hide();
        break;
      case 'waitForMove':
        messageHtml = "Mótspilarinn á leik";
        break;
      case 'firstTile':
        messageHtml = "Veldu fyrri stafinn";
        effectColor = turnColorGreen;
        break;
      case 'secondTile':
        messageHtml = "Veldu seinni stafinn";
        effectColor = turnColorGreen;
        break;
      case 'timeIsUp':
        messageHtml = "Þú féllst á tíma";
        effectColor = turnColorRed;
        break;
      case 'yourTurnNow':
        messageHtml = "Mótspilarinn féll á tíma";
        effectColor = turnColorGreen;
        break;
      case 'opponentQuit':
        messageHtml = "Mótspilarinn hætti";
        $('#usedwords, #grid, #scores').hide();
    }
    $('#message').html(messageHtml);
    return $('#message').effect("highlight", {
      color: "" + effectColor
    }, 5500);
  };

  tileClick = function() {
    var $this, x, y, _ref;
    if (!myTurn) return;
    $this = $(this);
    if ($this.hasClass('selected')) {
      selectedCoordinates = null;
      $this.removeClass('selected');
      return showMessage('firstTile');
    } else {
      _ref = this.id.match(/(\d+)_(\d+)/).slice(1), x = _ref[0], y = _ref[1];
      if (selectedCoordinates === null) {
        selectedCoordinates = {
          x1: x,
          y1: y
        };
        $this.addClass('selected');
        return showMessage('secondTile');
      } else {
        selectedCoordinates.x2 = x;
        selectedCoordinates.y2 = y;
        socket.send("move:" + (JSON.stringify(selectedCoordinates)));
        return endTurn();
      }
    }
  };

  swapTiles = function(_arg) {
    var x1, x2, y1, y2, _ref;
    x1 = _arg.x1, y1 = _arg.y1, x2 = _arg.x2, y2 = _arg.y2;
    _ref = [tiles[x2][y2], tiles[x1][y1]], tiles[x1][y1] = _ref[0], tiles[x2][y2] = _ref[1];
    return drawTiles(x1, y1, x2, y2);
  };

  updateUsedWords = function(newWords) {
    var _ref;
    if (Object.keys(usedWords).length === 0) {
      _ref = [newWords.wordsHtml, newWords.defs], usedWords.wordsHtml = _ref[0], usedWords.defs = _ref[1];
    } else if (newWords.wordsHtml.length > 0) {
      usedWords.wordsHtml = usedWords.wordsHtml.concat(", " + newWords.wordsHtml);
    }
    return $('#usedwords').html(usedWords.wordsHtml);
  };

  handleMessage = function(message) {
    var content, currPlayerNum, moveScore, newWords, nonTurnTimer, player, players, swapCoordinates, tick, turnTimer, type, _ref, _ref2, _ref3;
    _ref = typeAndContent(message), type = _ref.type, content = _ref.content;
    switch (type) {
      case 'welcome':
        _ref2 = JSON.parse(content), players = _ref2.players, currPlayerNum = _ref2.currPlayerNum, tiles = _ref2.tiles, myNum = _ref2.yourNum, newWords = _ref2.newWords, turnTime = _ref2.turnTime;
        startGame(players, currPlayerNum);
        $('#usedwords, #grid, #scores #meScore #opponentScore').show();
        $('#usedwords').html("");
        usedWords = {};
        return updateUsedWords(newWords);
      case 'moveResult':
        _ref3 = JSON.parse(content), player = _ref3.player, swapCoordinates = _ref3.swapCoordinates, moveScore = _ref3.moveScore, newWords = _ref3.newWords;
        showMoveResult(player, swapCoordinates, moveScore, newWords);
        return updateUsedWords(newWords);
      case 'opponentQuit':
        return showMessage('opponentQuit');
      case 'timeIsUp':
        return endTurn(true);
      case 'yourTurnNow':
        return startTurn(true);
      case 'tick':
        if (myTurn) {
          turnTimer = "#meTimer";
          nonTurnTimer = "#opponentTimer";
        } else {
          turnTimer = "#opponentTimer";
          nonTurnTimer = "#meTimer";
        }
        tick = JSON.parse(content);
        if (tick === "tick") {
          $(turnTimer).html(turnTime);
          $(nonTurnTimer).hide();
          return $(turnTimer).show();
        } else {
          $(turnTimer).html(parseInt($(turnTimer).html()) - 1);
          if (parseInt($(turnTimer).html()) <= 5) {
            return $(turnTimer).removeClass('turnColorRed turnColorGreen').addClass('turnColorYellow');
          }
        }
    }
  };

  typeAndContent = function(message) {
    var content, ignore, type, _ref;
    _ref = message.match(/(.*?):(.*)/), ignore = _ref[0], type = _ref[1], content = _ref[2];
    return {
      type: type,
      content: content
    };
  };

  getPlayerName = function(player) {
    var name;
    name = null;
    if (player.num === myNum) {
      return name = "Þú";
    } else {
      return name = "Mótspilari";
    }
  };

  toArray = function(newWords) {
    var key, value, words, _ref;
    words = [];
    _ref = newWords.defs;
    for (key in _ref) {
      value = _ref[key];
      words.push(key);
    }
    return words;
  };

  showNotice = function(moveScore, newWords, player) {
    var $notice, fannOrdTexti, words;
    words = toArray(newWords);
    $notice = $("<p class='notice'></p>");
    if (moveScore === 0) {
      if (player.num === myNum) {
        $notice.html("Þú fannst engin ný orð í þetta sinn.");
      } else {
        $notice.html("" + (getPlayerName(player)) + " fann engin ný orð.");
      }
    } else {
      fannOrdTexti = "" + (getPlayerName(player)) + " fann ";
      if (player.num === myNum) fannOrdTexti = "Þú fannst ";
      $notice.html(" \n" + fannOrdTexti + " " + words.length + " orð:<br /> \n<b>" + (words.join(', ')) + "</b><br /> \nsem gefur <b>" + (moveScore / words.length) + "x" + words.length + "\n= " + moveScore + "</b> stig!");
    }
    return showThenFade($notice);
  };

  showThenFade = function($elem) {
    $elem.insertAfter($('#grid'));
    return $elem.effect("highlight", {
      color: "#eb4"
    }, 5500, function() {
      return $elem.remove();
    });
  };

  startGame = function(players, currPlayerNum) {
    $("#meName").html(getPlayerName(players[myNum - 1]));
    $("#meScore").html(players[myNum - 1].score);
    $("#opponentName").html(getPlayerName(players[2 - myNum]));
    $("#opponentScore").html(players[2 - myNum].score);
    drawTiles();
    if (myNum === currPlayerNum) {
      return startTurn();
    } else {
      return endTurn();
    }
  };

  showMoveResult = function(player, swapCoordinates, moveScore, newWords) {
    if (player.num === myNum) {
      $("#meScore").html(player.score);
    } else {
      $("#opponentScore").html(player.score);
    }
    showNotice(moveScore, newWords, player);
    swapTiles(swapCoordinates);
    if (player.num !== myNum) return startTurn();
  };

  $(document).ready(function() {
    $('#grid li').live('click', tileClick);
    $;
    socket = io.connect();
    socket.on('connect', function() {
      return showMessage('waitForConnection');
    });
    return socket.on('message', handleMessage);
  });

}).call(this);
