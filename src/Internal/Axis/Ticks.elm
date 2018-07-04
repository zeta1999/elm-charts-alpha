module Internal.Axis.Ticks exposing
  ( Config, Set
  , defaultFloat, defaultTime, full, int, float, time, intCustom, floatCustom, custom, set
  -- INTERNAL
  , Compiled, ticks
  )


import Internal.Axis.Tick as Tick
import Internal.Axis.Values as Values
import Internal.Coordinate as Coordinate



-- AXIS


{-| -}
type Config msg
  = Config (Int -> Coordinate.Range -> Coordinate.Range -> List (Set msg))


{-| -}
type Set msg =
  Set (Tick.Config msg) (List ( Float, String ))


-- API


{-| -}
defaultFloat : Config msg
defaultFloat =
  custom <| \pixels data range ->
    let smallest = Coordinate.smallestRange data range
        amount = defaultNumberOfTicks pixels data range
        values = Values.float (Values.around amount) smallest
    in
    [ set Tick.float toString identity values ]


{-| -}
defaultTime : Config msg
defaultTime =
  custom <| \pixels data range ->
    let smallest = Coordinate.smallestRange data range
        amount = defaultNumberOfTicks pixels data range
        values = Values.time amount smallest
    in
    [ set Tick.time Tick.format .timestamp values ]


{-| -}
full : Config msg 
full =
  custom <| \pixels data range ->
    let largest = Coordinate.largestRange data range
        amount = pixels // 90
        values = Values.float (Values.around amount) largest
    in
    [ set Tick.float toString identity values ]


{-| -}
int : Int -> Config msg
int n =
  custom <| \pixels data axis ->
    [ set Tick.int toString toFloat (Values.int (Values.around n) axis) ]


{-| -}
time : Int -> Config msg
time n =
   custom <| \pixels data axis ->
    [ set Tick.time Tick.format .timestamp (Values.time n axis) ]


{-| -}
float : Int -> Config msg
float n =
   custom <| \pixels data axis ->
    [ set Tick.float toString identity (Values.float (Values.around n) axis) ]


{-| -}
intCustom : Tick.Config msg -> Int -> Config msg
intCustom tick n =
  custom <| \pixels data axis ->
    [ set tick toString identity (Values.float (Values.around n) axis) ]


{-| -}
floatCustom : Tick.Config msg -> Int -> Config msg
floatCustom tick n =
  custom <| \pixels data axis ->
    [ set tick toString identity (Values.float (Values.around n) axis) ]


{-| -}
custom : (Int -> Coordinate.Range -> Coordinate.Range -> List (Set msg)) -> Config msg
custom =
  Config


{-| -}
set : Tick.Config msg -> (data -> String) -> (data -> Float) -> List data -> Set msg
set config format position data =
  let ticks d = ( position d, format d ) in
  Set config (List.map ticks data)



-- INTERNAL


{-| -}
type alias Compiled msg =
  { position : Float
  , label : String
  , config : Tick.Properties msg
  }


{-| -}
ticks : Int -> Coordinate.Range -> Coordinate.Range -> Config msg -> List (Compiled msg)
ticks pixels dataRange range (Config toSets) =
  let eachTick config ( p, l ) = Compiled p l (Tick.properties config)
      eachSet (Set config ticks) = List.map (eachTick config) ticks
  in
  List.map eachSet (toSets pixels dataRange range)
    |> List.concat


defaultNumberOfTicks : Int -> Coordinate.Range -> Coordinate.Range -> Int
defaultNumberOfTicks pixels data range =
    let smallest = Coordinate.smallestRange data range
        rangeLong = range.max - range.min
        rangeSmall = smallest.max - smallest.min
        diff = 1 - (rangeLong - rangeSmall) / rangeLong
    in
    round (diff * toFloat pixels / 90)
