[
    {
        "service" : "xrefs/symbol",
        "url" : "/xrefs/symbol/:species/:symbol",
        "arguments" : [
                          "db_type","external_db","object"
                    ],
        "output" : [ "type", "id" ],
        "comService" : []
   },

    {
        "service" : "sequence",
        "url" : "/sequence/id/:id",
        "arguments" : [ ],
        "output" : [ "desc", "id", "seq", "molecule" ]
    }
]
