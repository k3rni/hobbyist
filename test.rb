require './app'
require 'test/unit'
require 'rack/test'

class AppTest < Test::Unit::TestCase
    include Rack::Test::Methods

    def app
        Sinatra::Application
    end

    def setup
        u = User.where(:imie => 'jozef', :nazwisko => 'oleksy').first
        u.destroy if u
        @yehuda = User.create(:imie => 'yehuda', :nazwisko => 'katz', :hobby => 'ruby')
    end

    def teardown
        @yehuda.destroy
    end


    def assert_valid_json
        assert_nothing_raised do
            @data = JSON.load last_response.body
        end
    end

    def json_request method, url, data
        request url, :input => data.to_json, :method => method
    end

    def test_index
        get '/users'
        assert_valid_json
        assert @data.is_a?(Array), "Index didn't return an array"
    end

    def test_create_urlencoded
        count = User.all.count
        post '/users/jozef/oleksy?uuid=admin&secret_token=1234', 'hobby=politykowanie'
        assert_equal 201, last_response.status
        assert_equal count + 1, User.all.count, "User wasn't created"
    end

    def test_create_json
        count = User.all.count
        header "Content-Type", "application/json"
        json_request 'POST', '/users/jozef/oleksy?uuid=admin&secret_token=1234', {hobby: 'politykowanie'}
        assert_equal 201, last_response.status
        assert_equal count + 1, User.all.count, "User wasn't created"
    end

    def test_update_urlencoded
    end

    def test_update_json
    end

    def test_auth
        # bez auth na wszystko poza getami powinnismy dostac 403
        get '/users'
        assert last_response.ok?

        url = "/users/#{@yehuda.imie}/#{@yehuda.nazwisko}"
        get url
        assert last_response.ok?

        put url, 'hobby=hacking'
        assert last_response.forbidden?

        post url
        assert last_response.forbidden?

        delete url
        assert last_response.forbidden?
    end

    def test_delete
    end
end
