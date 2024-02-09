-- *****************************************************************
-- This file is auto-generated by prepare.sh from migrations/*.sql.
-- Use it as a reference, but do not modify it directly.
-- *****************************************************************


--
-- PostgreSQL database dump
--

-- Dumped from database version 16.0 (Debian 16.0-1.pgdg120+1)
-- Dumped by pg_dump version 16.0 (Debian 16.0-1.pgdg120+1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _sqlx_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._sqlx_migrations (
    version bigint NOT NULL,
    description text NOT NULL,
    installed_on timestamp with time zone DEFAULT now() NOT NULL,
    success boolean NOT NULL,
    checksum bytea NOT NULL,
    execution_time bigint NOT NULL
);


ALTER TABLE public._sqlx_migrations OWNER TO postgres;

--
-- Name: acme_txt_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acme_txt_entries (
    cluster character varying(255) NOT NULL,
    leased_at timestamp with time zone DEFAULT now() NOT NULL,
    leased_by integer NOT NULL,
    txt_value character varying(255)
);


ALTER TABLE public.acme_txt_entries OWNER TO postgres;

--
-- Name: TABLE acme_txt_entries; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.acme_txt_entries IS 'TXT entries used for ACME DNS challenges. Doubles as a leasing mechanism to ensure that only one drone can do an ACME challenge at a time.';


--
-- Name: COLUMN acme_txt_entries.cluster; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acme_txt_entries.cluster IS 'The cluster the TXT entry is associated with.';


--
-- Name: COLUMN acme_txt_entries.leased_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acme_txt_entries.leased_at IS 'The time the TXT entry was leased.';


--
-- Name: COLUMN acme_txt_entries.leased_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acme_txt_entries.leased_by IS 'The proxy that last leased the entry.';


--
-- Name: COLUMN acme_txt_entries.txt_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acme_txt_entries.txt_value IS 'The TXT value of the entry.';


--
-- Name: backend; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backend (
    id character varying(255) NOT NULL,
    cluster character varying(255) NOT NULL,
    last_status character varying(255) NOT NULL,
    last_status_time timestamp with time zone NOT NULL,
    cluster_address character varying(255),
    drone_id integer NOT NULL,
    expiration_time timestamp with time zone,
    last_keepalive timestamp with time zone NOT NULL,
    allowed_idle_seconds integer,
    state jsonb NOT NULL,
    static_token character varying(256)
);


ALTER TABLE public.backend OWNER TO postgres;

--
-- Name: TABLE backend; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.backend IS 'Information about backends. A row is created when a backend is scheduled.';


--
-- Name: COLUMN backend.cluster; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend.cluster IS 'The cluster the backend belongs to.';


--
-- Name: COLUMN backend.last_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend.last_status IS 'The last status received from the backend.';


--
-- Name: COLUMN backend.last_status_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend.last_status_time IS 'The time the last status was received from the backend.';


--
-- Name: COLUMN backend.cluster_address; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend.cluster_address IS 'The address (IP:PORT) of the backend within the cluster.';


--
-- Name: COLUMN backend.drone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend.drone_id IS 'The drone the backend is assigned to.';


--
-- Name: COLUMN backend.expiration_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend.expiration_time IS 'A hard deadline after which the controller will initiate a graceful termination of the backend.';


--
-- Name: COLUMN backend.last_keepalive; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend.last_keepalive IS 'The last time a proxy sent a keepalive for this backend.';


--
-- Name: COLUMN backend.allowed_idle_seconds; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend.allowed_idle_seconds IS 'The number of seconds the backend is allowed to be idle (no inbound connections alive) before it is terminated.';


--
-- Name: COLUMN backend.state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend.state IS 'The most recent state of the backend.';


--
-- Name: backend_action; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backend_action (
    id character varying(255) NOT NULL,
    backend_id character varying(255),
    drone_id integer NOT NULL,
    action jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    acked_at timestamp with time zone
);


ALTER TABLE public.backend_action OWNER TO postgres;

--
-- Name: TABLE backend_action; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.backend_action IS 'Actions which are either queued to take place, or have taken place, on each backend.';


--
-- Name: COLUMN backend_action.backend_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_action.backend_id IS 'The backend the action applies to.';


--
-- Name: COLUMN backend_action.drone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_action.drone_id IS 'The drone associated with the backend_id. This is denormalized from the backend table so that we can efficiently index it.';


--
-- Name: COLUMN backend_action.action; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_action.action IS 'A JSON representation of the action to take. Deserializes to a BackendActionMessage.';


--
-- Name: COLUMN backend_action.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_action.created_at IS 'The time the action was created.';


--
-- Name: COLUMN backend_action.acked_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_action.acked_at IS 'The time the action was acked by the drone. Null if the action has not been acked. Will be re-sent on drone reconnect if not already acked.';


--
-- Name: backend_key; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backend_key (
    id character varying(255) NOT NULL,
    namespace character varying(255) NOT NULL,
    key_name character varying(255) NOT NULL,
    tag character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    fencing_token bigint NOT NULL,
    allow_renew boolean DEFAULT true NOT NULL
);


ALTER TABLE public.backend_key OWNER TO postgres;

--
-- Name: TABLE backend_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.backend_key IS 'Information about the key associated with each backend.';


--
-- Name: COLUMN backend_key.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_key.id IS 'The id of the backend the key is associated with.';


--
-- Name: COLUMN backend_key.namespace; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_key.namespace IS 'The namespace the key belongs to.';


--
-- Name: COLUMN backend_key.key_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_key.key_name IS 'The name of the key, unique within the namespace.';


--
-- Name: COLUMN backend_key.tag; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_key.tag IS 'A value which must match for an existing backend to be returned based on key.';


--
-- Name: COLUMN backend_key.expires_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_key.expires_at IS 'The time the key expires, unless renewed first.';


--
-- Name: COLUMN backend_key.fencing_token; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_key.fencing_token IS 'A number that monotonically increases when the same key is re-acquired, but stays the same across refreshes.';


--
-- Name: COLUMN backend_key.allow_renew; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_key.allow_renew IS 'If false, the key cannot be renewed for this backend, forcing the backend to be terminated.';


--
-- Name: backend_state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backend_state (
    id integer NOT NULL,
    backend_id character varying(255) NOT NULL,
    state jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.backend_state OWNER TO postgres;

--
-- Name: TABLE backend_state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.backend_state IS 'A history of state changes across all backends.';


--
-- Name: COLUMN backend_state.backend_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_state.backend_id IS 'The backend the state change refers to.';


--
-- Name: COLUMN backend_state.state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_state.state IS 'The state of the backend.';


--
-- Name: COLUMN backend_state.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.backend_state.created_at IS 'The time the state change was received.';


--
-- Name: backend_state_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.backend_state_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_state_id_seq OWNER TO postgres;

--
-- Name: backend_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.backend_state_id_seq OWNED BY public.backend_state.id;


--
-- Name: controller; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.controller (
    id character varying(255) NOT NULL,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_heartbeat timestamp with time zone NOT NULL,
    is_online boolean NOT NULL,
    plane_version character varying(255) NOT NULL,
    plane_hash character varying(255) NOT NULL,
    ip inet
);


ALTER TABLE public.controller OWNER TO postgres;

--
-- Name: TABLE controller; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.controller IS 'Self-reported information about controllers.';


--
-- Name: COLUMN controller.first_seen; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.controller.first_seen IS 'The first time the controller came online.';


--
-- Name: COLUMN controller.last_heartbeat; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.controller.last_heartbeat IS 'The last time the controller sent a heartbeat.';


--
-- Name: COLUMN controller.is_online; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.controller.is_online IS 'Whether the controller is online (self-reported; if a controller dies suddenly this will not be updated).';


--
-- Name: COLUMN controller.plane_version; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.controller.plane_version IS 'The version of plane running on the controller.';


--
-- Name: COLUMN controller.plane_hash; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.controller.plane_hash IS 'The git hash of the plane version running on the controller.';


--
-- Name: COLUMN controller.ip; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.controller.ip IS 'The last-seen IP of the controller (as seen from the Postgres server)';


--
-- Name: drone; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.drone (
    id integer NOT NULL,
    ready boolean NOT NULL,
    draining boolean DEFAULT false NOT NULL,
    last_heartbeat timestamp with time zone,
    last_local_time timestamp with time zone,
    pool text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.drone OWNER TO postgres;

--
-- Name: TABLE drone; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.drone IS 'Information about drones used for scheduling.';


--
-- Name: COLUMN drone.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.drone.id IS 'The unique id of the drone (shared with the node associated with this drone).';


--
-- Name: COLUMN drone.ready; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.drone.ready IS 'Whether the drone is ready to accept backends.';


--
-- Name: COLUMN drone.draining; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.drone.draining IS 'Whether the drone is draining. If true, this drone will not be considered by the scheduler.';


--
-- Name: COLUMN drone.last_heartbeat; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.drone.last_heartbeat IS 'The last time local_epoch_millis was received from the drone.';


--
-- Name: COLUMN drone.last_local_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.drone.last_local_time IS 'The last reported local timestamp on the drone, used to assign initial key leases when spawning.';


--
-- Name: COLUMN drone.pool; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.drone.pool IS 'The pool to which the drone is assigned (default pool is an empty string).';


--
-- Name: drone_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.drone_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.drone_id_seq OWNER TO postgres;

--
-- Name: drone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.drone_id_seq OWNED BY public.drone.id;


--
-- Name: event; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event (
    id integer NOT NULL,
    kind character varying(255) NOT NULL,
    key character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    data jsonb NOT NULL
);


ALTER TABLE public.event OWNER TO postgres;

--
-- Name: TABLE event; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.event IS 'A history of events that have been broacast in the system.';


--
-- Name: COLUMN event.kind; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.event.kind IS 'The kind of event (value of NotificationPayload::kind()).';


--
-- Name: COLUMN event.key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.event.key IS 'An optional key associated with the event. Along with "kind", acts like a pub/sub "subject". Subscriptions can filter on this key.';


--
-- Name: COLUMN event.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.event.created_at IS 'The time the event was created.';


--
-- Name: COLUMN event.data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.event.data IS 'A JSON representation of the event payload. Must be a type that implements NotificationPayload.';


--
-- Name: event_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.event_id_seq OWNER TO postgres;

--
-- Name: event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.event_id_seq OWNED BY public.event.id;


--
-- Name: node; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.node (
    id integer NOT NULL,
    kind character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    cluster character varying(255),
    plane_version character varying(255) NOT NULL,
    plane_hash character varying(255) NOT NULL,
    controller character varying(255),
    ip inet NOT NULL
);


ALTER TABLE public.node OWNER TO postgres;

--
-- Name: TABLE node; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.node IS 'Information about nodes (drones, proxies, DNS servers).';


--
-- Name: COLUMN node.kind; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node.kind IS 'A string representing the kind of node this is (serialized types::NodeKind).';


--
-- Name: COLUMN node.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node.name IS 'A string name provided by the node, unique within a cluster.';


--
-- Name: COLUMN node.cluster; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node.cluster IS 'The cluster the node belongs to. May be null if the node is cross-cluster (currently only DNS servers may have a null cluster).';


--
-- Name: COLUMN node.plane_version; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node.plane_version IS 'The version of plane running on the node.';


--
-- Name: COLUMN node.plane_hash; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node.plane_hash IS 'The git hash of the plane version running on the node.';


--
-- Name: COLUMN node.controller; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node.controller IS 'The controller the node is registered with (null if the node is offline).';


--
-- Name: COLUMN node.ip; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node.ip IS 'The last-seen IP of the node relative to the controller. This is just for reference; drones self-report their IP for use by proxies.';


--
-- Name: node_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.node_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.node_id_seq OWNER TO postgres;

--
-- Name: node_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.node_id_seq OWNED BY public.node.id;


--
-- Name: token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.token (
    token character varying(255) NOT NULL,
    backend_id character varying(255) NOT NULL,
    expiration_time timestamp with time zone NOT NULL,
    username character varying(255),
    auth jsonb NOT NULL,
    secret_token character varying(255) NOT NULL
);


ALTER TABLE public.token OWNER TO postgres;

--
-- Name: TABLE token; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.token IS 'Information about tokens used to make authorized connections to backends.';


--
-- Name: COLUMN token.token; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.token.token IS 'The token used to make the connection.';


--
-- Name: COLUMN token.backend_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.token.backend_id IS 'The backend the token is associated with.';


--
-- Name: COLUMN token.expiration_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.token.expiration_time IS 'The time the token expires.';


--
-- Name: COLUMN token.username; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.token.username IS 'The username associated with the token.';


--
-- Name: COLUMN token.auth; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.token.auth IS 'A JSON representation of arbitrary auth metadata which is passed to the backend.';


--
-- Name: COLUMN token.secret_token; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.token.secret_token IS 'A secret token optionally used for secondary authentication.';


--
-- Name: backend_state id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend_state ALTER COLUMN id SET DEFAULT nextval('public.backend_state_id_seq'::regclass);


--
-- Name: drone id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drone ALTER COLUMN id SET DEFAULT nextval('public.drone_id_seq'::regclass);


--
-- Name: event id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event ALTER COLUMN id SET DEFAULT nextval('public.event_id_seq'::regclass);


--
-- Name: node id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node ALTER COLUMN id SET DEFAULT nextval('public.node_id_seq'::regclass);


--
-- Name: _sqlx_migrations _sqlx_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._sqlx_migrations
    ADD CONSTRAINT _sqlx_migrations_pkey PRIMARY KEY (version);


--
-- Name: acme_txt_entries acme_txt_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acme_txt_entries
    ADD CONSTRAINT acme_txt_entries_pkey PRIMARY KEY (cluster);


--
-- Name: backend_action backend_action_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend_action
    ADD CONSTRAINT backend_action_pkey PRIMARY KEY (id);


--
-- Name: backend_key backend_key_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend_key
    ADD CONSTRAINT backend_key_pkey PRIMARY KEY (id);


--
-- Name: backend backend_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend
    ADD CONSTRAINT backend_pkey PRIMARY KEY (id);


--
-- Name: backend_state backend_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend_state
    ADD CONSTRAINT backend_state_pkey PRIMARY KEY (id);


--
-- Name: controller controller_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.controller
    ADD CONSTRAINT controller_pkey PRIMARY KEY (id);


--
-- Name: drone drone_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drone
    ADD CONSTRAINT drone_pkey PRIMARY KEY (id);


--
-- Name: event event_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (id);


--
-- Name: node node_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node
    ADD CONSTRAINT node_pkey PRIMARY KEY (id);


--
-- Name: token token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.token
    ADD CONSTRAINT token_pkey PRIMARY KEY (token);


--
-- Name: idx_backend_action_backend; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_backend_action_backend ON public.backend_action USING btree (backend_id);


--
-- Name: idx_backend_action_pending; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_backend_action_pending ON public.backend_action USING btree (drone_id, created_at) WHERE (acked_at IS NULL);


--
-- Name: idx_backend_drone_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_backend_drone_id ON public.backend USING btree (cluster, drone_id) WHERE ((last_status)::text <> 'terminated'::text);


--
-- Name: idx_backend_state_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_backend_state_created_at ON public.backend_state USING btree (backend_id, created_at);


--
-- Name: idx_backend_static_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_backend_static_token ON public.backend USING btree (static_token);


--
-- Name: idx_cluster_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_cluster_name ON public.node USING btree (cluster, name);


--
-- Name: idx_event_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_event_created_at ON public.event USING btree (created_at);


--
-- Name: idx_namespace_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_namespace_name ON public.backend_key USING btree (namespace, key_name);


--
-- Name: acme_txt_entries acme_txt_entries_leased_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acme_txt_entries
    ADD CONSTRAINT acme_txt_entries_leased_by_fkey FOREIGN KEY (leased_by) REFERENCES public.node(id);


--
-- Name: backend_action backend_action_backend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend_action
    ADD CONSTRAINT backend_action_backend_id_fkey FOREIGN KEY (backend_id) REFERENCES public.backend(id);


--
-- Name: backend_action backend_action_drone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend_action
    ADD CONSTRAINT backend_action_drone_id_fkey FOREIGN KEY (drone_id) REFERENCES public.drone(id);


--
-- Name: backend backend_drone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend
    ADD CONSTRAINT backend_drone_id_fkey FOREIGN KEY (drone_id) REFERENCES public.drone(id);


--
-- Name: backend_key backend_key_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend_key
    ADD CONSTRAINT backend_key_id_fkey FOREIGN KEY (id) REFERENCES public.backend(id);


--
-- Name: backend_state backend_state_backend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backend_state
    ADD CONSTRAINT backend_state_backend_id_fkey FOREIGN KEY (backend_id) REFERENCES public.backend(id);


--
-- Name: drone drone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drone
    ADD CONSTRAINT drone_id_fkey FOREIGN KEY (id) REFERENCES public.node(id);


--
-- Name: node node_controller_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node
    ADD CONSTRAINT node_controller_fkey FOREIGN KEY (controller) REFERENCES public.controller(id);


--
-- Name: token token_backend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.token
    ADD CONSTRAINT token_backend_id_fkey FOREIGN KEY (backend_id) REFERENCES public.backend(id);


--
-- PostgreSQL database dump complete
--

