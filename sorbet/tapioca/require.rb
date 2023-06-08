# typed: true
# frozen_string_literal: true

require "cgi"
require "dry/cli"
require "graphql/client"
require "graphql/client/http"
require "httparty"
require "json"
require "parallel"
require "ruby-progressbar"
require "tty-box"
require "tty-markdown"
require "tty-pager"
require "tty-spinner"
require "zeitwerk"
