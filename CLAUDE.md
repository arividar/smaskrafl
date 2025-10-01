# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smákrafl is an Icelandic word game (similar to Scrabble) built with CoffeeScript, Node.js, Express, and Socket.IO. It's a multiplayer web-based game where players swap letters on a grid to form words.

## Commands

### Development
- **Start server**: `coffee ssserver.coffee`
- **Install dependencies**: `npm install`
- **Deploy to Heroku**: `git push heroku master` (uses Procfile)

### Dependencies
- CoffeeScript >= 1.2.0
- Express >= 2.5.8
- Socket.IO >= 0.9.2
- Node.js 0.6.10

## Architecture

### Server-Side Structure

**Main Server** (`ssserver.coffee`):
- Express HTTP server serving static files from `/client`
- Socket.IO WebSocket server for real-time game communication
- Game session management with player invitations and matchmaking
- Timer-based turn system (60 second turns, 10 moves max per player)

**Core Game Classes**:
- `GameManager`: Manages multiple games, player login/logout, game creation and recycling
- `Game`: Individual game state, players, scoring, turn management
- `Player`: Player data including ID, name, score, move count
- `Dictionary`: Icelandic word validation using word list from `nonfetlc.js`
- `Grid`: 8x8 game board for letter tiles

### Client-Side Structure

**Main Client** (`client/ssclient.coffee`):
- Socket.IO client for server communication
- jQuery-based UI with tile selection and game board rendering
- Real-time turn timer and move validation
- Icelandic character encoding utilities

**UI Files**:
- `index.html`: Player login/lobby page
- `game.html`: Main game interface
- `style.css` & `lobbyStyle.css`: Game styling

### Game Flow

1. **Login**: Players connect via lobby (`index.html`) and provide username
2. **Matchmaking**: Server manages player invitations and game pairing
3. **Game Start**: Two players are placed in a `Game` instance with fresh grid
4. **Turns**: 60-second timed turns, players swap two letters to form words
5. **Scoring**: Points awarded based on new words formed (word count × word length)
6. **End Game**: After 10 moves each, highest score wins

### Key Communication Patterns

**Client → Server Messages**:
- `login`: Player authentication with username
- `invite`: Send game invitation to another player
- `inviteResponse`: Accept/decline invitation
- `move`: Submit letter swap coordinates
- `newGame`: Start game between two specified players

**Server → Client Messages**:
- `welcome`: Game start data (tiles, players, turn info)
- `moveResult`: Move validation and scoring results
- `tick`/`tock`: Turn timer updates
- `timeIsUp`/`yourTurnNow`: Turn timeout handling
- `gameOver`: Final results and winner

### Data Structures

**Grid**: 2D array of Icelandic letters with special characters (Á, Ð, É, Í, Ó, Ú, Ý, Þ, Æ, Ö)

**Move Coordinates**: `{x1, y1, x2, y2}` for letter swapping

**Player State**: ID (socket ID), name, score, move count, player number (1 or 2)

## Development Notes

- All server code is in CoffeeScript, client uses both CoffeeScript and compiled JavaScript
- Uses legacy Express v2 syntax and older Socket.IO patterns
- Extensive console logging for debugging multiplayer state
- Game recycling system to reuse completed games
- Icelandic language support with proper character encoding
- Client-side URL parameter parsing for player names
