require 'rubygems'
require 'active_record'
require 'composite_primary_keys'

ActiveRecord::Base.establish_connection(
    :adapter => 'sqlite3', 
    :database => 'app.sqlite3'
)

class User < ActiveRecord::Base
    set_primary_keys :imie, :nazwisko
    validates_presence_of :imie, :nazwisko, :hobby
    validates_uniqueness_of :imie, :nazwisko
end

class Authdata < ActiveRecord::Base
    set_primary_keys :uuid, :secret_token
end
