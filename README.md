# aws-sigv4 (spinel-aws-sigv4)

The [aws-sigv4](https://rubygems.org/gems/aws-sigv4) gem for Spinel: AWS
Signature Version 4 request signing, presigned URLs and event-stream
signing. This is the **gem's own source**, aws-sigv4 1.12.1, with rewrites
only where Spinel cannot run it as is, and every rewrite marked
`# spinel-aws-sigv4:` in place. `require "aws-sigv4"` and the names are the
gem's. It depends on [spinel-aws-eventstream](https://github.com/aristotelesbr/spinel-aws-eventstream),
as the gem depends on aws-eventstream.

```ruby
require "aws-sigv4"

signer = Aws::Sigv4::Signer.new(
  service: "sts", region: "us-east-1",
  access_key_id: "AKIDEXAMPLE", secret_access_key: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
)
signature = signer.sign_request(
  http_method: "POST", url: "https://sts.us-east-1.amazonaws.com/",
  headers: { "X-Amz-Date" => "20150830T123600Z" },
  body: "Action=GetCallerIdentity&Version=2011-06-15"
)
signature.headers["authorization"]
# => "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/sts/aws4_request, ..."
```

## What was rewritten, and why

`git diff` against the commit "Add the aws-sigv4 gem 1.12.1 lib/ verbatim"
shows every change. There are two:

| Where | The gem | Here | Why | Remove when |
|---|---|---|---|---|
| `aws-sigv4.rb` | `VERSION = File.read(...VERSION...)` | `VERSION = '1.12.1'` | a compiled binary does not carry the VERSION file | never; keep in step with `UPSTREAM` |
| `signer.rb`, `presign_url` | `Time.strptime(datetime, ...)` | `Time.utc(...)` from the datetime's fields | Spinel has no `Time.strptime`, by decision (matz/spinel#1117) | likely never |

## Known gaps

- **SigV4a** (`signing_algorithm: :sigv4a`) raises `NameError` under Spinel:
  its openssl package has no `OpenSSL::ASN1`, and the compiler prints a
  warning about it on every build. Plain SigV4, the default, is complete.
- **`sign_event`** takes `Time.now`, so its test checks the shape of the
  headers and that `:chunk-signature` carries the returned signature,
  not the signature itself.

## Tests

```sh
LIBRARY_PATH=$(brew --prefix openssl@3)/lib spin test   # each test compiled by Spinel against its .expected
sh oracle/run.sh                                        # the real gem and this package under CRuby 4.0.2
sh oracle/run.sh --write                                # regenerate .expected from the real gem
```

`LIBRARY_PATH` lets the link find Homebrew's OpenSSL (matz/spinel#7191).
The oracle needs [mise](https://mise.jdx.dev) with Ruby 4.0.2 and the gem
installed once: `cd oracle && BUNDLE_GEMFILE=$PWD/Gemfile mise exec ruby@4.0.2 -- bundle install`.
It takes this package's include paths from `spin flags`; set `SPIN` to the
spin binary if the one on `PATH` is not current, and `RUBY` to run it with
another ruby.

Every `.expected` is the real gem's output. The suite in `test/fixtures/suite`
is the official AWS Signature Version 4 test suite, as aws-sdk-ruby ships it
(see `UPSTREAM` and the suite's own `LICENSE` and `NOTICE`); the 22 cases
aws-sdk-ruby's suite_spec runs all match AWS's expected canonical request, string to sign and
authorization header. Tested with Spinel `89100bf0f`.

`.github/workflows/test.yml` runs both on Linux and macOS on every push
against that Spinel revision. `.github/workflows/spinel-master.yml` runs the
same tests against Spinel master on the 1st and 15th of each month and keeps
one issue labeled `spinel-master` open while master does not pass.

Version 0.1.1 dropped the `Digest.hexencode` rewrite (matz/spinel#7243 and
#7244 are merged), so it needs a Spinel from `5c78f07e5` (2026-10-07) or
later.

Version 0.1.2 dropped the HMAC rewrite (matz/spinel#9133 is merged), so it
needs a Spinel from `30f7d7e4d` (2026-10-15) or later.

Version 0.1.3 dropped the `sha256_hexdigest` rewrite (matz/spinel#9910 is
merged), so it needs a Spinel from `42119419c` (2026-10-22) or later.

Version 0.1.4 dropped the `each.with_index.sort` rewrite (matz/spinel#9937 is
merged), so it needs a Spinel from `89100bf0f` (2026-10-22) or later.

## License

Apache-2.0, as the gem. See `LICENSE` and `NOTICE`.
