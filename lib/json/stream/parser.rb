# encoding: UTF-8

module JSON
  module Stream

    class ParserError < RuntimeError;
    end

    # A streaming JSON parser that generates SAX-like events for
    # state changes. Use the json gem for small documents. Use this
    # for huge documents that won't fit in memory.
    class Parser
      BUF_SIZE = 512
      CONTROL = /[[:cntrl:]]/
      WS = /\s/
      HEX = /[0-9a-fA-F]/
      DIGIT = /[0-9]/
      DIGIT_1_9 = /[1-9]/
      DIGIT_END = /\d$/
      TRUE_RE = /[rue]/
      FALSE_RE = /[alse]/
      NULL_RE = /[ul]/
      TRUE_KEYWORD = 'true'
      FALSE_KEYWORD = 'false'
      NULL_KEYWORD = 'null'
      LEFT_BRACE = '{'
      RIGHT_BRACE = '}'
      LEFT_BRACKET = '['
      RIGHT_BRACKET = ']'
      BACKSLASH = '\\'
      SLASH = '/'
      QUOTE = '"'
      COMMA = ','
      COLON = ':'
      ZERO = '0'
      MINUS = '-'
      PLUS = '+'
      POINT = '.'
      EXPONENT = /[eE]/
      B, F, N, R, T, U = %w[b f n r t u]

      # Parses a full JSON document from a String or an IO stream and returns
      # the parsed object graph. For parsing small JSON documents with small
      # memory requirements, use the json gem's faster JSON.parse method instead.
      def self.parse(json)
        stream = json.is_a?(String) ? StringIO.new(json) : json
        parser = Parser.new
        builder = Builder.new(parser)
        while (buf = stream.read(BUF_SIZE)) != nil
          parser << buf
        end
        raise ParserError, "unexpected eof" unless builder.result
        builder.result
      ensure
        stream.close
      end

      # Create a new parser with an optional initialization block where
      # we can register event callbacks. For example:
      # parser = JSON::Stream::Parser.new do
      #   start_document { puts "start document" }
      #   end_document   { puts "end document" }
      #   start_object   { puts "start object" }
      #   end_object     { puts "end object" }
      #   start_array    { puts "start array" }
      #   end_array      { puts "end array" }
      #   key            {|k| puts "key: #{k}" }
      #   value          {|v| puts "value: #{v}" }
      # end
      def initialize(&block)
        @state = :start_document
        @utf8 = Buffer.new
        @listeners = Hash.new { |h, k| h[k] = [] }
        @stack, @unicode, @buf, @pos = [], "", "", -1
        @partial_stack = []
        @jpath, @jpath_tree = nil, nil
        @parsing_area = false
        @stop_parsing = nil
        instance_eval(&block) if block_given?
      end

      def parse(json, jpath=nil)
        jpath && jpath.strip!

        if (jpath.nil? || jpath.match(/^\/$/) || jpath.empty?)
          return self.class.parse(json)
        end

        @jpath = jpath
        @jpath_tree = JPathTree.new(jpath)
        stream = json.is_a?(String) ? StringIO.new(json) : json
        builder = Builder.new(self)

        while (buf = stream.read(BUF_SIZE)) != nil
          self << buf
        end

        raise ParserError, "unexpected eof" unless builder.result
        result = builder.result
        (result && result.values.first)
      ensure
        stream.close unless stream.nil?
      end

      %w[start_document end_document start_object end_object
          start_array end_array key value].each do |name|

        define_method(name) do |&block|
          @listeners[name] << block
        end

        define_method("notify_#{name}") do |*args|

          @listeners[name].each do |block|

            if (!@jpath) # If not used jpath, it should parse whole file
              block.call(*args)
            else

              if (!@jpath_tree.tree) # If jpath is invalid it should through error
                class InvalidJSONPath < Exception;
                end;
                raise InvalidJSONPath.new "Invalid json path. Example: '/root/child'"
              end

              if (!@parsing_area and @jpath_tree.parsing_feasible?(args[0])) # Check whether passed args[0] is comes under parsable area
                @parsing_area = true
              end

              if (name == :end_document) # An :end_document call is required
                block.call(*args)
                return
              end

              if (@parsing_area)
                block.call(*args)

                if (name == :key and @partial_stack.empty?) # Reached first key in the parsable JSON area
                  @partial_stack << :start_document
                  @partial_stack << :key
                end

                poped_partial_stack_value = @partial_stack[-1]

                if (poped_partial_stack_value == :key || poped_partial_stack_value == :start_array || poped_partial_stack_value == :start_object)
                  if (name == :start_array)
                    @partial_stack << :start_array
                  elsif (name == :start_object)
                    @partial_stack << :start_object
                  end
                end

                if (poped_partial_stack_value == :key)
                  if (name == :value)
                    @parsing_area = false
                    @stop_parsing = true
                    @partial_stack.pop
                  end
                elsif (poped_partial_stack_value == :start_array)
                  if (name == :end_array)
                    @partial_stack.pop
                    if (poped_partial_stack_value == :key)
                      @parsing_area = false
                      @stop_parsing = true
                      @partial_stack.pop
                    end
                  end
                elsif (poped_partial_stack_value == :start_object)
                  if (name == :end_object)
                    @partial_stack.pop
                    if (poped_partial_stack_value == :key)
                      @parsing_area = false
                      @stop_parsing = true
                      @partial_stack.pop
                    end
                  end
                end
              end
            end
          end

        end
        private "notify_#{name}"
      end

      # Pass data into the parser to advance the state machine and
      # generate callback events. This is well suited for an EventMachine
      # receive_data loop.
      def <<(data)

        (@utf8 << data).each_char do |ch|

          if (@stop_parsing)
          end

          @pos += 1
          case @state
            when :start_document
              case ch
                when LEFT_BRACE
                  @state = :start_object
                  @stack.push(:object)
                  @parsing_area = true
                  notify_start_document
                  notify_start_object
                  @parsing_area = false
                when LEFT_BRACKET
                  @state = :start_array
                  @stack.push(:array)
                  notify_start_document
                  notify_start_array
                when WS
                  # ignore
                else
                  error("Expected object or array start")
              end
            when :start_object
              case ch
                when RIGHT_BRACE
                  end_container(:object)
                when QUOTE
                  @state = :start_string
                  @stack.push(:key)
                when WS
                  # ignore
                else
                  error("Expected object key start")
              end
            when :start_string
              case ch
                when QUOTE
                  if @stack.pop == :string
                    @state = :end_value
                    notify_value(@buf)
                  else # :key
                    @state = :end_key
                    notify_key(@buf)
                  end
                  @buf = ""
                when BACKSLASH
                  @state = :start_escape
                when CONTROL
                  error('Control characters must be escaped')
                else
                  @buf << ch
              end
            when :start_escape
              case ch
                when QUOTE, BACKSLASH, SLASH
                  @buf << ch
                  @state = :start_string
                when B
                  @buf << "\b"
                  @state = :start_string
                when F
                  @buf << "\f"
                  @state = :start_string
                when N
                  @buf << "\n"
                  @state = :start_string
                when R
                  @buf << "\r"
                  @state = :start_string
                when T
                  @buf << "\t"
                  @state = :start_string
                when U
                  @state = :unicode_escape
                else
                  error("Expected escaped character")
              end
            when :unicode_escape
              case ch
                when HEX
                  @unicode << ch
                  if @unicode.size == 4
                    codepoint = @unicode.slice!(0, 4).hex
                    if codepoint >= 0xD800 && codepoint <= 0xDBFF
                      error('Expected low surrogate pair half') if @stack[-1].is_a?(Fixnum)
                      @state = :start_surrogate_pair
                      @stack.push(codepoint)
                    elsif codepoint >= 0xDC00 && codepoint <= 0xDFFF
                      high = @stack.pop
                      error('Expected high surrogate pair half') unless high.is_a?(Fixnum)
                      pair = ((high - 0xD800) * 0x400) + (codepoint - 0xDC00) + 0x10000
                      @buf << pair
                      @state = :start_string
                    else
                      @buf << codepoint
                      @state = :start_string
                    end
                  end
                else
                  error('Expected unicode escape hex digit')
              end
            when :start_surrogate_pair
              case ch
                when BACKSLASH
                  @state = :start_surrogate_pair_u
                else
                  error('Expected low surrogate pair half')
              end
            when :start_surrogate_pair_u
              case ch
                when U
                  @state = :unicode_escape
                else
                  error('Expected low surrogate pair half')
              end
            when :start_negative_number
              case ch
                when ZERO
                  @state = :start_zero
                  @buf << ch
                when DIGIT_1_9
                  @state = :start_int
                  @buf << ch
                else
                  error('Expected 0-9 digit')
              end
            when :start_zero
              case ch
                when POINT
                  @state = :start_float
                  @buf << ch
                when EXPONENT
                  @state = :start_exponent
                  @buf << ch
                else
                  @state = :end_value
                  notify_value(@buf.to_i)
                  @buf = ""
                  @pos -= 1
                  redo
              end
            when :start_float
              case ch
                when DIGIT
                  @state = :in_float
                  @buf << ch
                else
                  error('Expected 0-9 digit')
              end
            when :in_float
              case ch
                when DIGIT
                  @buf << ch
                when EXPONENT
                  @state = :start_exponent
                  @buf << ch
                else
                  @state = :end_value
                  notify_value(@buf.to_f)
                  @buf = ""
                  @pos -= 1
                  redo
              end
            when :start_exponent
              case ch
                when MINUS, PLUS, DIGIT
                  @state = :in_exponent
                  @buf << ch
                else
                  error('Expected +, -, or 0-9 digit')
              end
            when :in_exponent
              case ch
                when DIGIT
                  @buf << ch
                else
                  error('Expected 0-9 digit') unless @buf =~ DIGIT_END
                  @state = :end_value
                  num = @buf.include?('.') ? @buf.to_f : @buf.to_i
                  notify_value(num)
                  @buf = ""
                  @pos -= 1
                  redo
              end
            when :start_int
              case ch
                when DIGIT
                  @buf << ch
                when POINT
                  @state = :start_float
                  @buf << ch
                when EXPONENT
                  @state = :start_exponent
                  @buf << ch
                else
                  @state = :end_value
                  notify_value(@buf.to_i)
                  @buf = ""
                  @pos -= 1
                  redo
              end
            when :start_true
              keyword(TRUE_KEYWORD, true, TRUE_RE, ch)
            when :start_false
              keyword(FALSE_KEYWORD, false, FALSE_RE, ch)
            when :start_null
              keyword(NULL_KEYWORD, nil, NULL_RE, ch)
            when :end_key
              case ch
                when COLON
                  @state = :key_sep
                when WS
                  # ignore
                else
                  error("Expected colon key separator")
              end
            when :key_sep
              start_value(ch)
            when :start_array
              case ch
                when RIGHT_BRACKET
                  end_container(:array)
                when WS
                  # ignore
                else
                  start_value(ch)
              end
            when :end_value
              case ch
                when COMMA
                  @state = :value_sep
                when RIGHT_BRACKET
                  end_container(:array)
                when RIGHT_BRACE
                  end_container(:object)
                when WS
                  # ignore
                else
                  error("Expected comma or object or array close")
              end
            when :value_sep
              if @stack[-1] == :object
                case ch
                  when QUOTE
                    @state = :start_string
                    @stack.push(:key)
                  when WS
                    # ignore
                  else
                    error("Expected object key start")
                end
              else
                start_value(ch)
              end
            when :end_document
              error("Unexpected data") unless ch =~ WS
          end
        end
      end

      private

      def end_container(type)
        @state = :end_value
        if @stack.pop == type
          send("notify_end_#{type}")
        else
          error("Expected end of #{type}")
        end
        if @stack.empty?
          @state = :end_document
          notify_end_document
        end
      end

      def keyword(word, value, re, ch)
        if ch =~ re
          @buf << ch
        else
          error("Expected #{word} keyword")
        end
        if @buf.size == word.size
          if @buf == word
            @state = :end_value
            @buf = ""
            notify_value(value)
          else
            error("Expected #{word} keyword")
          end
        end
      end

      def start_value(ch)
        case ch
          when LEFT_BRACE
            @state = :start_object
            @stack.push(:object)
            notify_start_object
          when LEFT_BRACKET
            @state = :start_array
            @stack.push(:array)
            notify_start_array
          when QUOTE
            @state = :start_string
            @stack.push(:string)
          when T
            @state = :start_true
            @buf << ch
          when F
            @state = :start_false
            @buf << ch
          when N
            @state = :start_null
            @buf << ch
          when MINUS
            @state = :start_negative_number
            @buf << ch
          when ZERO
            @state = :start_zero
            @buf << ch
          when DIGIT_1_9
            @state = :start_int
            @buf << ch
          when WS
            # ignore
          else
            error("Expected value")
        end
      end

      def error(message)
        raise ParserError, "#{message}: char #{@pos}"
      end
    end

  end
end
