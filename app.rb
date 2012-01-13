#! /usr/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'bundler'

Bundler.setup(:default)

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'rack/auth/basic'
require './db'

# Nie ma potrzeby wyciągania większych rozwiązań typu Warden. Ponieważ nie potrzebujemy
# ciasteczek, na nic nam jego obsługa sesji. Roll-your-own, zbudujemy sobie jako condition
# do doczepienia w routach.
set :auth do |required|
    condition do
        return unless required
        if params["uuid"] && params["secret_token"]
            auth = Authdata.where(:uuid => params["uuid"], 
                                  :secret_token => params["secret_token"]).first
            halt 403 unless auth
        else
            httpauth = Rack::Auth::Basic::Request.new(env)
            halt 403 unless (httpauth.provided? && 
                             httpauth.basic? && 
                             Authdata.where('uuid = ? AND secret_token = ?', 
                                               *httpauth.credentials).first)
        end
    end
end

# Zawsze produkujemy JSON, chcemy też przyjmować requesty modyfikujące w tym formacie
# (a nie tylko x-wwwform-urlencoded).
before do
    # media-type pominie charset przy sprawdzaniu
    if request.media_type == 'application/json'
        data = JSON.load request.body
        # wpisujemy w request[], potem się pojawia w request.params.
        data.each { |key, val| request[key] = val } unless data.nil?
    end
end

# uwaga: w środowisku development nie działa, sinatra instaluje swój, 
# wyświetlający tracebacka
error ::ActiveRecord::RecordNotFound do
    404
end


# pomocnik do jsona, ucina pola według specyfikacji
class RestrictedEncoder
    class << self
        def encode object
            if object.is_a? Array
                # wiadomo że userów - tylko takie podajemy tu
                object.map { |user| user.as_json :only => [:imie, :nazwisko, :hobby] }.to_json
            elsif object.is_a? User
                object.to_json :only => [:imie, :nazwisko, :hobby]
            end
        end
    end
end
            


# index - Pobierz listę użytkowników, bez autoryzacji (GET, więc spełnia wymagania)
get '/users' do
    json(User.all, :encoder => RestrictedEncoder)
end

# create
post '/users', :auth => true do 
    data = request.params['user']
    u = User.create(data)
    if u.save
        [201, {}, 'Created']
    else
        [400, json(u.errors.full_messages)]
    end
end


# Dlaczego taka ścieżka, a nie z id?
# Założyłem sobie, trochę nietypowo, że kluczem głównym w tabeli users jest para
# imię+nazwisko (stąd też gem composite_primary_keys).

USER_PATH = '/users/:imie/:nazwisko'

# show - pobierz pojedynczego użytkownika, również bez autoryzacji.
get USER_PATH do
    u = User.find(params[:imie], params[:nazwisko])
    json u, :encoder => RestrictedEncoder
end


# update
put USER_PATH, :auth => true do 
    u = User.find(params[:imie], params[:nazwisko])
    data = request.params['user']
    u.update_attributes data
    if u.save
        [200, 'Updated']
    else
        [400, json(u.errors.full_messages)]
    end
end

# dstroy
delete USER_PATH, :auth => true do 
    u = User.find(params[:imie], params[:nazwisko])
    u.destroy
    [200, 'Deleted']
end

