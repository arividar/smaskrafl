fs = require 'fs'
Lazy = require 'lazy'

outFile = fs.createWriteStream("ORD2.js")
inFile = fs.createReadStream 'ORD2.txt'
inFile.once "open", (fd) ->
	new Lazy(inFile).lines.forEach (line) ->
			outFile.write '"' + line + '":"",' + "\n"
			console.log "Wrote: " + line

