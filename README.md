Wymagania
=========

Baza danych składa się z dwóch tabel. W jednej z nich są użytkownicy z polami
imię, nazwisko, hobby, datą utworzenia rekordu i modyfikacji. Druga tabela
zawiera pola: *uuid* oraz *secret_token*. Należy napisać aplikację, która będzie
obsługiwać standardowe RESTowe API, posiadające zasób users i odpowiadające w
formacie json.  Przy czym metoda GET powinna pokazywać tylko imię, nazwisko i
hobby uzytkownika (bez daty utworzenia i modyfikacji), oraz być jedyną metoda
ogólnie dostępną (bez uwierzytelniania). Pozostałe metody wymagają podania
dodatkowych parametrów: uuid i pasującego secret_token.

Uruchamianie
------------

Pobranie i instalacja gemów (wymagany bundler):

    $ git clone git://github.com/k3rni/hobbyist
    $ cd hobbyist
    $ bundle install

Uruchamianie testów:

    $ ruby test.rb 

Wygenerowanie bazy danych (przed uruchomieniem aplikacji):

    $ ruby setup.rb

Uruchomienie:

    $ ruby app.rb

Jeśli ruby nie potrafi znaleźć gemów, zastępujemy go w poleceniach przez `bundle exec ruby`.

O implementacji
---------------

Trzymając się specyfikacji słowo w słowo, zakładam nietypowo, że kluczem
głównym tabeli users jest para (imię, nazwisko), i tak projektuję model oraz
ścieżki (również tabelę autoryzacji). Wymaga to również użycia gema
*composite_primary_keys*.

Ścieżki odpowiadają modelowi REST:

    index     GET /users
    show      GET /users/imie/nazwisko
    create  * POST /users
    update  * PUT /users/imie/nazwisko
    destroy * DELETE /users/imie/nazwisko

Zapytania oznaczone gwiazdką wymagają autoryzacji.

Wszystkie zapytania, jeśli dają cokolwiek w odpowiedzi (udane operacje create i destroy
zwracają pustą odpowiedź z odpowiednim kodem), zwracają to w formacie JSON - nawet listę
błędów w przypadku create i update. Próby operacji na nieistniejącym użytkowniku kończą się
statusem 404, dotyczy to operacji show, update, destroy.

Dodatkowo, metody create i update potrafią przyjmować dane w formacie JSON,
odpowiednio deserializując je z treści zapytania. Musi ono wówczas zawierać
nagłówek `Content-Type: application/json`.

Autoryzacja jest zbudowana w najprostszy możliwy sposób, bez użycia dodatkowych bibliotek.
Korzystając z możliwości sinatry, dodaję to jako warunek, który mogę potem zastosować
jako część definicji routa. Takie rozwiązanie wybrałem ze względu na brak potrzeby
zarządzania autoryzacją oraz brak persystentnych sesji. W innym przypadku warto byłoby
zastosować gotowe rozwiązanie, jak np. Warden.

Autoryzacja może nastąpić na dwa sposoby: według specyfikacji - przez podanie w
GET parametrów uuid i secret_token, oraz poprzez podanie ich w autoryzacji
HTTP Basic - nagłówku Authorization.

Kod zawiera testy funkcjonalne (samych metod REST) oraz integracyjne (testujące autoryzację).
Pokrycie testami wynosi 100%, zmierzone przez simplecov.
