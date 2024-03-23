# The battle ship game

Challenge from https://www.panaxeo.com/coding-arena#api
Copy of the website of the challenge can be found in CodingArena folder. Read that.

**MOST USEFUL** -> To run the solver just run `ruby run_battleship_mock.rb`

## Brief Overview

It's a battleship game with a spin. We have a 12 X 12 game field with 6 ships. We want to sink all
the ships with as few shots as possible.

Not fully implemented spin:
One of those ships is then irregular and has 4 "chimneys" on both sites of the ship.
This irregular ship is carrying "avengers" with special abilities tjhat can help you later on in the game. 

## The Solver

The solver is fully functional except for the API and Avengers. Unfortunately the API was disabled before I could
finish the project. The API calls and responses are not properly documented which prevented me to go further. 
( see the original copy of the webpage )

To run the solver just run `ruby run_battleship_mock.rb`

### The approach to solve the game ( for future me )

1. Create a Mock of the game.
   1. `battleship_api_mock` To be able to solve the game I had to create a mock fo the game. The API calls were limited to 200 moves a day and to develop and optimize the solver we needed orders of magnitude more.
   2. `map_generator` -> Generates the map and places all the ships in the grid.
   3. `run_battleship_mock` -> Runs the mock, is benchmarked and shows the game stats.
2. Try different algos to solve the game.
   1. The first approach is brute force. This gives us an idea of a worst case algo. `brurte_force.rb`
   2. Second approach is a better strategy but still naive one. Called `hund_and_target.rb`. We basically first try to find the ships by almost randomly shooting in the grid and then sinking them once we found them. This approach is similar to the one we might use as humans playing the game. I call it naive because we do not operate with any probabilities of where the ships might be. And as in life, in battleship game we can only think in probabilities.
   3. `probability_density.rb` approach brings an idea that depending on ship sizes we can assign probabilities to the cells / positions where the ships might be. Then we can periodically update the probabilities after every shot and win the game. This is to my knowledge the best performing algo ( maybe aside from some ML approach ). Read the excellent article -> http://www.datagenetics.com/blog/december32011/index.html .
   4. My approach derives from the supposed use of the avengers. I used modified probability density strategy. Since the avengers are on a big irregular ship and all the other ships are just one line. I used 2 probability fields, one used before the avengers ship is found and the second one after it is found and sunk.
      1. You can see the implemented approaches in `modified_probability_density,rb` in `update_adjacent_cells.rb`, `update_hit_or_miss_probability.rb` and `update_ship_sunk_or_not`.
      2. Main problem I was facing is that the algo shoots around the ship even when the ship has been sunk. This adds significant overhead and makes the algo underperform. Theoretically the optimum results should be around 12000 per 200 games ( metric defined by the game masters ). What further complicates things is that the game masters decided to not provide a validation whether the ship was sunk or not. In standard battleship game this is available. I attempted to solve this problem with the `ship_sunk_or_not` approach.
      3. Another problem for the probability algo is that it performs much better when the ships are closer to the center. This migt even be an advantage, depending on how the game masters designed the grid.
      4. Final problem is how to determine how big the constants what modify the probabilities in game should be. See `constatns.rb`
3. Ideas hot wo further optimize the game.
   1. Refactor everything even more to make the code more readable.
   2. Make sensitivity analysis for the constants, to determine their ideal size. This would be done by running sets of simulations with different sized constants in certain size window.

### Did I have fun?

Definitely! Learned a lot I realised how hard is it to manipulates grids even in 2D, and to write these lower level algo from scratch. And no chatGPT is not helpful at all. I guess not enough training data. Oh well maybe next year. ( end of 2023 ).

### The little I managed to pull out of the API before it was shut down.

Avengers capabilities ()
**hulk**
hulk ability will destroy the whole ship if the map point specified by the
row/column combination at the api endpoint hits the ship
(all the map points belonging to this ship will be marked as destroyed)
response ?? NEED TO TRY OUT

**ironman**
ironman ability will return 1 map point of the smallest non-destroyed ship,
this map point will be unaffected (the purpose of this ability is to give a hint to the user)
response ?? NEED TO TRY OUT

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
