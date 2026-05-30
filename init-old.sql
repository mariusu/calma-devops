-- 1. Opprett databaseroller for PostgREST
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;

-- Rollen PostgREST bruker for å koble seg til databasen
CREATE ROLE authenticator WITH LOGIN PASSWORD 'your_authenticator_password';
GRANT anon TO authenticator;
GRANT authenticated TO authenticator;

-- 2. Opprett API-skjemaet (det som eksponeres som REST-endepunkter)
CREATE SCHEMA api;

-- Eksempeltabell for å teste oppsettet
CREATE TABLE api.todos (
    id SERIAL PRIMARY KEY,
    task TEXT NOT NULL,
    user_id TEXT NOT NULL -- Her lagres Firebase UID (sub)
);

-- Gi tilganger til skjema og tabeller
GRANT USAGE ON SCHEMA api TO anon, authenticated;
GRANT ALL ON api.todos TO authenticated;
GRANT SELECT ON api.todos TO anon;

-- Aktiver Row Level Security (RLS) slik at brukere kun ser egne data
ALTER TABLE api.todos ENABLE ROW LEVEL SECURITY;

CREATE POLICY todos_policy ON api.todos
    FOR ALL
    TO authenticated
    USING (user_id = (current_setting('request.jwt.claims', true)::json->>'sub'))
    WITH CHECK (user_id = (current_setting('request.jwt.claims', true)::json->>'sub'));

-- 3. Pre-request-funksjon for Firebase Auth-validering
-- Siden Firebase ikke sender med "role", vil PostgREST som standard behandle brukeren som 'anon'.
-- Denne funksjonen sjekker om "aud" matcher din Firebase Prosjekt-ID og oppgraderer til 'authenticated'.
CREATE OR REPLACE FUNCTION api.check_firebase_auth() RETURNS void AS $$
DECLARE
    claims json;
    firebase_project_id text := 'DIN_FIREBASE_PROSJEKT_ID'; -- Erstatt med din faktiske Firebase Project ID
BEGIN
    IF current_setting('request.jwt.claims', true) IS NOT NULL AND current_setting('request.jwt.claims', true) != '' THEN
        claims := current_setting('request.jwt.claims', true)::json;
        
        IF claims->>'aud' = firebase_project_id THEN
            -- Endre rollen lokalt for denne spesifikke HTTP-forespørselen
            PERFORM set_config('role', 'authenticated', true);
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Opprett publikasjon for PowerSync (kreves for logisk replikering)
CREATE PUBLICATION powersync FOR ALL TABLES;