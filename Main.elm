module Main exposing (main)

import Html.App exposing (program)
import View
import Model exposing (Model)
import Message exposing (..)
import Video
import Task
import Clip
import Random
import Window


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    VideosLoad videos ->
      { model
      | videos = videos
      } ! [Random.generate ClipLoad (Video.random videos)]

    VideosError _ ->
      model ! []

    ClipLoad maybeVideo ->
      case maybeVideo of
        Just video ->
          let
            (clip, cmd) = Clip.initial video
          in
            ({ model | clip = Just clip}, Cmd.map Measured cmd)
        Nothing ->
          model ! []

    Measured line ->
      case model.clip of
        Nothing ->
          model ! []
        Just clip ->
          let
            (newClip, cmd) = Clip.update line clip
          in
            ({ model | clip = Just newClip}, Cmd.map Measured cmd)

    PlayEnd ->
      {model | count = model.count + 1} ! [Random.generate ClipLoad (Video.random model.videos)]

    WindowSize size ->
      {model | size = size} ! []


main : Program Never
main =
  program
    { init =
        ( Model.initial
        , Cmd.batch
            [ Native.Measure.measure "Mod" "106px" "trigger the font"
                |> (flip Task.andThen) (\_ -> Video.load "unsoundscapes" "/data.json")
                |> Task.perform VideosError VideosLoad
            , Window.size
                |> Task.perform identity WindowSize

            ]
        )
    , view = View.view
    , update = update
    , subscriptions = (\model -> Window.resizes WindowSize)
    }