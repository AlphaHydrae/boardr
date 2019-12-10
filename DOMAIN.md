# Boardr domain

## Entities

* **Board** - A 2- or 3-dimensional board.
* **Rules** - The rules of a competitive **Board** game such as Chess, Go or Tic-Tac-Toe.
* **Game** - A game being played on a **Board** according to a set of **Rules**.
* **User** - A user of the boardr platform.
* **Player** - A **User** who has joined a **Game**.
* **Move** - A move made by a **Player** in a **Game** that is valid according
  to the **Game**'s **Rules**. The following types of moves are supported.

  * `take(position)` - Take a position on the board (e.g. play on the board in
    Go or Tic-Tac-Toe)

## Invariants

* There must be at least 2 **Players** in a **Game**.

  > At this time, each Player must be a distinct User.
* Only one **Move** can be played at a time.

  > The Game's Rules determine what a valid Move is, e.g. there is no
  > restriction that Players must each wait their turn. You could implement a
  > speed-based Game where several Moves by various Players are possible in a
  > given game state, and the first Player to play a valid move gets to play.