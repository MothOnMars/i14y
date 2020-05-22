i14y
====

[![CircleCI](https://circleci.com/gh/GSA/i14y.svg?style=shield)](https://circleci.com/gh/GSA/i14y)
[![Code Climate](https://codeclimate.com/github/GSA/i14y/badges/gpa.svg)](https://codeclimate.com/github/GSA/i14y)
[![Test Coverage](https://codeclimate.com/github/GSA/i14y/badges/coverage.svg)](https://codeclimate.com/github/GSA/i14y)

Search engine for agencies' published content


docker-compose build web

## Dependencies/Prerequisistes
- Elasticsearch 6.8+:

You can run Elasticsearch using Docker:
```
$ docker-compose up elasticsearch
```

Verify that Elasticsearch 6.8.x is running on port 9268 (we use 9268
instead of the default 9200 to simplify development when running
multiple versions of Elasticsearch):
```
$ curl localhost:9268
{
  "name" : "wp9TsCe",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "WGf_peYTTZarT49AtEgc3g",
  "version" : {
    "number" : "6.8.7",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "c63e621",
    "build_date" : "2020-02-26T14:38:01.193138Z",
    "build_snapshot" : false,
    "lucene_version" : "7.7.2",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

- Kibana
Kibana is not required, but it can very helpful for debugging your Elasticsearch cluster or data.
You can also run Kibana using Docker:
```
$ docker-compose up kibana
```
Verify that you can access Kibana in your browser:
http://localhost:5668/

## Development

- Use `rvm` to install the version of Ruby specified in `.ruby-version`.
- `bundle install`.
- Copy `config/secrets_example.yml` to `config/secrets.yml` and fill in your own secrets. To generate a random long secret, use `rake secret`.
- Run `bundle exec rake i14y:setup` to create the neccessary indexes, index templates, and dynamic field templates.

If you ever want to start from scratch with your indexes/templates, you can clear everything out:
`bundle exec rake i14y:clear_all`

- Run the Rails server on port 8081 for compatibility with the
  search-gov app:
```
$ rails s -p 8081
```

-- Alternatively, run the server in a Docker container:
```
$ docker-compose up web
```
You should see the default Rails index page on http://localhost:8081/.

## Tests

`bundle exec rake`

Alternatively, you can use Docker for your test environment:
```
$ docker-compose up -d web
$ docker-compose exec web rake
```
