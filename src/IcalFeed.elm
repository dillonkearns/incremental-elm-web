module IcalFeed exposing (..)

import Ical
import Request.Events exposing (LiveStream)
import SanityApi.Scalar exposing (Id(..))
import Time
import Time.Extra


feed : List LiveStream -> String
feed liveStreams =
    liveStreams
        |> List.map toEvent
        |> Ical.generate { id = "//incrementalelm.com//elm-ical.tests//EN", domain = "incrementalelm.com" }


toEvent : LiveStream -> Ical.Event
toEvent liveStream =
    { id = liveStream.id |> (\(Id id) -> id)
    , stamp = liveStream.createdAt
    , start = liveStream.startsAt
    , end = liveStream.startsAt |> Time.Extra.add Time.Extra.Minute 90 Time.utc
    , summary = liveStream.title
    , description = liveStream.description
    , location =
        liveStream.youtubeId
            |> Maybe.map (\youtubeId -> "https://www.youtube.com/watch?v=" ++ youtubeId)
            |> Maybe.withDefault "https://twitch.tv/dillonkearns"
    }
