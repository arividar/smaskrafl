fs = require 'fs'
ord2 = fs.readFileSync 'ORD2.txt', 'utf8'
console.log 'ord2 lengd: ' + ord2.length
wordList = ord2.split '\n'
console.log wordList
#
# fileContents = """
# 	root = typeof exports === "undefined" ? window : exports;
# 	root.OWL2 = ['#{wordList.join "',\n'"}']
# """
# fs.writeFile 'OWL2.js', fileContents
