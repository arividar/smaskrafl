Word game written in Node.js using socket.io. The game is from Trevor Burnham's excellent Coffeescript book, [Coffeescript: Accelerated Javascript Development] (http://pragprog.com/book/tbcoffee/coffeescript/ "Coffeescript: Accelerated Javascript Development").

Contains minor fixes and some new features:

  * used word display along with definitions
  * enforced time limit for player turns
  * support for more than 1 game at a time
  * a simple matchmaking feature to automatically connect waiting players
  * minor UI tweaks for usability etc.

### To Run
coffee 5x5server.coffee

There is also a branch that can be deployed to Heroku. Heroku doesn't support WebSockets yet so the clients fall back to XHR long-polling.
