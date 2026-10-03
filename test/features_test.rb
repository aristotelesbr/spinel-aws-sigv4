# The rest of the public surface: a presigned URL at a fixed time, a session
# token, unsigned headers, the checksum header switch, path escaping, and an
# event signature (sign_event takes Time.now, so its shape is printed, and the
# signature is checked against the header that carries it).
require "aws-sigv4"
require "aws-eventstream"

KEY = "AKIDEXAMPLE"
SECRET = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
DATE = { "X-Amz-Date" => "20150830T123600Z" }

def signer(**extra)
  Aws::Sigv4::Signer.new(service: "service", region: "us-east-1", access_key_id: KEY, secret_access_key: SECRET, **extra)
end

puts Aws::Sigv4::VERSION

url = signer.presign_url(http_method: "GET", url: "https://example.amazonaws.com/a%20b?x=1",
                         expires_in: 3600, time: Time.utc(2015, 8, 30, 12, 36, 0))
puts url

token = signer(session_token: "TOKEN").sign_request(http_method: "GET", url: "https://example.amazonaws.com/", headers: DATE, body: "")
puts token.headers.keys.sort.join(",")
puts token.headers["x-amz-security-token"]
puts token.headers["authorization"]

unsigned = signer(unsigned_headers: ["x-skip"]).sign_request(http_method: "GET", url: "https://example.amazonaws.com/",
                                                              headers: DATE.merge("X-Skip" => "1", "X-Keep" => "2"), body: "")
puts unsigned.canonical_request.lines[4]

no_checksum = signer(apply_checksum_header: false).sign_request(http_method: "PUT", url: "https://example.amazonaws.com/", headers: DATE, body: "x")
puts no_checksum.headers.keys.sort.join(",")

escaped = signer.sign_request(http_method: "GET", url: "https://example.amazonaws.com/a%20b/c%2Fd~e", headers: DATE, body: "")
puts escaped.canonical_request.lines[1]

headers, signature = signer.sign_event("00" * 32, "payload", Aws::EventStream::Encoder.new)
puts headers.keys.sort.join(",")
puts headers.keys.sort.map { |k| headers[k].type }.join(",")
puts signature.size
puts headers[":chunk-signature"].value.unpack1("H*") == signature
