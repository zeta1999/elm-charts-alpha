module Events1 exposing (main)

import Html
import Html.Attributes
import BarChart
import BarChart.Axis.Independent as IndependentAxis
import BarChart.Axis.Dependent as DependentAxis
import BarChart.Orientation as Orientation
import BarChart.Legends as Legends
import BarChart.Events as Events
import BarChart.Container as Container
import BarChart.Events as Events
import BarChart.Grid as Grid
import BarChart.Bars as Bars
import BarChart.Junk as Junk
import BarChart.Colors as Colors
import BarChart.Pattern as Pattern
-- TODO ^^^^
import Color



main : Program Never Model Msg
main =
  Html.beginnerProgram
    { model = init
    , update = update
    , view = view
    }



-- MODEL


type alias Model =
    { hovering : Maybe ( Int, Data) }


init : Model
init =
    { hovering = Nothing }



-- UPDATE


type Msg
  = Hover (Maybe (Int, Data))


update : Msg -> Model -> Model
update msg model =
  case msg of
    Hover hovering ->
      { model | hovering = hovering }



-- VIEW


view : Model -> Html.Html Msg
view model =
  Html.div
    [ Html.Attributes.style [ ( "font-family", "monospace" ) ] ]
    [ chart model ]



chart : Model -> Html.Html Msg
chart model =
  BarChart.view -- TODO should pixels be defined elsewhere due to orientation switching?
    { independentAxis = IndependentAxis.default 700 "gender" .label -- TODO customize label?
    , dependentAxis = DependentAxis.default 400 "$" -- TODO negative labels -- TODO horizontal border radius
    , container = Container.default "bar-chart"
    , orientation = Orientation.default
    , legends = Legends.default
    , events = Events.hoverOne Hover
    , grid = Grid.default
    , bars = Bars.custom (Bars.Properties Nothing 50 3) -- TODO set y on hover
    , junk = Junk.hoverOne model.hovering [ ( "ok", toString << .magnesium ) ]
    , pattern = Pattern.default
    }
    [ BarChart.bar "Indonesia" (always (Color.rgba 255 204 128 0.8)) [] .magnesium
    , BarChart.bar "Malaysia" (always Colors.blueLight) [] .heartattacks
    ]
    data


-- DATA


type alias Data =
  { magnesium : Float
  , expected : Float
  , heartattacks : Float
  , label : String
  }


data : List Data
data =
  [ Data 1 -5 -2 "Female"
  , Data 2 6 3 "Male"
  , Data 3 7 6 "Trans"
  , Data 4 8 3 "Fluid"
  ]
