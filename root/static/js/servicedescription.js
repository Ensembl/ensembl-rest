[
    {
        "service" : "xrefs/symbol",
        "url" : "/xrefs/symbol/:species/:symbol",
        "arguments" : [ "db_type","external_db","object" ],
        "output" : [ "type", "id" ],
        "comService" : [ "homology/id", "lookup/id", "sequence/id" ]
   },

    {
        "service" : "sequence",
        "url" : "/sequence/id/:id",
        "arguments" : [ ],
        "output" : [ "desc", "id", "seq", "molecule" ],
        "comService" : [ "homology/id", "lookup/id", "sequence/id" ]
    },
    {
        "service" : "homology",
        "url" : "/homology/id/:id",
        "arguments" : [ ],
        "output" : [ "desc", "id", "seq", "molecule" ],
        "comService" : ["lookup/id", "sequence/id" ]
    }
]
