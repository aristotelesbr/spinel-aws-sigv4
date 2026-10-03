# frozen_string_literal: true

require_relative 'aws-sigv4/asymmetric_credentials'
require_relative 'aws-sigv4/credentials'
require_relative 'aws-sigv4/errors'
require_relative 'aws-sigv4/signature'
require_relative 'aws-sigv4/signer'

module Aws
  module Sigv4
    # spinel-aws-sigv4: the gem reads its VERSION file at load time, and a
    # compiled binary does not carry it. Keep in step with UPSTREAM.
    VERSION = '1.12.1'
  end
end