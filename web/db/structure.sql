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
-- Name: tiger; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tiger;


--
-- Name: tiger_data; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tiger_data;


--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA topology;


--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: postgis_tiger_geocoder; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder WITH SCHEMA tiger;


--
-- Name: EXTENSION postgis_tiger_geocoder; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_tiger_geocoder IS 'PostGIS tiger geocoder and reverse geocoder';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_sessions (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    ip_address character varying,
    user_agent character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: admin_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_sessions_id_seq OWNED BY public.admin_sessions.id;


--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_users (
    id bigint NOT NULL,
    email_address character varying NOT NULL,
    password_digest character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


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
-- Name: bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookmarks (
    id bigint NOT NULL,
    listing_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: bookmarks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bookmarks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookmarks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bookmarks_id_seq OWNED BY public.bookmarks.id;


--
-- Name: chat_rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_rooms (
    id bigint NOT NULL,
    listing_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: chat_rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_rooms_id_seq OWNED BY public.chat_rooms.id;


--
-- Name: court_pass_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.court_pass_details (
    id bigint NOT NULL,
    listing_id bigint NOT NULL,
    court_name character varying NOT NULL,
    original_price integer NOT NULL,
    pass_price integer NOT NULL,
    booking_proof character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: court_pass_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.court_pass_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: court_pass_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.court_pass_details_id_seq OWNED BY public.court_pass_details.id;


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
    price_estimate integer,
    contact_info character varying NOT NULL,
    source character varying NOT NULL,
    source_url character varying,
    schema_version integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    geom public.geography(Point,4326),
    user_id bigint,
    skill_level_min character varying NOT NULL,
    skill_level_max character varying NOT NULL,
    listing_type character varying DEFAULT 'match_finding'::character varying NOT NULL,
    gender_requirement character varying,
    play_format character varying,
    active boolean DEFAULT true NOT NULL,
    skill_level_min_pk character varying,
    skill_level_max_pk character varying,
    rain_probability integer,
    weather_checked_at timestamp with time zone,
    CONSTRAINT listings_rain_probability_range CHECK (((rain_probability IS NULL) OR ((rain_probability >= 0) AND (rain_probability <= 100)))),
    CONSTRAINT listings_skill_level_max_pk_valid CHECK (((skill_level_max_pk IS NULL) OR ((skill_level_max_pk)::text = ANY (ARRAY['dupr_2_0'::text, 'dupr_2_5'::text, 'dupr_3_0'::text, 'dupr_3_5'::text, 'dupr_4_0'::text, 'dupr_4_5'::text, 'dupr_5_0'::text])))),
    CONSTRAINT listings_skill_level_max_valid CHECK (((skill_level_max)::text = ANY (ARRAY[('yeu'::character varying)::text, ('trung_binh_yeu'::character varying)::text, ('trung_binh_minus'::character varying)::text, ('trung_binh'::character varying)::text, ('trung_binh_plus'::character varying)::text, ('trung_binh_plus_plus'::character varying)::text, ('trung_binh_kha'::character varying)::text, ('kha'::character varying)::text, ('ban_chuyen'::character varying)::text, ('chuyen_nghiep'::character varying)::text]))),
    CONSTRAINT listings_skill_level_min_pk_valid CHECK (((skill_level_min_pk IS NULL) OR ((skill_level_min_pk)::text = ANY (ARRAY['dupr_2_0'::text, 'dupr_2_5'::text, 'dupr_3_0'::text, 'dupr_3_5'::text, 'dupr_4_0'::text, 'dupr_4_5'::text, 'dupr_5_0'::text])))),
    CONSTRAINT listings_skill_level_min_valid CHECK (((skill_level_min)::text = ANY (ARRAY[('yeu'::character varying)::text, ('trung_binh_yeu'::character varying)::text, ('trung_binh_minus'::character varying)::text, ('trung_binh'::character varying)::text, ('trung_binh_plus'::character varying)::text, ('trung_binh_plus_plus'::character varying)::text, ('trung_binh_kha'::character varying)::text, ('kha'::character varying)::text, ('ban_chuyen'::character varying)::text, ('chuyen_nghiep'::character varying)::text]))),
    CONSTRAINT listings_skill_level_pk_range_valid CHECK (((skill_level_min_pk IS NULL) OR (skill_level_max_pk IS NULL) OR (array_position(ARRAY['dupr_2_0'::text, 'dupr_2_5'::text, 'dupr_3_0'::text, 'dupr_3_5'::text, 'dupr_4_0'::text, 'dupr_4_5'::text, 'dupr_5_0'::text], (skill_level_min_pk)::text) <= array_position(ARRAY['dupr_2_0'::text, 'dupr_2_5'::text, 'dupr_3_0'::text, 'dupr_3_5'::text, 'dupr_4_0'::text, 'dupr_4_5'::text, 'dupr_5_0'::text], (skill_level_max_pk)::text)))),
    CONSTRAINT listings_skill_level_range_valid CHECK ((array_position(ARRAY['yeu'::text, 'trung_binh_yeu'::text, 'trung_binh_minus'::text, 'trung_binh'::text, 'trung_binh_plus'::text, 'trung_binh_plus_plus'::text, 'trung_binh_kha'::text, 'kha'::text, 'ban_chuyen'::text, 'chuyen_nghiep'::text], (skill_level_min)::text) <= array_position(ARRAY['yeu'::text, 'trung_binh_yeu'::text, 'trung_binh_minus'::text, 'trung_binh'::text, 'trung_binh_plus'::text, 'trung_binh_plus_plus'::text, 'trung_binh_kha'::text, 'kha'::text, 'ban_chuyen'::text, 'chuyen_nghiep'::text], (skill_level_max)::text))),
    CONSTRAINT listings_slots_needed_positive CHECK ((slots_needed >= 1)),
    CONSTRAINT listings_sport_valid CHECK (((sport)::text = ANY (ARRAY[('badminton'::character varying)::text, ('pickleball'::character varying)::text]))),
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
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    chat_room_id bigint NOT NULL,
    user_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT messages_body_max_length CHECK ((char_length(body) <= 2000)),
    CONSTRAINT messages_body_not_blank CHECK ((char_length(TRIM(BOTH FROM body)) > 0))
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: registrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.registrations (
    id bigint NOT NULL,
    listing_id bigint NOT NULL,
    user_id bigint NOT NULL,
    note text,
    phone character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: registrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.registrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: registrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.registrations_id_seq OWNED BY public.registrations.id;


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
-- Name: tournament_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournament_details (
    id bigint NOT NULL,
    listing_id bigint NOT NULL,
    tournament_name character varying NOT NULL,
    organizer character varying,
    registration_deadline timestamp(6) without time zone NOT NULL,
    format character varying NOT NULL,
    prize_info character varying,
    registration_link character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tournament_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tournament_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tournament_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tournament_details_id_seq OWNED BY public.tournament_details.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email_address character varying NOT NULL,
    password_digest character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    display_name character varying,
    phone_number character varying,
    date_of_birth date,
    gender character varying,
    address character varying,
    bio text,
    sport_badminton boolean DEFAULT false NOT NULL,
    sport_pickleball boolean DEFAULT false NOT NULL,
    skill_level_badminton character varying,
    skill_level_pickleball character varying
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
-- Name: admin_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_sessions ALTER COLUMN id SET DEFAULT nextval('public.admin_sessions_id_seq'::regclass);


--
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- Name: bookmarks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks ALTER COLUMN id SET DEFAULT nextval('public.bookmarks_id_seq'::regclass);


--
-- Name: chat_rooms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms ALTER COLUMN id SET DEFAULT nextval('public.chat_rooms_id_seq'::regclass);


--
-- Name: court_pass_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.court_pass_details ALTER COLUMN id SET DEFAULT nextval('public.court_pass_details_id_seq'::regclass);


--
-- Name: geocoding_caches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geocoding_caches ALTER COLUMN id SET DEFAULT nextval('public.geocoding_caches_id_seq'::regclass);


--
-- Name: listings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings ALTER COLUMN id SET DEFAULT nextval('public.listings_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: registrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registrations ALTER COLUMN id SET DEFAULT nextval('public.registrations_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: tournament_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_details ALTER COLUMN id SET DEFAULT nextval('public.tournament_details_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: admin_sessions admin_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT admin_sessions_pkey PRIMARY KEY (id);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (id);


--
-- Name: chat_rooms chat_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT chat_rooms_pkey PRIMARY KEY (id);


--
-- Name: court_pass_details court_pass_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.court_pass_details
    ADD CONSTRAINT court_pass_details_pkey PRIMARY KEY (id);


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
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: registrations registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registrations
    ADD CONSTRAINT registrations_pkey PRIMARY KEY (id);


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
-- Name: tournament_details tournament_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_details
    ADD CONSTRAINT tournament_details_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_listings_active_sport_start; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_listings_active_sport_start ON public.listings USING btree (sport, start_at) WHERE (active = true);


--
-- Name: idx_listings_active_type_start; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_listings_active_type_start ON public.listings USING btree (listing_type, start_at) WHERE (active = true);


--
-- Name: index_admin_sessions_on_admin_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_sessions_on_admin_user_id ON public.admin_sessions USING btree (admin_user_id);


--
-- Name: index_admin_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admin_users_on_email_address ON public.admin_users USING btree (email_address);


--
-- Name: index_bookmarks_on_listing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookmarks_on_listing_id ON public.bookmarks USING btree (listing_id);


--
-- Name: index_bookmarks_on_listing_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bookmarks_on_listing_id_and_user_id ON public.bookmarks USING btree (listing_id, user_id);


--
-- Name: index_bookmarks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookmarks_on_user_id ON public.bookmarks USING btree (user_id);


--
-- Name: index_chat_rooms_on_listing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_rooms_on_listing_id ON public.chat_rooms USING btree (listing_id);


--
-- Name: index_chat_rooms_on_listing_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_chat_rooms_on_listing_id_unique ON public.chat_rooms USING btree (listing_id);


--
-- Name: index_court_pass_details_on_listing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_court_pass_details_on_listing_id ON public.court_pass_details USING btree (listing_id);


--
-- Name: index_geocoding_caches_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_geocoding_caches_on_geom ON public.geocoding_caches USING gist (geom);


--
-- Name: index_geocoding_caches_on_location_query; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_geocoding_caches_on_location_query ON public.geocoding_caches USING btree (location_query);


--
-- Name: index_listings_on_gender_requirement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_gender_requirement ON public.listings USING btree (gender_requirement);


--
-- Name: index_listings_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_geom ON public.listings USING gist (geom);


--
-- Name: index_listings_on_play_format; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_play_format ON public.listings USING btree (play_format);


--
-- Name: index_listings_on_source_url_nonnull; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_listings_on_source_url_nonnull ON public.listings USING btree (source_url) WHERE (source_url IS NOT NULL);


--
-- Name: index_listings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_user_id ON public.listings USING btree (user_id);


--
-- Name: index_messages_on_chat_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_chat_room_id ON public.messages USING btree (chat_room_id);


--
-- Name: index_messages_on_chat_room_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_chat_room_id_and_created_at ON public.messages USING btree (chat_room_id, created_at);


--
-- Name: index_messages_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_user_id ON public.messages USING btree (user_id);


--
-- Name: index_registrations_on_listing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_registrations_on_listing_id ON public.registrations USING btree (listing_id);


--
-- Name: index_registrations_on_listing_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_registrations_on_listing_id_and_user_id ON public.registrations USING btree (listing_id, user_id);


--
-- Name: index_registrations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_registrations_on_user_id ON public.registrations USING btree (user_id);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_tournament_details_on_listing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tournament_details_on_listing_id ON public.tournament_details USING btree (listing_id);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: messages fk_rails_00aac238e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_00aac238e8 FOREIGN KEY (chat_room_id) REFERENCES public.chat_rooms(id);


--
-- Name: tournament_details fk_rails_098aa17f52; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_details
    ADD CONSTRAINT fk_rails_098aa17f52 FOREIGN KEY (listing_id) REFERENCES public.listings(id);


--
-- Name: registrations fk_rails_2447744ad8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registrations
    ADD CONSTRAINT fk_rails_2447744ad8 FOREIGN KEY (listing_id) REFERENCES public.listings(id);


--
-- Name: messages fk_rails_273a25a7a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_273a25a7a6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: registrations fk_rails_2e0658f554; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registrations
    ADD CONSTRAINT fk_rails_2e0658f554 FOREIGN KEY (user_id) REFERENCES public.users(id);


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
-- Name: bookmarks fk_rails_c06420b17c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT fk_rails_c06420b17c FOREIGN KEY (listing_id) REFERENCES public.listings(id);


--
-- Name: bookmarks fk_rails_c1ff6fa4ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT fk_rails_c1ff6fa4ac FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: court_pass_details fk_rails_dcc75b9607; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.court_pass_details
    ADD CONSTRAINT fk_rails_dcc75b9607 FOREIGN KEY (listing_id) REFERENCES public.listings(id);


--
-- Name: admin_sessions fk_rails_e5862922c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT fk_rails_e5862922c9 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- Name: chat_rooms fk_rails_eca7826014; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT fk_rails_eca7826014 FOREIGN KEY (listing_id) REFERENCES public.listings(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public, tiger, topology;

INSERT INTO "schema_migrations" (version) VALUES
('20260429000001'),
('20260427000002'),
('20260427000001'),
('20260424100606'),
('20260424000002'),
('20260424000001'),
('20260423000004'),
('20260423000003'),
('20260423000002'),
('20260423000001'),
('20260422000001'),
('20260419100001'),
('20260419000002'),
('20260419000001'),
('20260403110000'),
('20260403040003'),
('20260403040002'),
('20260403040001'),
('20260403034734'),
('20260403034733');

