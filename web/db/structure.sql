SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: geocoding_caches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.geocoding_caches (
    id bigint NOT NULL,
    location_query character varying NOT NULL,
    provider character varying DEFAULT 'google'::character varying NOT NULL,
    raw_response jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    geom public.geography(Point,4326) NOT NULL
);


--
-- Name: geocoding_caches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.geocoding_caches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: geocoding_caches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.geocoding_caches_id_seq OWNED BY public.geocoding_caches.id;


--
-- Name: listings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listings (
    id bigint NOT NULL,
    sport character varying NOT NULL,
    title character varying NOT NULL,
    body text,
    location_name character varying NOT NULL,
    start_at timestamp(6) without time zone NOT NULL,
    end_at timestamp(6) without time zone NOT NULL,
    slots_needed integer NOT NULL,
    skill_level_min character varying NOT NULL,
    skill_level_max character varying NOT NULL,
    price_estimate integer,
    contact_info character varying NOT NULL,
    source character varying NOT NULL,
    source_url character varying,
    schema_version integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    geom public.geography(Point,4326),
    user_id bigint,
    CONSTRAINT listings_skill_level_max_valid CHECK (((skill_level_max)::text = ANY ((ARRAY['yeu'::character varying, 'trung_binh_yeu'::character varying, 'trung_binh_minus'::character varying, 'trung_binh'::character varying, 'trung_binh_plus'::character varying, 'trung_binh_plus_plus'::character varying, 'trung_binh_kha'::character varying, 'kha'::character varying, 'ban_chuyen'::character varying, 'chuyen_nghiep'::character varying])::text[]))),
    CONSTRAINT listings_skill_level_min_valid CHECK (((skill_level_min)::text = ANY ((ARRAY['yeu'::character varying, 'trung_binh_yeu'::character varying, 'trung_binh_minus'::character varying, 'trung_binh'::character varying, 'trung_binh_plus'::character varying, 'trung_binh_plus_plus'::character varying, 'trung_binh_kha'::character varying, 'kha'::character varying, 'ban_chuyen'::character varying, 'chuyen_nghiep'::character varying])::text[]))),
    CONSTRAINT listings_skill_level_range_valid CHECK ((array_position(ARRAY['yeu'::text, 'trung_binh_yeu'::text, 'trung_binh_minus'::text, 'trung_binh'::text, 'trung_binh_plus'::text, 'trung_binh_plus_plus'::text, 'trung_binh_kha'::text, 'kha'::text, 'ban_chuyen'::text, 'chuyen_nghiep'::text], (skill_level_min)::text) <= array_position(ARRAY['yeu'::text, 'trung_binh_yeu'::text, 'trung_binh_minus'::text, 'trung_binh'::text, 'trung_binh_plus'::text, 'trung_binh_plus_plus'::text, 'trung_binh_kha'::text, 'kha'::text, 'ban_chuyen'::text, 'chuyen_nghiep'::text], (skill_level_max)::text))),
    CONSTRAINT listings_slots_needed_positive CHECK ((slots_needed >= 1)),
    CONSTRAINT listings_sport_valid CHECK (((sport)::text = ANY ((ARRAY['badminton'::character varying, 'pickleball'::character varying])::text[]))),
    CONSTRAINT listings_time_range_valid CHECK ((end_at >= start_at))
);


--
-- Name: listings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.listings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.listings_id_seq OWNED BY public.listings.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    ip_address character varying,
    user_agent character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email_address character varying NOT NULL,
    password_digest character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: geocoding_caches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geocoding_caches ALTER COLUMN id SET DEFAULT nextval('public.geocoding_caches_id_seq'::regclass);


--
-- Name: listings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings ALTER COLUMN id SET DEFAULT nextval('public.listings_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: geocoding_caches geocoding_caches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geocoding_caches
    ADD CONSTRAINT geocoding_caches_pkey PRIMARY KEY (id);


--
-- Name: listings listings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings
    ADD CONSTRAINT listings_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_geocoding_caches_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_geocoding_caches_on_geom ON public.geocoding_caches USING gist (geom);


--
-- Name: index_geocoding_caches_on_location_query; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_geocoding_caches_on_location_query ON public.geocoding_caches USING btree (location_query);


--
-- Name: index_listings_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_geom ON public.listings USING gist (geom);


--
-- Name: index_listings_on_source_url_nonnull; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_listings_on_source_url_nonnull ON public.listings USING btree (source_url) WHERE (source_url IS NOT NULL);


--
-- Name: index_listings_on_sport_and_start_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_sport_and_start_at ON public.listings USING btree (sport, start_at);


--
-- Name: index_listings_on_start_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_start_at ON public.listings USING btree (start_at);


--
-- Name: index_listings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_user_id ON public.listings USING btree (user_id);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: listings fk_rails_baa008bfd2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings
    ADD CONSTRAINT fk_rails_baa008bfd2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260403110000'),
('20260403040003'),
('20260403040002'),
('20260403040001'),
('20260403034734'),
('20260403034733');

