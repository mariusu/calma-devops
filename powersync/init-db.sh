#!/bin/bash
set -e

# Kjøre SQL-kommandoer med miljøvariabler injisert fra bash
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- 1. Opprett databaseroller for PostgREST
    CREATE ROLE anon NOLOGIN;
    CREATE ROLE authenticated NOLOGIN;

    -- Bruker passordet fra .env for PostgREST-autentiseringen
    CREATE ROLE authenticator WITH LOGIN PASSWORD '$PGRST_AUTHENTICATOR_PASSWORD';
    GRANT anon TO authenticator;
    GRANT authenticated TO authenticator;

    -- 2. Opprett API-skjemaet
    CREATE SCHEMA api;

    CREATE TABLE api.todos (
        id SERIAL PRIMARY KEY,
        task TEXT NOT NULL,
        user_id TEXT NOT NULL
    );

    GRANT USAGE ON SCHEMA api TO anon, authenticated;
    GRANT ALL ON api.todos TO authenticated;
    GRANT SELECT ON api.todos TO anon;

    ALTER TABLE api.todos ENABLE ROW LEVEL SECURITY;

    CREATE POLICY todos_policy ON api.todos
        FOR ALL
        TO authenticated
        USING (user_id = (current_setting('request.jwt.claims', true)::json->>'sub'))
        WITH CHECK (user_id = (current_setting('request.jwt.claims', true)::json->>'sub'));

    -- 3. Pre-request-funksjon for Firebase Auth-validering (Injisert med prosjekt-ID)
    CREATE OR REPLACE FUNCTION api.check_firebase_auth() RETURNS void AS \$\$
    DECLARE
        claims json;
        firebase_project_id text := '$FIREBASE_PROJECT_ID';
    BEGIN
        IF current_setting('request.jwt.claims', true) IS NOT NULL AND current_setting('request.jwt.claims', true) != '' THEN
            claims := current_setting('request.jwt.claims', true)::json;
            
            IF claims->>'aud' = firebase_project_id THEN
                PERFORM set_config('role', 'authenticated', true);
            END IF;
        END IF;
    END;
    \$\$ LANGUAGE plpgsql SECURITY DEFINER;

    -- 4. Opprett publikasjon for PowerSync
    CREATE PUBLICATION powersync FOR ALL TABLES;
EOSQL