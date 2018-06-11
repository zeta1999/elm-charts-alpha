module BarChart exposing (view, Config, bar, barWithExpectation)

{-| -}

import Html
import Html.Attributes
import Svg
import Svg.Attributes

import BarChart.Junk as Junk
import BarChart.Axis.Dependent as AxisDependent
import BarChart.Axis.Independent as AxisIndependent
import BarChart.Grid as Grid
import BarChart.Events as Events
import BarChart.Legends as Legends
import BarChart.Container as Container
import BarChart.Orientation as Orientation
import BarChart.Pattern as Pattern
import BarChart.Bars as Bars

import Internal.Bars
import Internal.Orientation
import Internal.Axis
import Internal.Axis.Dependent
import Internal.Axis.Independent
import Internal.Axis.Intersection
import Internal.Axis.Range
import Internal.Junk
import Internal.Grid
import Internal.Container
import Internal.Pattern

import Internal.Utils as Utils
import Internal.Coordinate as Coordinate
import Color


{-| -}
type alias Config data msg =
  { independentAxis : AxisIndependent.Config data msg
  , dependentAxis : AxisDependent.Config msg
  , container : Container.Config msg
  , orientation : Orientation.Config
  , legends : Legends.Config data msg
  , events : Events.Config data msg
  , pattern : Pattern.Config
  , grid : Grid.Config
  , bars : Bars.Config msg
  , junk : Junk.Config data msg
  }


{-| -}
type alias Bar data msg =
  Internal.Bars.Bar data msg


{-| -}
bar : (data -> Color.Color) -> List (Svg.Attribute msg) -> (data -> Float) -> Bar data msg
bar =
  Internal.Bars.bar


{-| -}
barWithExpectation : (data -> Color.Color) -> List (Svg.Attribute msg) -> (data -> Float) -> (data -> Float) -> Bar data msg
barWithExpectation =
  Internal.Bars.barWithExpectation


{-| -}
view : Config data msg -> List (Bar data msg) -> List data -> Svg.Svg msg
view config bars data =
  let
    -- Data
    barsConfigs =
      List.concatMap Internal.Bars.barConfigs bars

    totalOfBars =
      List.length barsConfigs

    groups =
      Internal.Bars.toGroups config.orientation config.bars barsConfigs data

    -- Axes
    ( horizontalAxis, verticalAxis ) =
      case config.orientation of
        Internal.Orientation.Horizontal ->
          ( Internal.Axis.Dependent.toNormal config.dependentAxis
          , Internal.Axis.Independent.toNormal data config.independentAxis
          )

        Internal.Orientation.Vertical ->
          ( Internal.Axis.Independent.toNormal data config.independentAxis
          , Internal.Axis.Dependent.toNormal config.dependentAxis
          )

    -- System
    points =
      List.concatMap (List.map .point) groups

    system =
      toSystem config horizontalAxis verticalAxis data points

    -- Junk
    getJunk =
      Internal.Junk.getLayers
        [] -- (List.map junkLineInfo groups)
        (Internal.Axis.variable horizontalAxis)
        (Internal.Axis.variable verticalAxis >> Just)

    addGrid =
      Internal.Junk.addBelow
        (Internal.Grid.view system
          (Internal.Axis.ticks horizontalAxis)
          (Internal.Axis.ticks verticalAxis)
          config.grid
        )

    junk =
       getJunk system config.junk |> addGrid

    intersection =
      Internal.Axis.Intersection.default -- TODO

    -- View
    viewGroups =
      List.map (Internal.Bars.viewGroup config.orientation config.bars system (List.length data) totalOfBars) groups

    attributes =
      List.concat
        [ Internal.Container.properties .attributesSvg config.container
        -- TODO , Internal.Events.toContainerAttributes dataAll system config.events
        , [ viewBoxAttribute system ]
        ]
  in
  container config system junk.html <|
    Svg.svg attributes
      [ Svg.defs [] (clipPath system :: Internal.Pattern.toDefs config.pattern)
      , Svg.g [ Svg.Attributes.class "chart__junk--below" ] junk.below
      , Svg.g [ Svg.Attributes.class "groups" ] viewGroups
      , Internal.Axis.viewHorizontal system intersection horizontalAxis
      , Internal.Axis.viewVertical system intersection verticalAxis
      , Svg.g [ Svg.Attributes.class "chart__junk--above" ] junk.above
      ]



-- INTERNAL


viewBoxAttribute : Coordinate.System -> Html.Attribute msg
viewBoxAttribute { frame } =
  Svg.Attributes.viewBox <|
    "0 0 " ++ toString frame.size.width ++ " " ++ toString frame.size.height


container : Config data msg -> Coordinate.System -> List (Html.Html msg) -> Html.Html msg -> Html.Html msg
container config { frame } junkHtml plot  =
  let
    userAttributes =
      Internal.Container.properties .attributesHtml config.container

    sizeStyles =
      Internal.Container.sizeStyles config.container frame.size.width frame.size.height

    styles =
      Html.Attributes.style <| ( "position", "relative" ) :: sizeStyles
  in
  Html.div (styles :: userAttributes) (plot :: junkHtml)


chartAreaAttributes : Coordinate.System -> List (Svg.Attribute msg)
chartAreaAttributes system =
  [ Svg.Attributes.x <| toString system.frame.margin.left
  , Svg.Attributes.y <| toString system.frame.margin.top
  , Svg.Attributes.width <| toString (Coordinate.lengthX system)
  , Svg.Attributes.height <| toString (Coordinate.lengthY system)
  ]


clipPath : Coordinate.System -> Svg.Svg msg
clipPath system =
  Svg.clipPath
    [ Svg.Attributes.id (Utils.toChartAreaId system.id) ]
    [ Svg.rect (chartAreaAttributes system) [] ]


toSystem : Config data msg -> Internal.Axis.Config Float data msg -> Internal.Axis.Config Float data msg -> List data -> List Coordinate.Point -> Coordinate.System
toSystem config x y data points =
  let

    independentRange toHeight =
      { min = Coordinate.minimumOrZero toHeight points
      , max = Coordinate.maximum toHeight points
      }

    dependentRange =
      { min = 0.5
      , max = toFloat (List.length data) + 0.5
      }

    ( xRange, yRange, size ) =
      case config.orientation of
        Internal.Orientation.Horizontal ->
          ( independentRange .x
          , dependentRange
          , Coordinate.Size (Internal.Axis.pixels y) (Internal.Axis.pixels x)
          )

        Internal.Orientation.Vertical ->
          ( dependentRange
          , independentRange .y
          , Coordinate.Size (Internal.Axis.pixels x) (Internal.Axis.pixels y)
          )

    container = Internal.Container.properties identity config.container
    frame  = Coordinate.Frame container.margin size

    system =
      { frame = frame
      , x = xRange
      , y = yRange
      , xData = xRange
      , yData = yRange
      , id = container.id
      }
  in
  { system
  | x = Internal.Axis.Range.applyX (Internal.Axis.range x) system
  , y = Internal.Axis.Range.applyY (Internal.Axis.range y) system
  }



-- INTERNAL / DEFAULTS


defaultConfig : (data -> String) -> (data -> Float) -> Config data msg
defaultConfig label toY =
  { independentAxis = AxisIndependent.default 700 "" label
  , dependentAxis = AxisDependent.default 400 ""
  , container = Container.default "bar-chart"
  , orientation = Orientation.default
  , legends = Legends.default
  , events = Events.default
  , grid = Grid.default
  , bars = Bars.default
  , junk = Junk.default
  , pattern = Pattern.default
  }
