# Json::Stream::Path

It's a JSON Path basic implementation and memory optimization of JSON Stream - https://github.com/dgraham/json-stream

JSON Stream Path is well suit to parse a subset of JSON data from a huge JSON file.

Usual stream based parsers will reduce the memory only in parsing. But it is still keeps the graph(a intermediate data structure to create hash) of whole JSON data in memory. Again the graph is converted into hash that again consumes memory.If only subset of JSON data have to be parsed from a huge JSON file, graph no need to be created for the whole file and final hash also no need to contain whole JSON data.

JSON Stream Path is optimized for this situation. In JSON Stream Path, since path to parse JSON is mentioned, it will consume memory to create graph only for the subset of huge JSON data. Same way, final out come (hash) is the subset of huge JSON data which will again consume memory for the whole subset of JSON data.

## Installation

Add this line to your application's Gemfile:

    gem 'json-stream-path'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json-stream-path

## Usage

To parse subset of data from JSON file.

    require 'json/stream'
    parser = JSON::Stream::Parser.new
    stream = File.open('path/to/json-file.json')
    hash = parser.parse(stream, '/json/path')


To parse whole JSON file

    require 'json/stream'
    parser = JSON::Stream::Parser.new
    stream = File.open('path/to/json-file.json')
    hash = parser.parse(stream)

For the other basic usage refer https://github.com/dgraham/json-stream

Thanks to David Graham for his JSON Stream https://github.com/dgraham/json-stream

Future Enhancements:
    Implement full stack JSON Path
    Option to get hash or JSON

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
