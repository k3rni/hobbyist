#! /usr/bin/env ruby


require 'rubygems'
require 'bundler'

Bundler.setup(:default)

require './db'

ActiveRecord::Base.connection.execute "CREATE TABLE authdata (uuid TEXT, secret_token TEXT)"
ActiveRecord::Base.connection.execute "CREATE TABLE users (imie TEXT, nazwisko TEXT, hobby TEXT, created_at TIMESTAMP, updated_at TIMESTAMP)"
