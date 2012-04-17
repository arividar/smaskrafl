(function() {
  var Url, drawTiles, endGame, endTurn, getUrlVars, handleMessage, iceHTMLChar, myNum, myTurn, selectedCoordinates, showMessage, showMoveResult, showNotice, socket, startGame, startTurn, swapTiles, tileClick, tiles, toArray, turnColor, turnColorGreen, turnColorRed, turnColorYellow, turnTime, typeAndContent, updateUsedWords, usedWords;

  socket = tiles = selectedCoordinates = myNum = myTurn = usedWords = turnTime = null;

  turnColorGreen = "#181";

  turnColorRed = "#d32";

  turnColorYellow = "#FFFFB6";

  turnColor = turnColorGreen;

  Url = {
    encode: function(string) {
      return escape(this._utf8_encode(string));
    },
    decode: function(string) {
      return this._utf8_decode(unescape(string));
    },
    _utf8_encode: function(string) {
      var c, n, utftext;
      string = string.replace(/\r\n/g, "\n");
      utftext = "";
      n = 0;
      while (n < string.length) {
        c = string.charCodeAt(n);
        if (c < 128) {
          utftext += String.fromCharCode(c);
        } else if ((c > 127) && (c < 2048)) {
          utftext += String.fromCharCode((c >> 6) | 192);
          utftext += String.fromCharCode((c & 63) | 128);
        } else {
          utftext += String.fromCharCode((c >> 12) | 224);
          utftext += String.fromCharCode(((c >> 6) & 63) | 128);
          utftext += String.fromCharCode((c & 63) | 128);
        }
        n++;
      }
      return utftext;
    },
    _utf8_decode: function(utftext) {
      var c, c1, c2, c3, i, string;
      string = "";
      i = 0;
      c = c1 = c2 = 0;
      while (i < utftext.length) {
        c = utftext.charCodeAt(i);
        if (c < 128) {
          string += String.fromCharCode(c);
          i++;
        } else if ((c > 191) && (c < 224)) {
          c2 = utftext.charCodeAt(i + 1);
          string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
          i += 2;
        } else {
          c2 = utftext.charCodeAt(i + 1);
          c3 = utftext.charCodeAt(i + 2);
          string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
          i += 3;
        }
      }
      return string;
    }
  };

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

  getUrlVars = function() {
    var parts, vars;
    vars = {};
    parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/g, function(m, key, value) {
      return vars[key] = value;
    });
    return vars;
  };

  startTurn = function(player, forced) {
    if (forced == null) forced = false;
    myTurn = true;
    $('#grid').removeClass('turnColorRed turnColorYellow').addClass('turnColorGreen');
    $('#opponentTimer').hide();
    $('#meTimer').show();
    if (forced) {
      $("#opponentTimer").html("0");
      showMoveResult(player, null, 0, []);
      return showMessage('yourTurnNow');
    } else {
      return showMessage('firstTile');
    }
  };

  endTurn = function(player, forced) {
    if (forced == null) forced = false;
    selectedCoordinates = null;
    myTurn = false;
    $('#grid').removeClass('turnColorGreen turnColorYellow').addClass('turnColorRed');
    $('#meTimer').hide();
    $('#opponentTimer').show();
    if (forced) {
      $('#meTimer').html("0");
      showMoveResult(player, null, 0, []);
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
    }, 3000);
  };

  showMessage = function(messageType) {
    var effectColor, messageHtml;
    effectColor = "#FFF";
    switch (messageType) {
      case 'waitForConnection':
        messageHtml = "Bíð eftir mótspilara";
        $('#usedwords, #grid, #opponentScore, #meScore').hide();
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
        $('#usedwords, #grid').hide();
        break;
      case 'gameOver':
        messageHtml = "";
        $('#usedwords, #meTimer, #opponentTimer').hide();
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
        return endTurn(null, false);
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
    var allUsedWords, newWordsHtmlSorted, _ref;
    if (Object.keys(usedWords).length === 0) {
      newWordsHtmlSorted = newWords.wordsHtml.split(", ").sort(function(a, b) {
        return a.localeCompare(b);
      }).join(", ");
      _ref = [newWordsHtmlSorted, newWords.defs], usedWords.wordsHtml = _ref[0], usedWords.defs = _ref[1];
    } else if (newWords.wordsHtml.length > 0) {
      allUsedWords = usedWords.wordsHtml.concat(", " + newWords.wordsHtml);
      usedWords.wordsHtml = allUsedWords.split(", ").sort().join(", ");
      usedWords.wordsHtml = allUsedWords.split(", ").sort(function(a, b) {
        return a.localeCompare(b);
      }).join(", ");
    }
    return $('#usedwords').html(usedWords.wordsHtml);
  };

  handleMessage = function(message) {
    var content, currPlayerNum, moveScore, newWords, nonTurnTimer, player, players, swapCoordinates, tick, turnTimer, type, winner, _ref, _ref2, _ref3, _ref4;
    _ref = typeAndContent(message), type = _ref.type, content = _ref.content;
    switch (type) {
      case 'welcome':
        _ref2 = JSON.parse(content), players = _ref2.players, currPlayerNum = _ref2.currPlayerNum, tiles = _ref2.tiles, myNum = _ref2.yourNum, newWords = _ref2.newWords, turnTime = _ref2.turnTime;
        startGame(players, currPlayerNum);
        $('#usedwords, #grid, #meScore, #opponentScore').show();
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
        player = JSON.parse(content);
        return endTurn(player, true);
      case 'yourTurnNow':
        player = JSON.parse(content);
        return startTurn(player, true);
      case 'tick':
        tick = JSON.parse(content);
        if (myTurn) {
          turnTimer = "#meTimer";
          nonTurnTimer = "#opponentTimer";
        } else {
          turnTimer = "#opponentTimer";
          nonTurnTimer = "#meTimer";
        }
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
        break;
      case 'gameOver':
        _ref4 = JSON.parse(content), winner = _ref4.winner, myNum = _ref4.yourNum;
        return endGame(winner);
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
    var $notice, fannOrdTexti, messageLocation, words;
    words = toArray(newWords);
    $notice = $("<p class='notice'></p>");
    if (moveScore === 0) {
      if (player.num === myNum) {
        return $notice.html("Þú fannst engin ný orð");
      } else {
        return $notice.html("" + player.name + " fann engin ný orð");
      }
    } else {
      fannOrdTexti = "" + player.name + " fann ";
      messageLocation = '#opponentMoveList';
      if (player.num === myNum) {
        fannOrdTexti = "Þú fannst ";
        messageLocation = '#meMoveList';
      }
      $notice.html(" \n" + fannOrdTexti + " " + words.length + " orð:<br /> \n<b>" + (words.join(', ')) + "</b><br /> \nsem gefur <b>" + (moveScore / words.length) + "x" + words.length + "\n= " + moveScore + "</b> stig!");
      $notice.insertAfter($(messageLocation));
      return $notice.effect("highlight", {
        color: "#eb4"
      }, 7500, function() {
        return $notice.remove();
      });
    }
  };

  startGame = function(players, currPlayerNum) {
    $("#meName").html(players[myNum - 1].name);
    $("#meScore").html(players[myNum - 1].score);
    $("#opponentName").html(players[2 - myNum].name);
    $("#opponentScore").html(players[2 - myNum].score);
    drawTiles();
    if (myNum === currPlayerNum) {
      return startTurn(players[2 - myNum], false);
    } else {
      return endTurn(players[myNum - 1], false);
    }
  };

  endGame = function(winner) {
    $("#grid").html("<center>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\nLeik lokið!\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n" + winner.name + " vann!\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n<FORM>\n<INPUT type=\"button\" value=\"Nýr leikur\" onClick=\"history.go(-1);return true;\">\n</FORM>\n</center>");
    return showMessage('gameOver');
  };

  showMoveResult = function(player, swapCoordinates, moveScore, newWords) {
    var moveString, words;
    words = toArray(newWords);
    moveString = "<b>" + player.moveCount + ": 0</b><br/>";
    if (words.length > 0) {
      moveString = "<b>" + player.moveCount + ": " + moveScore + "</b> - " + (words.join(', ')) + "<br/>";
    }
    console.log(player);
    if (player.num === myNum) {
      $("#meScore").html(player.score);
      $("#meMoveList").prepend(moveString);
    } else {
      $("#opponentScore").html(player.score);
      $("#opponentMoveList").prepend(moveString);
    }
    showNotice(moveScore, newWords, player);
    if (swapCoordinates) swapTiles(swapCoordinates);
    if (player.num !== myNum) return startTurn(player, false);
  };

  $(document).ready(function() {
    var pname, urlVars;
    $('#grid li').live('click', tileClick);
    urlVars = getUrlVars();
    pname = Url.decode(urlVars["player"]);
    socket = io.connect();
    socket.emit('login', {
      playername: pname
    });
    socket.on('connect', function() {
      return showMessage('waitForConnection');
    });
    return socket.on('message', handleMessage);
  });

}).call(this);
