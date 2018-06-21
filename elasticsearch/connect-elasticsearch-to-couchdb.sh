curl -X PUT 'http://127.0.0.1:9200/_river/nuthatchdvlp1/_meta' -d '{ "type" : "couchdb", "couchdb" : { "host" : "localhost", "port" : 5984, "db" : "nuthatchdvlp1", "filter" : null }, "index" : { "index" : "nuthatchdvlp1", "type" : "nuthatchdvlp1", "bulk_size" : "100", "bulk_timeout" : "10ms" } }'

