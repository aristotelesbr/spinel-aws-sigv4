# The official AWS Signature Version 4 test suite, signed as the gem's own
# suite_spec.rb signs it: each case's canonical request, string to sign and
# authorization header against the expected files AWS publishes.
require "aws-sigv4"

DIR = __dir__ + "/fixtures/suite"
CASES = %w[get-header-key-duplicate get-header-value-multiline get-header-value-order get-header-value-trim get-unreserved get-utf8 get-vanilla-empty-query-key get-vanilla-query-order-key-case get-vanilla-query-unreserved get-vanilla-query get-vanilla-utf8-query get-vanilla post-header-key-case post-header-key-sort post-header-value-case post-vanilla-empty-query-value post-vanilla-query-nonunreserved post-vanilla-query-space post-vanilla-query post-vanilla post-x-www-form-urlencoded-parameters post-x-www-form-urlencoded ]

def parse_request(raw)
  lines = raw.lines
  http_method, request_uri = lines.shift.split(" ", 2)
  request_uri = request_uri.sub(" HTTP/1.1\n", "")
  uri_path, query = request_uri.split("?", 2)
  if query
    query = query.split("&").map do |pair|
      key, value = pair.split("=")
      key = Aws::Sigv4::Signer.uri_escape(key) unless key.include?("%E1")
      "#{key}=#{Aws::Sigv4::Signer.uri_escape(value.to_s)}"
    end.join("&")
  end
  request_uri = Aws::Sigv4::Signer.uri_escape_path(uri_path)
  request_uri += "?" + query if query

  names = []
  values = {}
  previous = nil
  until lines.empty?
    line = lines.shift
    break if line.strip == ""
    if line.start_with?(" ") || line.start_with?("\t")
      values[previous][0] = values[previous][0] + " " + line.strip
    else
      key, value = line.strip.split(":")
      names << key unless values.key?(key)
      (values[key] ||= []) << value.to_s
      previous = key
    end
  end
  headers = {}
  names.each { |name| headers[name] = values[name].join(",") }

  { http_method: http_method, url: "https://#{headers["Host"]}#{request_uri}", headers: headers, body: lines.join }
end

signer = Aws::Sigv4::Signer.new(
  service: "service",
  region: "us-east-1",
  credentials: Aws::Sigv4::Credentials.new(access_key_id: "AKIDEXAMPLE", secret_access_key: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"),
  uri_escape_path: false,
  apply_checksum_header: false
)

CASES.each do |name|
  prefix = DIR + "/" + name + "/" + name
  signature = signer.sign_request(parse_request(File.read(prefix + ".req")))
  creq = signature.canonical_request == File.read(prefix + ".creq")
  sts = signature.string_to_sign == File.read(prefix + ".sts")
  authz = signature.headers["authorization"] == File.read(prefix + ".authz")
  puts "#{name}: creq=#{creq} sts=#{sts} authz=#{authz}"
  puts "  #{signature.headers["authorization"]}"
end
