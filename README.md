# battle-ship-game
Challenge from https://www.panaxeo.com/coding-arena#api

Copy of the website of the challenge can be found in CodingArena folder.


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


