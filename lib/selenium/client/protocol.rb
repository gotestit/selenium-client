module Selenium
  module Client

    HTTP_HEADERS = { 'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8' }
    
    # Module in charge of handling Selenium over-the-wire HTTP protocol
    module Protocol
      attr_reader :session_id
  
      def remote_control_command(verb, args=[])
        timeout(@default_timeout_in_seconds) do
          status, response = http_post(http_request_for(verb, args))
          raise Selenium::CommandError, response unless status == "OK"          
          response
        end
      end
      
      def string_command(verb, args=[])
        remote_control_command(verb, args)
      end
    
      def string_array_command(verb, args=[])
        csv = string_command(verb, args)
        token = ""
        tokens = []
        escape = false
        csv.split(//).each do |letter|
          if escape
            token += letter
            escape = false
            next
          end
          case letter
            when '\\'
              escape = true
            when ','
              tokens << token
              token = ""
            else
              token += letter
          end
        end
        tokens << token
        return tokens
      end

      def number_command(verb, args)
        string_command verb, args
      end
    
      def number_array_command(verb, args)
        string_array_command verb, args
      end

      def boolean_command(verb, args=[])
        parse_boolean_value string_command(verb, args)
      end
    
      def boolean_array_command(verb, args)
        string_array_command(verb, args).collect {|value| parse_boolean_value(value)}
      end
            
      protected

      def parse_boolean_value(value)
        if ("true" == value)
            return true
        elsif ("false" == value)
            return false
        end
        raise ProtocolError, "Invalid Selenese boolean value that is neither 'true' nor 'false': got '#{value}'"
      end

      def http_request_for(verb, args)
        data = "cmd=#{CGI::escape(verb)}"
        args.each_with_index do |arg, index|
          data << "&#{index.succ}=#{CGI::escape(arg.to_s)}"
        end
        data << "&sessionId=#{session_id}" unless session_id.nil?
        data
      end
            
      def http_post(data)
        # puts "Requesting ---> #{data.inspect}"
        http = Net::HTTP.new(@host, @port)
        http.open_timeout = default_timeout_in_seconds
        http.read_timeout = default_timeout_in_seconds
        response = http.post('/selenium-server/driver/', data, HTTP_HEADERS)
        # puts "RESULT: #{response.body.inspect}\n"
        if response.body[0..1] == "OK"
            [ response.body[0..1], response.body[3..-1] ]
        else
            [ "", response.body ]
        end
      end
     
    end

  end
end
