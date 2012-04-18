(function() {
  var Url, getUrlVars, iceHTMLChar, myNum, socket;

  socket = myNum = null;

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
