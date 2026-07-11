# The battle ship game

Challenge from https://www.panaxeo.com/coding-arena Might not work anymore, or there migh be a new challenge already. Copy of the website of the challenge can be found in [CodingArena folder](https://github.com/Bard89/battle-ship-game/blob/main/Coding%20Arena%20%E2%80%94%20Boost%20your%20coding%20skill%20and%20win%20cool%20prizes%20%E2%80%94%20Panaxeo%20%E2%80%94%20Crazy%20good%20software%20teams%20(02_12_2023%2023_21_07).html) . Read that.

**MOST USEFUL** -> To run the solver just run `bundle install` and then `ruby run_battleship_mock.rb`
which plays one game *visually*: you see the generated map, every shot on the board, the live
probability field and the stats at the end. Pass a game count to switch to the quiet benchmark.

```
ruby run_battleship_mock.rb [algo] [runs] [--seed N] [--delay S] [--verbose] [--sequential]

  ruby run_battleship_mock.rb                          # watch the solver play one game
  ruby run_battleship_mock.rb modified_probability_density --delay 0.5   # watch the old algo, slower
  ruby run_battleship_mock.rb constraint_solver 200    # quiet benchmark = the challenge score
  ruby run_battleship_mock.rb all 200                  # compare all algorithms on the same maps

  algo       constraint_solver (default), modified_probability_density,
             probability_density, hunt_and_target, brute_force, or all
  runs       number of games; omit it to watch one game being played
             (the summed move count of a 200-game run IS the challenge score)
  --seed N   every run plays a fresh random map set and prints its seed;
             pass --seed N to replay exact maps ( within one run all
             algorithms always share the same maps, so comparisons are fair )
  --delay S  seconds between moves in watch mode (default 0.15)
  --verbose  force watch mode even when a runs count is given (plays 1 game)
```

## Version history ( newest first )

### v2 - the constraint solver ( 2026 )

Score: **10,072 ± 20** expected per 200 games ( avg 50.4 moves/game, 43% fewer than v1 ).

[browse the v2 code](https://github.com/Bard89/battle-ship-game/tree/v2) | [everything that changed since v1](https://github.com/Bard89/battle-ship-game/compare/v1...v2)

What changed: the fleet now matches the official rules ( v1 was missing the 5-cell Carrier the
whole time! ), the mock mirrors the real API faithfully including all three avengers, and a new
constraint-based solver replaces the hand-tuned probabilities - it enumerates every legal ship
placement and PROVES when a ship is sunk, the exact thing v1 could not do.

<!-- v2 pics go here -->

### v1 - modified probability density ( 2023 )

Score: ~**17,700** per 200 games ( avg ~88 moves/game measured on the corrected fleet ).

[browse the v1 code](https://github.com/Bard89/battle-ship-game/tree/v1)

The original attempt: two hand-tuned probability fields ( before / after finding the avenger
ship ). Main unsolved problem: without a sunk confirmation from the game it kept shooting
around ships that were already dead.

<!-- v1 pics go here -->

## Brief Overview

It's a battleship game with a spin. We have a 12 X 12 game field with 6 ships. We want to sink all
the ships with as few shots as possible. The fleet, per the official rules: Avengers Helicarrier
(9 spaces, irregular), Carrier (5), Battleship (4), Destroyer (3), Submarine (3) and Patrol Boat (2)
-> 26 ship cells in total. Ships never touch each other, not even diagonally (that rule turns out
to be the key to solving the game well).

The spin:
The irregular Helicarrier has 4 "chimneys" on both sides of the ship and is carrying "avengers"
with special abilities. Destroying it makes ONE avenger ability available (usable once per map):

- **thor** hits the targeted cell plus up to 10 random untouched cells, all in one move
- **ironman** reveals (only to you) one cell of the smallest ship still afloat
- **hulk** destroys the whole ship at the targeted cell if that cell is a hit

<img width="600" alt="image" src="https://github.com/Bard89/battle-ship-game/assets/46139131/e4759f83-608b-4110-b478-731398b0a66b">

## The Solver

The real API was disabled before the project was finished, so everything runs against
`battleship_api_mock.rb`, which now mirrors the documented API faithfully: the response grid never
leaks unrevealed ships, `result` means "the move was valid" while `cell` carries the X/. outcome,
repeated shots don't count as moves, and all three avenger abilities are implemented
(`fire_with_avenger`). One assumption had to be made because the API is gone: the avenger stays
available from the Helicarrier's destruction until used, rather than expiring after one turn.

### Results (200 games, seed 42, identical maps for every algorithm)

| algorithm                      | total moves (=score) | avg moves/game |
|--------------------------------|---------------------:|---------------:|
| brute_force                    |               26,942 |         134.7 |
| hunt_and_target                |               27,108 |         135.5 |
| probability_density            |               24,683 |         123.4 |
| modified_probability_density   |               17,667 |          88.3 |
| **constraint_solver**          |           **10,033** |      **50.2** |

Larger verification run of the constraint solver: 5,000 games, zero errors, every "ship sunk"
deduction checked against the true board -> **average 50.36 ± 0.10 moves/game, i.e. an expected
200-game score of 10,072 ± 20** (observed 200-game blocks ranged 9,834..10,262).

For context, the all-time leaderboard best was **9,625**. Two things about that number:

1. The real challenge allowed 20 attempts on a fixed set of maps and kept your best score. The
   spread of 200-game scores is large (std ≈ 112), so a bot with our average would typically
   post ≈ 9,850 as its best-of-20.
2. An oracle version of our solver that is told exactly when each ship sinks (information the
   game does not provide) averages 48.40 -> 9,680 per 200 games. The winner was either very
   lucky, very good, or both. Respect.

### How the constraint solver works (`algos/constraint_solver.rb`)

Every turn it enumerates every legal placement of every remaining ship (as 144-bit masks) and
plays the cell with the best score. The official no-touch rule does most of the heavy lifting:

1. **Legality pruning** - a placement may never overlap known water and may never touch a
   revealed ship cell it doesn't cover (ships can't touch, not even diagonally).
2. **Sunk-ship deduction** - a hit cluster whose every legal covering placement is already fully
   hit IS a sunk ship: its whole neighborhood becomes known water and the ship leaves the fleet.
   This solves the historical problem of shooting around already-sunk ships without any
   sunk-confirmation from the game.
3. **Helicarrier tracking** - `avengerAvailable` flipping to true is a free "the Helicarrier just
   sank" signal (and the only sunk-confirmation the game ever gives).
4. **Calibrated probabilities** - each hit cluster is exactly one unidentified ship, so cluster
   cells get a mixture over the candidate (ship, placement) pairs; hidden ships contribute a
   placement-counting density. Predicted probabilities match observed hit rates within ~0.03.
5. **Probe ordering** - within a cluster the solver doesn't just shoot the most probable cell: a
   root expectimax over the cluster's hypotheses (with greedy rollouts) picks the probe that
   minimizes the expected number of misses to resolve the ship.
6. **Exact endgame** - once few placement combinations remain it enumerates all joint fleet
   configurations and plays the true posterior.
7. **Avenger policy** (all benchmarked on paired map sets): fire **thor** the moment it becomes
   available - its ~11 reveals compound through the rest of the game (holding it costs up to
   +0.9 moves/game, hulk is strictly worse); fire **ironman** instead only when everything still
   hidden is small (<= 3 cells), where its guaranteed anchor saves an expensive hunt.

### The approach to solve the game ( for future me )

1. Create a Mock of the game.
   1. `battleship_api_mock` To be able to solve the game I had to create a mock fo the game. The API calls were limited to 200 moves a day and to develop and optimize the solver we needed orders of magnitude more.
   2. `map_generator` -> Generates the map and places all the ships in the grid (seedable, so benchmark runs are reproducible).
   3. `run_battleship_mock` -> Runs the mock, is benchmarked and shows the game stats.
2. Try different algos to solve the game.
   1. The first approach is brute force. This gives us an idea of a worst case algo. `brute_force.rb`
   2. Second approach is a better strategy but still naive one. Called `hunt_and_target.rb`. We basically first try to find the ships by almost randomly shooting in the grid and then sinking them once we found them. This approach is similar to the one we might use as humans playing the game. I call it naive because we do not operate with any probabilities of where the ships might be. And as in life, in battleship game we can only think in probabilities.
   3. `probability_density.rb` approach brings an idea that depending on ship sizes we can assign probabilities to the cells / positions where the ships might be. Then we can periodically update the probabilities after every shot and win the game. Read the excellent article -> http://www.datagenetics.com/blog/december32011/index.html .
   4. `modified_probability_density` was my hand-tuned attempt at the above with two probability fields (before/after finding the avenger ship). Its main unsolved problem was that it kept shooting around ships that were already sunk, because the game gives no sunk confirmation. <img width="1559" alt="image" src="https://github.com/Bard89/battle-ship-game/assets/46139131/ee6b979f-c0ae-418c-909d-2bc73d27f417">
   5. `constraint_solver.rb` replaces the hand-tuned probability increments with exact placement
      enumeration and logical deduction (see above). The no-ships-touching rule + placement
      enumeration make "is this ship sunk?" provable in most cases, which was exactly the thing
      the modified probability density approach was missing.
3. Ideas how to further optimize the game.
   1. The remaining gap to a perfect-information player is ~2 moves/game (measured with a
      sunk-info oracle). Most of it sits in the late hunt for the last small ships.
   2. Smarter multi-turn planning during hunting (the solver is 1-ply greedy there) might
      recover a fraction of that, at significant complexity cost.

### Did I have fun?

Definitely! Learned a lot I realised how hard is it to manipulates grids even in 2D, and to write these lower level algo from scratch. And no chatGPT is not helpful at all. I guess not enough training data. Oh well maybe next year. ( end of 2023 ).

Update ( mid 2026 ): Claude finished the project. The API is long gone, but the mock now matches
the documented rules (the fleet was even missing the 5-cell Carrier the whole time!), the
avengers work, and the new solver more than halves the old score. Turns out the training data
caught up after all.

### The little I managed to pull out of the API before it was shut down.

Avengers capabilities ()
**hulk**
hulk ability will destroy the whole ship if the map point specified by the
row/column combination at the api endpoint hits the ship
(all the map points belonging to this ship will be marked as destroyed)
response

**ironman**
ironman ability will return 1 map point of the smallest non-destroyed ship,
this map point will be unaffected (the purpose of this ability is to give a hint to the user)
response

**thor**
thor ability will hit 10 random map points at maximum
(at maximum = if there are fewer untouched map points available than 10, all of them will be targeted by this ability)
after request like
game.test_fire_with_avenger(11,11, 'thor')

get a response like
{"grid"=>"************************************************************************************************************************************************", "cell"=>".", "result"=>true, "avengerAvailable"=>false, "mapId"=>1, "mapCount"=>200, "moveCount"=>118, "finished"=>false, "avengerResult"=>[{"mapPoint"=>{"x"=>9, "y"=>10}, "hit"=>false}, {"mapPoint"=>{"x"=>11, "y"=>6}, "hit"=>false}, {"mapPoint"=>{"x"=>11, "y"=>7}, "hit"=>false}, {"mapPoint"=>{"x"=>8, "y"=>0}, "hit"=>true}, {"mapPoint"=>{"x"=>10, "y"=>9}, "hit"=>false}, {"mapPoint"=>{"x"=>9, "y"=>0}, "hit"=>false}, {"mapPoint"=>{"x"=>11, "y"=>8}, "hit"=>false}, {"mapPoint"=>{"x"=>10, "y"=>4}, "hit"=>false}, {"mapPoint"=>{"x"=>11, "y"=>5}, "hit"=>false}, {"mapPoint"=>{"x"=>11, "y"=>2}, "hit"=>false}]}

beatified response
see that even in this case the game ended the "finished" was false, because the first shot didn't end the game
{
"grid": "************************************************************************************************************************************************",
"cell": ".",
"result": true,
"avengerAvailable": false,
"mapId": 1,
"mapCount": 200,
"moveCount": 118,
"finished": false,
"avengerResult": [
{
"mapPoint": {
"x": 9,
"y": 10
},
"hit": false
},
{
"mapPoint": {
"x": 11,
"y": 6
},
"hit": false
},
{
"mapPoint": {
"x": 11,
"y": 7
},
"hit": false
},
{
"mapPoint": {
"x": 8,
"y": 0
},
"hit": true
},
{
"mapPoint": {
"x": 10,
"y": 9
},
"hit": false
},
{
"mapPoint": {
"x": 9,
"y": 0
},
"hit": false
},
{
"mapPoint": {
"x": 11,
"y": 8
},
"hit": false
},
{
"mapPoint": {
"x": 10,
"y": 4
},
"hit": false
},
{
"mapPoint": {
"x": 11,
"y": 5
},
"hit": false
},
{
"mapPoint": {
"x": 11,
"y": 2
},
"hit": false
}
]
}
end

**reset**
response like
#<HTTParty::Response:0x7fabed9595e8 parsed_response={"availableTries"=>-1}, @response=#<Net::HTTPOK 200 OK readbody=true>, @headers={"x-powered-by"=>["Express"], "vary"=>["Origin"], "content-type"=>["application/json; charset=utf-8"], "etag"=>["W/\"15-H/dWmVC2Wt8CzJgIOmzsscSPy04\""], "function-execution-id"=>["nuqn8gusq9t6"], "x-cloud-trace-context"=>["6e56b4594f03c2a1fbd52bd976c59c7a"], "date"=>["Sat, 09 Dec 2023 20:40:49 GMT"], "server"=>["Google Frontend"], "content-length"=>["21"], "alt-svc"=>["h3=\":443\"; ma=2592000,h3-29=\":443\"; ma=2592000"], "connection"=>["close"]}>

beatified response
{
"availableTries" => -1
}
