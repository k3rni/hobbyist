#! /usr/bin/env ruby


require 'rubygems'
require 'bundler'

Bundler.setup(:default)

require './db'

def setup_db
    ActiveRecord::Base.connection.execute "CREATE TABLE authdata (uuid TEXT PRIMARY KEY, secret_token TEXT)"
    ActiveRecord::Base.connection.execute "CREATE TABLE users (imie TEXT, nazwisko TEXT, hobby TEXT, created_at TIMESTAMP, updated_at TIMESTAMP)"
end

if $0 == __FILE__
    setup_db
end
