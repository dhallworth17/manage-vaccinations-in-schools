# frozen_string_literal: true

require "cgi"
require "net/http"
require "uri"

module Careplus
  class Client
    TARGET_NAMESPACE_BASE = "https://careplus.syhapp.thirdparty.nhs.uk"

    def initialize(username:, password:, namespace:, payload:)
      @username = username
      @password = password
      @namespace = namespace
      @payload = payload
    end

    def send_csv
      base_url = Settings.careplus.base_url.presence or
        raise "Settings.careplus.base_url is empty or has not been configured " \
                "(if this is a deployed service, the MOCK_CAREPLUS_URL environment variable may not be set)"
      uri = URI.parse("#{base_url}/#{namespace}/soap.SCHImms.cls")
      soap_body = build_soap_envelope
      post_soap_request(uri, soap_body)
    end

    def self.send_csv(...) = new(...).send_csv

    private_class_method :new

    private

    attr_reader :username, :password, :namespace, :payload

    def build_soap_envelope
      escaped_payload = CGI.escapeHTML(payload)

      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope
            xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
            xmlns:car="http://careplus.syhapp.thirdparty.nhs.uk">
          <soapenv:Header/>
          <soapenv:Body>
            <car:InsertImmsRecord>
              <car:strUserId>#{username}</car:strUserId>
              <car:strPwd>#{password}</car:strPwd>
              <car:strPayload>#{escaped_payload}</car:strPayload>
            </car:InsertImmsRecord>
          </soapenv:Body>
        </soapenv:Envelope>
      XML
    end

    def post_soap_request(uri, body)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/xml"
      request[
        "SOAPAction"
      ] = "http://careplus.syhapp.thirdparty.nhs.uk/soap.SCHImms.InsertImmsRecord"
      request.body = body

      http.request(request)
    end
  end
end
