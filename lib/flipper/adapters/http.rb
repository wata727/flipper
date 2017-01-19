require 'net/http'
require 'json'

module Flipper
  module Adapters
    # Module for handling http requests.
    # Any class that needs to make an http request can include/use this
    module Request
      HEADERS = { 'Content-Type' => 'application/json' }.freeze

      def get_request(path)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri, HEADERS)
        response = http.request(request)
      end

      def post_request(path, data)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri, HEADERS)
        request.body = data.to_json
        response = http.request(request)
      end

      def delete_request(path)
        uri = URI.parse(path)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Delete.new(uri.request_uri, HEADERS)
        response = http.request(request)
      end
    end

    class Http
      include Flipper::Adapter
      include Request
      attr_reader :name

      def initialize(path_to_mount)
        @path = path_to_mount
        @name = :http
      end

      # Get one feature
      def get(feature)
        response = get_request(@path + "/api/v1/features/#{feature}")
        # JSON.parse(response.body)
      end

      # Add a feature
      def add(feature)
        response = post_request(@path + '/api/v1/features', name: feature)
        # JSON.parse(response.body)
      end

      def get_multi(features)
        # could be cool to add this feature as an api endpoint requesting multiple features
        # or alternatively use a persistent connection and request multiple endpoints
      end

      # Get all features
      def features
        response = get_request(@path + '/api/v1/features')
        # JSON.parse(response.body)
      end

      # Remove a feature
      def remove(feature)
        response = delete_request(@path + "/api/v1/features/#{feature}")
        # JSON.parse(response.body)
      end

      # Enable gate thing for feature
      def enable(feature, gate, thing)
        body = gate_request_body(gate.key, thing.value.to_s)
        response = post_request(@path + "/api/v1/features/#{feature.key}/#{gate.key}", body)
        # JSON.parse(response)
      end

      # Disable gate thing for feature
      def disable(feature, gate, _thing)
        response = delete_request(@path + "/api/v1/features/#{feature.key}/#{gate.key}")
        # JSON.parse(response)
      end

      private

      # Returns request body for enabling/disabling a gate
      # i.e gate_request_body(:percentage_of_actors, 10)
      # returns { 'percentage' => 10 }
      def gate_request_body(gate_key, value)
        parameter = gate_parameter(gate_key)
        { parameter.to_s => value }
      end

      def gate_parameter(gate_name)
        case gate_name.to_sym
        when :groups
          :name
        when :actors
          :flipper_id
        when :percentage_of_actors
          :percentage
        when :percentage_of_time
          :percentage
        else
          raise "#{gate_name} is not a valid flipper gate name"
        end
      end
    end
  end
end
