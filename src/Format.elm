module Format exposing (..)

import List.Extra
import Regex


formatKeys nodes =
    nodes
        |> List.map
            (\( key, value ) ->
                String.concat
                    [ key
                    , ":"
                    , value
                    ]
            )
        |> String.join "\n"


normalizeField : ( String, String ) -> String
normalizeField ( key, value ) =
    String.concat
        [ key
        , ":"
        , formatValue value
        ]
        |> splitOverflowingLines


formatValue : String -> String
formatValue value =
    value
        |> Regex.replace (reg "[\\\\;,\"]") (\{ match } -> "\\" ++ match)
        |> Regex.replace (reg "(?:\u{000D}\n|\u{000D}|\n)") (\_ -> "\\n")


splitOverflowingLines : String -> String
splitOverflowingLines string =
    string
        |> String.toList
        |> List.Extra.greedyGroupsOf 74
        |> List.map String.fromList
        |> String.join "\n "


reg string =
    Regex.fromString string
        |> Maybe.withDefault Regex.never
