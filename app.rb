#! /usr/bin/env ruby
#
require 'rubygems'
require 'bundler'

Bundler.setup(:default)

require 'sinatra'
require './db'

set :auth do |required|
    condition do
        if required
            if params["uuid"] && params["secret_token"]
                auth = Authdata.where(:uuid => params["uuid"], :secret_token => params["secret_token"]).first
                halt 403 if auth.nil?
            else
                halt 403
            end
        end
    end
end

before do
    content_type :json
    if request.media_type == 'application/json'
        data = JSON.load request.body
        data.each { |key, val| request[key] = val } unless data.nil?
    end
end


get '/users' do
    User.all.to_json(:only => [:imie, :nazwisko, :hobby])
end

get %r{/users/([^\/]+)/([^\/]+)} do |imie, nazwisko|
    u = User.where(:imie => imie, :nazwisko => nazwisko).first
    if u.nil?
        404
    else
        u.to_json(:only => [:imie, :nazwisko, :hobby])
    end
end

post %r{/users/([^\/]+)/([^\/]+)}, :auth => true do |imie, nazwisko| 
    u = User.create(:imie => imie, :nazwisko => nazwisko, :hobby => request.params['hobby'], :created_at => Time.now, :updated_at => Time.now)
    if u.save
        [201, {}, 'Created']
    else
        [400, u.errors.full_messages.to_json]
    end
end

put %r{/users/([^\/]+)/([^\/]+)}, :auth => true do |imie, nazwisko| 
    u = User.where(:imie => imie, :nazwisko => nazwisko).first
    if u.nil?
        404
    else
        u.update_attributes :imie => request.params['imie'], :nazwisko => request.params['nazwisko'], :hobby => request.params['hobby'], :updated_at => Time.now
        if u.save
            [200, 'Updated']
        else
            [400, u.errors.full_messages.to_json]
        end
    end
end

delete %r{/users/([^\/]+)/([^\/]+)}, :auth => true do |imie, nazwisko| 
    u = User.where(:imie => imie, :nazwisko => nazwisko).first
    if u.nil?
        404
    else
        u.destroy
        [200, 'Deleted']
    end
end
