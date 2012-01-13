# encoding: utf-8
require 'simplecov'
SimpleCov.start { add_filter "setup.rb" } # nie nalezy do testow, tylko konfiguracji
require './app'
require './setup'
require 'test/unit'
require 'rack/test'

# nadpisz do testów
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ":memory:")
setup_db

class AppTest < Test::Unit::TestCase
    include Rack::Test::Methods

    def app
        Sinatra::Application
    end

    def setup
        set :show_exceptions, false
        @yehuda = User.create! imie: 'yehuda', nazwisko: 'katz', hobby: 'ruby'
        @matz = User.create! imie: 'yukihiro', nazwisko: 'matsumoto', hobby: 'ruby'
        Authdata.create! uuid: 'admin', secret_token: '1234'
        Authdata.create! uuid: 'wiceadmin', secret_token: '1111'
        @auth = 'uuid=admin&secret_token=1234'
        @www_auth = ["admin:1234"].pack('m0')
        @bad_www_auth = ["admin:9999"].pack('m0')
    end

    def teardown
        User.destroy_all
        Authdata.destroy_all
    end


    def assert_valid_json
        assert_nothing_raised do
            @data = JSON.load last_response.body
        end
    end

    def json_request method, url, data
        request url, input: data.to_json, method: method
    end

    def test_index
        get '/users'
        assert_valid_json
        assert @data.is_a?(Array)
        assert_equal 2, @data.size
        assert_equal %w(yehuda yukihiro), @data.map { |row| row['user']['imie'] }.sort
    end

    def test_show_existing
        get "/users/#{@yehuda.imie}/#{@yehuda.nazwisko}"
        assert last_response.ok?
        assert_valid_json
        assert @data.is_a?(Hash)
        assert_equal %w(hobby imie nazwisko), @data['user'].keys.sort, 'Nieprawidłowe klucze w wyniku show'
        assert_equal @yehuda.imie, @data['user']['imie']
        assert_equal @yehuda.nazwisko, @data['user']['nazwisko']
    end

    def test_show_absent
        assert_raises(ActiveRecord::RecordNotFound) do
            User.find('david', 'heineman')
        end
        get '/users/david/heineman'
        assert last_response.not_found?
    end

    def test_create_urlencoded
        count = User.all.count
        assert_raises(ActiveRecord::RecordNotFound) do
            User.find('david', 'heineman')
        end

        path = '/users'
        data = 'user[imie]=david&user[nazwisko]=heineman&user[hobby]=rails'
        post "#{path}?#{@auth}", data

        assert_equal 201, last_response.status
        assert_equal count + 1, User.all.count
        assert_nothing_raised do
            @u = User.find('david', 'heineman')
        end
        get path
        assert last_response.ok?

        count = User.all.count
        post "#{path}?#{@auth}", data
        assert_equal 400, last_response.status
        assert_equal count, User.all.count
    end

    def test_create_json
        count = User.all.count
        assert_raises(ActiveRecord::RecordNotFound) do
            User.find('david', 'heineman')
        end

        path = '/users'
        header "Content-Type", "application/json"
        params = {user: {imie: 'david', nazwisko: 'heineman', hobby: 'rails'}}
        json_request 'POST', "/users?#{@auth}", params

        assert_equal 201, last_response.status
        assert_equal count + 1, User.all.count
        assert_nothing_raised do
            User.find('david', 'heineman')
        end
        get path
        assert last_response.ok?

        # a teraz sprobujemy duplikat
        count = User.all.count
        json_request 'POST', "/users?#{@auth}", params
        assert_equal 400, last_response.status
        assert_equal count, User.all.count
    end

    def test_update_urlencoded
        count = User.all.count
        path = "/users/yehuda/katz?#{@auth}"

        put path, 'user[hobby]=beer'
        assert last_response.ok?
        assert_nothing_raised do
            @y = User.find('yehuda', 'katz')
        end
        assert_equal 'beer', @y.hobby
        assert_equal count, User.all.count

        put path, 'user[imie]=&user[nazwisko]='
        assert_equal 400, last_response.status
        assert_nothing_raised do
            @y = User.find('yehuda', 'katz')
        end

        put path, 'user[hobby]=donuts&user[imie]=wy&user[nazwisko]=cats'
        assert last_response.ok?
        assert_equal count, User.all.count
        assert_nothing_raised do
            @y = User.find('wy', 'cats')
        end
        assert_equal 'donuts', @y.hobby

        path = "/users/niema/takiego?#{@auth}"
        put path, 'user[hobby]=beer'
        assert_equal 404, last_response.status
    end

    def test_update_json
        count = User.all.count
        path = "/users/yehuda/katz?#{@auth}"
        header "Content-Type", "application/json"
        
        json_request 'PUT', path, {:user => {:hobby => 'beer'}}
        # niekompletne parametry, ale akceptowalne
        assert last_response.ok?
        assert_nothing_raised do
            @y = User.find('yehuda', 'katz')
        end
        assert_equal 'beer', @y.hobby
        assert_equal count, User.all.count

        json_request "PUT", path, {:user => {:imie => '', :nazwisko => ''}}
        assert_equal 400, last_response.status
        assert_nothing_raised do
            @y = User.find('yehuda', 'katz')
        end

        data = {:user => {:imie => 'wy', :nazwisko => 'cats', :hobby => 'donuts'}}
        json_request 'PUT', path, data
        assert last_response.ok?
        assert_equal count, User.all.count
        assert_nothing_raised do
            @t = User.find('wy', 'cats')
        end
        assert_equal 'donuts', @t.hobby

        path = "/users/niema/takiego?#{@auth}"
        json_request "PUT", path, data
        assert_equal 404, last_response.status
    end

    def test_auth
        # tu można GET bez parametrów auth
        get '/users'
        assert last_response.ok?

        path = "/users/yehuda/katz"
        get path
        assert last_response.ok?

        # pozostałe już forbidden
        post '/users'
        assert last_response.forbidden?

        put path, 'hobby=hacking'
        assert last_response.forbidden?

        delete path
        assert last_response.forbidden?

        authpath = "#{path}?uuid=wiceadmin&secret_token=2222"
        delete authpath
        assert last_response.forbidden?
    end

    def test_delete_httpauth
        path = "/users/yehuda/katz"
        header "Authorization", "Basic #{@www_auth}"
        count = User.all.count
        delete path
        assert last_response.ok?
        assert_equal count - 1, User.all.count
        assert_raises(ActiveRecord::RecordNotFound) do
            User.find('yehuda', 'katz')
        end
    end

    def test_delete_bad_httpauth
        path = "/users/yehuda/katz"
        header "Authorization", "Basic #{@bad_www_auth}"
        count = User.all.count
        delete path
        assert last_response.forbidden?
        assert_equal count, User.all.count
        assert_nothing_raised do
            User.find('yehuda', 'katz')
        end
    end

    def test_delete
        path = "/users/yehuda/katz?#{@auth}"
        count = User.all.count
        delete path
        assert last_response.ok?
        assert_equal count - 1, User.all.count
        assert_raises(ActiveRecord::RecordNotFound) do
            User.find('yehuda', 'katz')
        end

        # a teraz jeszcze raz jak już go skasowaliśmy
        count = User.all.count
        delete path
        assert last_response.not_found?
        assert_equal count, User.all.count
    end
end
