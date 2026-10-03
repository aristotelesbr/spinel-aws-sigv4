# The payload hash for a String, a StringIO and a File body, and a query
# string whose parameters need the stable sort by name, value and offset.
require "aws-sigv4"
require "stringio"

signer = Aws::Sigv4::Signer.new(
  service: "service", region: "us-east-1",
  access_key_id: "AKIDEXAMPLE", secret_access_key: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
)
headers = { "X-Amz-Date" => "20150830T123600Z" }
path = __dir__ + "/fixtures/body.txt"

[["string", "Action=ListUsers&Version=2010-05-08"],
 ["stringio", StringIO.new("Action=ListUsers&Version=2010-05-08")],
 ["file", File.open(path, "rb")]].each do |label, body|
  signature = signer.sign_request(http_method: "POST", url: "https://example.amazonaws.com/", headers: headers, body: body)
  puts "#{label}: #{signature.content_sha256}"
  puts "  #{signature.headers["authorization"]}"
end

query = signer.sign_request(http_method: "GET", url: "https://example.amazonaws.com/?b=2&a=1&a=0&c&a=1", headers: headers, body: "")
puts query.canonical_request.lines[2]
