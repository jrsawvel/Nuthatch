curl -X GET "http://127.0.0.1:9200/veerydvlp1/veerydvlp1/_search" -H 'Content-Type: application/json' -d'
{
    "query": {
        "match_phrase": {
            "markup": "veery"
        }
    }
}
'
