module Json.Mustache exposing (Config, prettyString, prettyValue)

{-| Pretty print JSON stored as a `String` or `Json.Encode.Value`

@docs Config, prettyString, prettyValue

-}

-- third

import Json.Decode as Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Pretty exposing (Doc, align, append, char, hang, join, line, nest, softline, space, string, surround)
import Result



-- UTIL


commaLine : Doc
commaLine =
    append (char ',') line


colonSpace : Doc
colonSpace =
    append (char ':') space


openBrace : Doc
openBrace =
    append (char '{') line


closeBrace : Doc
closeBrace =
    append line (char '}')


openBracket : Doc
openBracket =
    append (char '[') line


closeBracket : Doc
closeBracket =
    append line (char ']')



-- CONVERT


nullToDoc : String -> Maybe Doc -> Doc
nullToDoc parentKeyPath maybeDoc =
    case maybeDoc of
        Just doc ->
            doc

        Nothing ->
            if String.isEmpty parentKeyPath  then
                string "null"
            else 
                surround (string "{{") (string "}}") (string parentKeyPath)



stringToDoc : String -> Doc
stringToDoc s =
    surround (char '"') (char '"') (string s)


encodeMustache : String -> a -> Doc
encodeMustache parentKeyPath _ =
    surround (string "{{") (string "}}") (string parentKeyPath)


objectToDoc : Int -> List ( String, Doc ) -> Doc
objectToDoc indent pairs =
    if List.isEmpty pairs then
        string "{}"

    else
        append
            (nest
                indent
                (append
                    openBrace
                    (join
                        (append (char ',') line)
                        (List.map
                            (\( key, doc ) ->
                                append (stringToDoc key) (append colonSpace doc)
                            )
                            pairs
                        )
                    )
                )
            )
            closeBrace


listToDoc : Int -> List Doc -> Doc
listToDoc indent list =
    if List.isEmpty list then
        string "[]"

    else
        append
            (nest
                indent
                (append
                    openBracket
                    (join commaLine list)
                )
            )
            closeBracket



-- DECODE


decodeDoc : Int -> Char -> String -> Decoder Doc
decodeDoc indent delimiter parentKeyPath =
    Decode.map
        (nullToDoc parentKeyPath)
        (Decode.maybe
            (Decode.oneOf
                [ Decode.map (encodeMustache parentKeyPath) Decode.string
                , Decode.map (encodeMustache parentKeyPath) Decode.float
                , Decode.map (encodeMustache parentKeyPath) Decode.bool
                , Decode.map (listToDoc indent) (Decode.lazy (\_ -> Decode.list (decodeDoc indent delimiter parentKeyPath)))
                , Decode.map (objectToDoc indent)
                    (Decode.lazy
                        (\_ ->
                            Decode.keyValuePairs Decode.value
                                |> Decode.andThen
                                    (\keyValues ->
                                        let
                                            decodingResult =
                                                keyValues
                                                    |> List.map
                                                        (\( k, v ) ->
                                                            ( k, Decode.decodeValue (decodeDoc indent delimiter (parentKeyPath ++ String.fromChar delimiter ++ k)) v )
                                                        )

                                            valid : List ( String, Doc )
                                            valid =
                                                decodingResult
                                                    |> List.concatMap
                                                        (\( k, v ) ->
                                                            case v of
                                                                Ok value ->
                                                                    [ ( k, value ) ]

                                                                Err _ ->
                                                                    []
                                                        )

                                            invalid =
                                                decodingResult
                                                    |> List.concatMap
                                                        (\( k, v ) ->
                                                            case v of
                                                                Ok _ ->
                                                                    []

                                                                Err e ->
                                                                    [ ( k, v, e ) ]
                                                        )
                                                    |> Debug.log ""
                                        in
                                        if invalid /= [] then
                                            Decode.fail ""

                                        else
                                            Decode.succeed valid
                                    )
                        )
                    )
                ]
            )
        )



-- PRETTY


{-| Formating configuration.

`indent` is the number of spaces in an indent.

`columns` is the desired column width of the formatted string. The formatter
will try to fit it as best as possible to the column width, but can still
exceed this limit. The maximum column width of the formatted string is
unbounded.

-}
type alias Config =
    { indent : Int
    , columns : Int
    , delimiter : Char
    }


{-| Formats a JSON string.
passes the string through `Json.Decode.decodeString` and bubbles up any JSON
parsing errors.
-}
prettyString : Config -> String -> Result String String
prettyString { columns, indent, delimiter } json =
    Decode.decodeString (decodeDoc indent delimiter "") json
        |> Result.map (Pretty.pretty columns)
        |> Result.mapError Decode.errorToString


{-| Formats a `Json.Encode.Value`. Internally passes the string through
`Json.Decode.decodeValue` and bubbles up any JSON parsing errors.
-}
prettyValue : Config -> Value -> Result String String
prettyValue { columns, indent, delimiter } json =
    Decode.decodeValue (decodeDoc indent delimiter "") json
        |> Result.map (Pretty.pretty columns)
        |> Result.mapError Decode.errorToString
