# Smákrafl 🇮🇸

Smákrafl is an Icelandic word game built with CoffeeScript, Node.js, and Socket.IO. It's a multiplayer web-based game where players compete to find Icelandic words by swapping letters on a grid.

*Originally based on an example from "CoffeeScript: Accelerated JavaScript Development" by Trevor Burnham.*

## 🎮 Game Overview

### How to Play
- **Objective**: Find as many 4+ letter Icelandic nouns as possible
- **Rules**: Words must be in nominative case, singular, without articles
- **Gameplay**: Take turns swapping two letters on an 8×8 grid
- **Time Limit**: 60 seconds per turn
- **Game Length**: 10 moves per player
- **Scoring**: Letter values × number of words formed in a single move

### Game Mechanics
- **Grid**: 8×8 board with weighted Icelandic letter distribution
- **Word Validation**: Uses comprehensive Icelandic dictionary
- **Scoring System**: Each letter has a point value, multiplied by word count
- **Real-time**: Instant move updates and live opponent interaction

## 🚀 Quick Start

### Prerequisites
- Node.js 0.6.10+
- npm

### Installation & Setup
```bash
# Clone the repository
git clone https://github.com/arividar/smaskrafl.git
cd smaskrafl

# Install dependencies
npm install

# Start the server
coffee ssserver.coffee

# Open your browser
# Navigate to http://localhost:3000
```

### Playing the Game
1. Enter your username on the landing page
2. Wait for other players to join the lobby
3. Click on a player's name to send a game invitation
4. Accept/decline invitations to start playing
5. Take turns swapping letters to form words
6. Game ends after 10 moves each - highest score wins!

## 🏗️ Architecture

### Core Components

**Server-Side** (`ssserver.coffee`):
- Express HTTP server for static files
- Socket.IO WebSocket server for real-time communication
- Game session management and player matchmaking
- Turn-based timer system (60 seconds per turn)

**Game Logic**:
- `GameManager`: Handles multiple games and player management
- `Game`: Individual game state and turn management
- `Player`: Player data, scoring, and move validation
- `Dictionary`: Icelandic word validation and marking
- `Grid`: 8×8 letter grid with swap functionality

**Client-Side**:
- `index.html`: Login and lobby interface
- `game.html`: Main game board and UI
- `ssclient.coffee`: Game client logic and server communication
- `sslobby.coffee`: Lobby management and invitation system

### Communication Flow
```
Client ←→ Socket.IO ←→ Server
  ↓                    ↓
Login → Lobby → Invite → Game → Moves → Results → End
```

## 🛠️ Development

### Project Structure
```
smaskrafl/
├── ssserver.coffee         # Main server
├── GameManager.coffee      # Game session management
├── Game.coffee            # Individual game logic
├── Player.coffee          # Player state and scoring
├── Dictionary.coffee      # Word validation
├── Grid.coffee           # Game board logic
├── client/               # Client-side files
│   ├── index.html        # Landing page
│   ├── game.html         # Game interface
│   ├── ssclient.coffee   # Game client
│   └── sslobby.coffee    # Lobby client
├── nonfetlc.js          # Icelandic word dictionary
└── package.json         # Dependencies
```

### Key Technologies
- **Backend**: CoffeeScript, Node.js, Express v2, Socket.IO
- **Frontend**: HTML5, CSS3, jQuery, jQuery UI
- **Real-time**: WebSocket communication via Socket.IO
- **Deployment**: Heroku-ready with Procfile

### Message Protocol
The game uses a simple message protocol over WebSockets:

**Client → Server**:
- `login: {playername}` - Player authentication
- `invite: targetPlayer` - Send game invitation
- `inviteResponse: yes/no` - Respond to invitation
- `move: {x1, y1, x2, y2}` - Submit letter swap

**Server → Client**:
- `playerList: "p1,p2,..."` - Available players
- `inviteFrom: playerName` - Incoming invitation
- `welcome: gameData` - Game start information
- `moveResult: moveData` - Move outcome and scoring
- `gameOver: {winner}` - Game completion

### Scoring System
```coffeescript
# Letter values (from Player.coffee)
tileValues =
    a: 1, 'á': 4, b: 4, d: 3, 'ð': 2, e: 2, 'é': 9, f: 3, g: 2, h: 3,
    i: 1, 'í': 7, j: 4, k: 2, l: 1, m: 2, n: 1, o: 5, 'ó': 4, p: 5,
    r: 1, s: 1, t: 1, u: 1, 'ú': 7, v: 3, x: 10, y: 6, 'ý': 8,
    'þ': 8, 'æ': 6, 'ö': 6

# Final score = (sum of letter values) × (number of new words formed)
```

## 📚 Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Developer setup and architecture guide
- **[GAME_FLOW_DOCUMENTATION.md](./GAME_FLOW_DOCUMENTATION.md)** - Comprehensive game flow documentation

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### Setting Up Development Environment
1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/smaskrafl.git`
3. Install dependencies: `npm install`
4. Start development server: `coffee ssserver.coffee`
5. Make your changes
6. Test thoroughly (multiplayer functionality requires multiple browser windows/tabs)

### Code Style Guidelines
- **CoffeeScript**: Follow existing indentation and naming conventions
- **Comments**: Add comments for complex game logic
- **Console Logging**: Use descriptive logging for debugging multiplayer interactions
- **Error Handling**: Always handle WebSocket disconnections and game state errors

### Areas for Contribution

**Game Features**:
- [ ] Spectator mode for watching ongoing games
- [ ] Game replay functionality
- [ ] Tournament/bracket system
- [ ] Player statistics and leaderboards
- [ ] Chat system during games

**Technical Improvements**:
- [ ] Upgrade to modern Node.js and Express versions
- [ ] Convert CoffeeScript to modern JavaScript/TypeScript
- [ ] Add comprehensive test suite
- [ ] Improve mobile responsiveness
- [ ] Add game state persistence
- [ ] Performance optimizations for large player counts

**UI/UX Enhancements**:
- [ ] Modern CSS styling and animations
- [ ] Better mobile interface
- [ ] Accessibility improvements
- [ ] Sound effects and visual feedback
- [ ] Dark mode theme

### Submitting Changes
1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes and test thoroughly
3. Commit with descriptive messages
4. Push and create a Pull Request
5. Include screenshots/demos for UI changes

### Testing Multiplayer Features
Since this is a multiplayer game, testing requires:
- Multiple browser windows/tabs for local testing
- Clear browser storage between tests
- Testing disconnection scenarios
- Validating game state synchronization

## 🚀 Deployment

### Heroku Deployment
The game is Heroku-ready with the included `Procfile`:

```bash
# Deploy to Heroku
heroku create your-app-name
git push heroku master
heroku open
```

### Environment Variables
No special environment variables required. The app uses `process.env.PORT` for Heroku deployment.

## 📄 License

This project is open source. Please check the repository for license details.

## 🙋‍♀️ Support

- **Issues**: Report bugs and feature requests in GitHub Issues
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Documentation**: Refer to the comprehensive documentation in this repository

---

**Smákrafl** - Bringing the beauty of Icelandic language to interactive word gaming! 🎮🇮🇸
