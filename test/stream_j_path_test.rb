require 'json/stream'
require 'test/unit'
require 'pry'

class StreamJPathTest < Test::Unit::TestCase

  def setup
    @hash = {
        "root" => {
            "one" => "one-key",
            "two" => ["two1-key", "two2-key"],
            "three" => {
                "three1" => "three1-key",
                "three2" => "three2-key"
            },
            "four" => [
                {
                    "four-hash" => {
                        "four1" => "four1-key"
                    }
                },
                {
                    "four-array" => ["four1", "four2"]
                },
                {
                    "four-string" => "four-string"
                },
                {
                    "four-number" => 12.1
                }
            ]
        },
        "sibling" => "sibling-key"
    }
  end

  def test_parsing_without_jpath
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    result = @parser.parse(stream)
    assert_equal(@hash, result)
  end

  def test_parsing_with_empty_jpath
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    result = @parser.parse(stream)
    assert_equal(@hash, result)
  end

  def test_parsing_with_empty_jpath
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    result = @parser.parse(stream, '')
    assert_equal(@hash, result)
  end

  def test_parsing_whole
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    result = @parser.parse(stream, '/')
    assert_equal(@hash, result)
  end

  def test_parsing_root
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    result = @parser.parse(stream, '/root')
    assert_equal(@hash['root'], result)
  end

  def test_parsing_root_one
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    result = @parser.parse(stream, '/root/one')
    assert_equal(@hash['root']['one'], result)
  end

  def test_parsing_root_two
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    result = @parser.parse(stream, '/root/two')
    assert_equal(@hash['root']['two'], result)
  end

  def test_parsing_root_three
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    result = @parser.parse(stream, '/root/three')
    assert_equal(@hash['root']['three'], result)
  end

  def test_parsing_root_three1
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    result = @parser.parse(stream, '/root/three/three1')
    assert_equal(@hash['root']['three']['three1'], result)
  end

  def test_parsing_root_three2
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    hash = @parser.parse(stream, '/root/three/three2')
    assert_equal(@hash['root']['three']['three2'], hash)
  end

  def test_parsing_root_
    stream = File.open('test/stream_example.json')
    @parser = JSON::Stream::Parser.new
    hash = @parser.parse(stream, '/sibling')
    assert_equal(@hash['sibling'], hash)
  end

end
