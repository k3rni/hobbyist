#! /usr/bin/env ruby


require 'rubygems'
require 'bundler'

Bundler.setup(:default)

require './db'

def setup_db add_auth=false
    ActiveRecord::Base.connection.execute "CREATE TABLE authdata (uuid TEXT PRIMARY KEY, secret_token TEXT)"
    ActiveRecord::Base.connection.execute "CREATE TABLE users (imie TEXT, nazwisko TEXT, hobby TEXT, created_at TIMESTAMP, updated_at TIMESTAMP)"
    if add_auth
        Authdata.create! uuid: 'admin', secret_token: '1234'
    end
end

if $0 == __FILE__
    setup_db(true)
end
