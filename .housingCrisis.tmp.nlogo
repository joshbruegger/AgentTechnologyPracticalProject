;; Model by Melisa, Atakan, Zeynep, Josh.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                        ;;
;;                        VARIABLES                       ;;
;;                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [
  sites ;; Everything that is not a border, can be a house or a place to build a house in
  population ;; How many people live in the city

  percent-successful
  total-students
  old-student-count
  occupied
  current-increase
  old-tenant-count
]

patches-own[
  is-house?
  has-permit? ;; A house w/ permit allows more than 2 households
  tenant-count

  district
  price
  capacity

  racist?
  sexist?
  age-limit

  contract-length
]

turtles-own [
  international?
  gender?
  age

  max-price

  moved-in?
  viewing?
  leaving? ;; True is leaving the city
  copy
  days
  done?
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                        ;;
;;                  SETUP FUNCTIONS                       ;;
;;                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to populate-houses
  ;; Hatch initial population
  ask n-of (count houses * initially-occupied / 100) houses [
    set population population + capacity

    sprout capacity [ become-student ]

    set tenant-count capacity
    set pcolor red
  ]

end

to become-student
  set hidden? true

  set max-price (350 + (random (400))) ;; CHANGE THIS

  ifelse random 100 < international% [
    set international? true
  ] [
    set international? false
  ]

  set gender? false
  if random 100 < gender% [
    set gender? true
  ]

  set age random-normal age-average 10
  if (age < 17) or (age > 30) [ set age age-average ]

  set moved-in? true
  set viewing? false
  set leaving? false
  set copy [ contract-length ] of patch-here
  set days copy
  set done? false
end

to populate-houses-old

;; Paint occupied rentals red
ask n-of (count houses * initially-occupied / 100) patches with [is-house? = true and pcolor = green] [
  set pcolor red
  set occupied occupied + 1
]

; Paint not students houses black so they are not included
ask max-n-of (((100 - students%) * occupied) / 100) patches with [is-house? = true] [ red ] [
  set pcolor black
  set old-tenant-count old-tenant-count + 1
  set is-house? false
]

;; Paint students full houses red to populate initial students
ask max-n-of ((students% * occupied) / 100) patches with [ pcolor = red ] [ green ] [
  set old-student-count old-student-count + 1
]

;; Populate some red houses with old students
create-turtles old-student-count [
  set color white
  ;; set shape "circle" defult is circle now
  set max-price (350 + (random (400)))
  set international? false
  if random 100 < gender% [
    set gender? true
  ]
  if random-float 1 < (100 / international%) [
    set international? true
  ]
  set gender? false
  if random-float 1 < (100 / gender%) [
    set gender? true
  ]
  set age random-normal age-average 10  ;;one-of (list (age-average + 10) (age-average - 10
  if (age < 17) or (age > 30) [ set age age-average ]
  set moved-in? true
  set viewing? false
  set leaving? false
  set copy contract-length
  set days random copy
  set done? false
]
set total-students total-students + old-student-count

end

to setup
  ;; Clear everything
  clear-all
  reset-ticks

  set-default-shape turtles "circle"

  ;; Initialize variables
  set population 0
  set occupied 0

  create-city
  add-houses
  populate-houses

end

to add-houses
  ;; Create houses based on house-density
  ask n-of (house-density / 100 * count sites) sites [
    become-house
  ]
end

to become-house
  set is-house? true
  set pcolor green

  ;; Issue permit
  ifelse random 100 < permit-density [
    set has-permit? true
  ] [
    set has-permit? false
  ]

  ;; Capacity
  set capacity abs random-poisson mean-capacity
  if capacity < 1 [ set capacity 1 ]
  if capacity > max-capacity [set capacity max-capacity]

  ;; Cut capacity based on permit
  if capacity > 2 and has-permit? = false [
    set capacity 2
  ]

  ;; Tenant count
  set tenant-count 0

  ;; Price based on district
  ;; TODO: base on capacity and if shared or not
  let priceSD 200
  if district = "left" [ set price random-normal 400 priceSD ] ;; first average rent, second density
  if district = "right" [ set price random-normal 400 priceSD ] ;;  GUESSED NUMBERS FOR NOw
  if district = "top" [ set price random-normal 600 priceSD ]
  if district = "bottom" [ set price random-normal 350 priceSD ]
  if district = "center" [ set price random-normal 650 priceSD ]

  ;; Racism
  set racist? false
  if random 100 < nationality-discrimination% [
    set racist? true
  ]

  ;; Sexism
  set sexist? false
  if random 100 < sex-discrimination% [
    set sexist? true
  ]

  ;; Age discrimination
  set age-limit one-of (list (average-age-limit + random 10) (average-age-limit - random 10)) ;idk
  if (age-limit < 17) or (age-limit > 30) [ set age-limit average-age-limit ] ;idk

  ;; Contract lengths
  set contract-length int abs random-poisson 30
  if contract-length < 1 [ set contract-length 1 ]
  if contract-length > 60 [set capacity 60]
end

to-report houses
  report sites with [is-house? = true]
end

to-report full?
  report tenant-count = capacity
end

;; Creates  the initial map based on Groningen
to create-city
  ;; Set Districts
  ask patches [
    if pxcor < -40 [
      set district "left"
    ]
    if pxcor > 40 [
      set district "right"
    ]
    if pycor > 40 [
      ifelse pxcor < 0 [ set district "left" ] [ set district "right" ]
    ]
    if pxcor >= -40 and pxcor <= 40 and pycor >= 0 and pycor <= 40 [
      set district "top"
    ]
    if pxcor >= -40 and pxcor <= 40 and pycor >= -60 and pycor <= 0[
      set district "bottom"
    ]
    if pxcor > -20 and pxcor < 20 and pycor > -20 and pycor < 20[
      set district "center"
    ]
  ]

  ;; Paint district border
  ask patches [
    if count neighbors with [district != [district] of myself] > 0 and pxcor < 69 and pxcor > -69 [
      set pcolor blue
    ]
  ]
  ;; Fix borders top
  ask patches with [ pcolor = blue] [
    if pycor = 50 and count patches with [pxcor = [pxcor] of myself and pycor = [pycor] of myself - 1 and pcolor != blue] > 0[
      set pcolor black
    ]
  ]
  ;; Fix borders bottom
  ask patches with [ pcolor = blue] [
    if pycor = -50 and count patches with [pxcor = [pxcor] of myself and pycor = [pycor] of myself + 1 and pcolor != blue] > 0[
      set pcolor black
    ]
  ]

  ;; Remove district in border lines
  ask patches with [ pcolor = blue ] [
    set district "border"
    set is-house? false
    ]

  ;; Add non district into agentset called sites for better handling
  set sites patches with [district != "border"]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                        ;;
;;                  EVERY TICK FUNCTIONS                  ;;
;;                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; Increase the student population
  set current-increase  int((student-increase% * total-students) / 100)
  if (ticks mod 15 = 1) and (ticks > 0) [
    ask max-n-of current-increase turtles [ white ] [
      hatch int ((student-increase% * total-students) / 100) [ ;;USE SPROUT HERE TOO
        if any? patches with [ pcolor = green or pcolor = yellow ] [
          move-to one-of patches with [ pcolor = green or pcolor = yellow ]
          set moved-in? false
          set viewing? true
        ]
        set total-students total-students + 1 ;;maybe + current-increase instead
      ]
      if random-float 1 < 0.2 and random-float 1 < 0.5 [
        die
        set pcolor violet
      ]
    ]
  ]

  ask turtles [
    start
  ]

  update
  tick
end

to update
  let successful-students count turtles with [ moved-in? = true ]
  if total-students > 0 [
    set percent-successful successful-students / total-students
  ]
end

;; Start based on availability only
to start
  set done? false
  set days days + 1

  if moved-in? = false and viewing? = false and done? = false [
    set done? true
    ifelse count turtles-on patch-here > [capacity] of patch-here [
      move-to one-of other patches with [ pcolor = green or pcolor = yellow ]
    ] [
      set pcolor yellow
      set viewing? true
    ]
  ]

  if viewing? = true and done? = false [
    set done? true
    ifelse (max-price <= price) or (international? = true and racist? = true)
            or (gender? = true and sexist? = true) or (age < age-limit) [
      move-to one-of other patches with [ pcolor = green or pcolor = yellow ]
      set viewing? false
      set moved-in? false
    ] [
      set pcolor red
      set viewing? false
      set moved-in? true
      set copy contract-length
    ]
  ]

  if moved-in? = true and done? = false [
    set done? true
    set copy copy - 1
    if copy < days [
      set leaving? true
    ]
  ]

  ;; i changed this entire thing
  if leaving? = true and done? = false[
    ifelse random-float 1 < 0.33 [
      die
    ] [
      set done? true
      move-to one-of other patches with [ pcolor = green ]
      set moved-in? false
      set leaving? false
    ]
    set pcolor green
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
390
97
962
510
-1
-1
4.0
1
10
1
1
1
0
1
1
1
-70
70
-50
50
0
0
1
ticks
30.0

BUTTON
21
27
186
74
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
285
192
318
international%
international%
0
100
47.0
1
1
NIL
HORIZONTAL

SLIDER
21
75
198
108
house-density
house-density
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
17
406
245
439
nationality-discrimination%
nationality-discrimination%
0
100
18.0
1
1
NIL
HORIZONTAL

SLIDER
17
439
201
472
sex-discrimination%
sex-discrimination%
0
100
22.0
1
1
NIL
HORIZONTAL

BUTTON
193
28
358
75
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
21
108
198
141
initially-occupied
initially-occupied
0
100
61.0
1
1
NIL
HORIZONTAL

SLIDER
17
253
189
286
students%
students%
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
17
318
189
351
gender%
gender%
0
100
62.0
1
1
NIL
HORIZONTAL

PLOT
16
534
216
684
percent-successful
days
students
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot percent-successful"

SLIDER
17
472
189
505
average-age-limit
average-age-limit
17
30
20.0
1
1
NIL
HORIZONTAL

SLIDER
17
351
189
384
age-average
age-average
17
40
21.0
1
1
NIL
HORIZONTAL

SLIDER
18
207
190
240
immigration-rate
immigration-rate
0
10
1.0
1
1
NIL
HORIZONTAL

MONITOR
255
600
312
645
rentals
count houses
17
1
11

MONITOR
386
649
456
694
NIL
occupied
17
1
11

MONITOR
386
599
504
644
NIL
current-increase
17
1
11

MONITOR
386
552
488
597
total-students
total-students
17
1
11

SLIDER
418
51
590
84
max-capacity
max-capacity
0
10
4.0
1
1
NIL
HORIZONTAL

PLOT
547
551
747
701
capacities
NIL
NIL
1.0
10.0
0.0
10.0
true
false
"histogram [capacity] of patches" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [capacity] of patches"

PLOT
1069
197
1269
347
Student number
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
1060
364
1260
514
plot 2
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [moved-in? = false]"

SLIDER
21
139
193
172
permit-density
permit-density
0
100
41.0
1
1
NIL
HORIZONTAL

SLIDER
590
52
762
85
mean-capacity
mean-capacity
0
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
387
700
516
745
old-student-count
old-student-count
17
1
11

MONITOR
255
554
312
599
sites
count sites
17
1
11

MONITOR
255
646
364
691
NIL
population
17
1
11

MONITOR
255
691
315
736
student
count turtles with [ is-student? = true ]
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
