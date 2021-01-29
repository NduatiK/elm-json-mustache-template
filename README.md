# elm-json-mustache-template

Converts a json sample into a mustache template with the json pointers
as the mustache keys.

! Does not support arrays properly !

## Example
Take a string containing JSON and format it with 4 space indents.
```elm
json = """
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

Json.Print.prettyString { columns = 0, indent = 4, delimiter = '/' } exampleJsonInput
{-
{
    "name": {{/name}},
    "age": {{/age}},
    "isStrong": {{/isStrong}},
    "knownWeakness": null,
    "nicknames": [
        {{/nicknames}},
        {{/nicknames}}
    ],
    "extra": {
        "foo": {{/extra/foo}},
        "zap": {
            "cat": {{/extra/zap/cat}},
            "dog": {{/extra/zap/dog}}
        },
        "transport": [
            [
                {{/extra/transport}},
                {{/extra/transport}}
            ],
            [
                {{/extra/transport}},
                {{/extra/transport}},
                {{/extra/transport}}
            ]
        ]
    }
}
-}
```
