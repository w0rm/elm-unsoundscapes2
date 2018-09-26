module Video exposing (Video, videos, random)

import Json.Decode as Decode exposing (Decoder)
import Random exposing (Generator)
import String
import Char
import Dict exposing (Dict)


type alias Video =
    { createdTime : Int
    , title : String
    }


videos : Decoder (Dict String Video)
videos =
    Decode.maybe video
        |> Decode.list
        |> Decode.map (List.foldl addVideo Dict.empty)


addVideo : Maybe Video -> Dict String Video -> Dict String Video
addVideo maybeVideo videos =
    case maybeVideo of
        Just video ->
            let
                slug =
                    findSlug videos (captionToSlug video.title) 0
            in
                Dict.insert slug video videos

        Nothing ->
            videos


findSlug : Dict String a -> String -> Int -> String
findSlug dict str n =
    let
        key =
            if n == 0 then
                str
            else
                str ++ "-" ++ toString n
    in
        if Dict.member key dict then
            findSlug dict str (n + 1)
        else
            key


video : Decoder Video
video =
    Decode.map2
        Video
        (Decode.field "created_time" Decode.int)
        (Decode.at [ "title" ] Decode.string |> Decode.andThen caption)


caption : String -> Decoder String
caption =
    String.split "-" 
        >> List.head
        >> Maybe.andThen
            (\result ->
                case String.trim result of
                    "" ->
                        Nothing

                    value ->
                        value
                            |> String.foldr replaceChars ""
                            |> Decode.succeed
                            |> Just
            )
        >> Maybe.withDefault (Decode.fail "No caption")


captionToSlug : String -> String
captionToSlug =
    String.toLower
        >> String.filter (\c -> Char.isLower c || Char.isDigit c || c == ' ')
        >> String.words
        >> String.join "-"


{-| Remove some umlauts
-}
replaceChars : Char -> String -> String
replaceChars char =
    case char of
        'ó' ->
            String.cons 'o'
            
        'ç' ->
            String.cons 'c'

        'ü' ->
            (++) "ue"

        _ ->
            String.cons char


random : Dict String Video -> Generator String
random dict =
    let
        keys =
            Dict.keys dict
    in
        Random.int 0 (List.length keys - 1)
            |> Random.map ((flip List.drop) keys >> List.head >> Maybe.withDefault "")
