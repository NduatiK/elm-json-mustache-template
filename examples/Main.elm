module Main exposing (main)

import Html exposing (textarea, text)
import Html.Attributes exposing (style)


-- third party

import Json.Print

main =
    textarea [ style "min-width" "45em" , style "min-height" "24em"  ] 
        [ text <| Result.withDefault "" (
            Json.Print.prettyString { columns = 0, indent = 4, delimiter = '/' } exampleJsonInput
            )
        ]


exampleJsonInput =
    """
{
  "name": "Arnold",
  "age": 70,
  "isStrong": true,
  "knownWeakness": null,
  "nicknames": ["Terminator", "The Governator"],
  "extra": {
    "foo": "bar",
    "zap": { "cat": 1, "dog": 2 },
    "transport": [
      ["ford", "chevy"],
      ["TGV", "bullet train", "steam"]
    ]
  }
}
"""
