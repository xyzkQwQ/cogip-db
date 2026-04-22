--
-- PostgreSQL database dump
--

\restrict HDucs5LXUWqzG2PjNIWAbIAeqEPB84WqEp4xgTruGlfrgiYLcynhBEBE7hzsj6R

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg13+1)
-- Dumped by pg_dump version 18.3

-- Started on 2026-04-22 14:17:14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 16469)
-- Name: pldbgapi; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pldbgapi WITH SCHEMA public;


--
-- TOC entry 3581 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pldbgapi; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pldbgapi IS 'server-side support for debugging PL/pgSQL functions';


--
-- TOC entry 266 (class 1255 OID 24709)
-- Name: audit_item(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.audit_item() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	IF TG_OP = 'INSERT' then
	INSERT INTO item_audit(item_id, operation, new_value)
        VALUES (NEW.id, 'INSERT', NEW.name);
			RETURN NEW;
	
	 ELSIF TG_OP = 'UPDATE' then
	 INSERT INTO item_audit(item_id, operation, old_value, new_value)
        VALUES (NEW.id, 'UPDATE', OLD.name, NEW.name);
	 		RETURN NEW;
	 
	 ELSIF TG_OP = 'DELETE' then
	 INSERT INTO item_audit(item_id, operation, old_value)
        VALUES (OLD.id, 'DELETE', OLD.name);
	 		RETURN OLD;
	 
 end if;

end;
$$;


ALTER FUNCTION public.audit_item() OWNER TO postgres;

--
-- TOC entry 283 (class 1255 OID 24672)
-- Name: check_orderline_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_orderline_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if OLD.delivered_quantity < OLD.ordered_quantity THEN
		raise exception 'SUPPRESSION IMPOSSIBLE pour order_id % et item_id %', OLD.order_id, OLD.item_id USING HINT = 'La commande n''est pas totalement livrée.';
	end if;

	return OLD;
end;
$$;


ALTER FUNCTION public.check_orderline_delete() OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 24666)
-- Name: check_user_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_user_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
if old.role = 'MAIN_ADMIN' then
raise exception 'Impossible de supprimer l`''utilisateur %. Il s''agit de
l''administrateur principal.', old.id;
end if;
return null;
END;
$$;


ALTER FUNCTION public.check_user_delete() OWNER TO postgres;

--
-- TOC entry 260 (class 1255 OID 16506)
-- Name: count_items_by_supplier(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.count_items_by_supplier(supplier_id_param integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    total integer;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM supplier WHERE id = supplier_id_param) THEN
        RAISE EXCEPTION 'L''identifiant % n''existe pas', supplier_id_param;
    END IF;

    SELECT count(DISTINCT item_id)
    INTO total
    FROM sale_offer
    WHERE supplier_id = supplier_id_param;

    RETURN total;
END;
$$;


ALTER FUNCTION public.count_items_by_supplier(supplier_id_param integer) OWNER TO postgres;

--
-- TOC entry 262 (class 1255 OID 16523)
-- Name: create_user(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_user(p_email character varying, p_password character varying, p_role character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
BEGIN

    -- Vérification mot de passe
    IF LENGTH(p_password) < 8 THEN
        RAISE EXCEPTION 'Mot de passe trop court';
    END IF;

    -- Vérification email
    IF p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Email invalide';
    END IF;

    -- Vérification rôle
    IF p_role NOT IN ('MAIN_ADMIN', 'ADMIN', 'COMMON') THEN
        RAISE EXCEPTION 'Rôle invalide';
    END IF;

    -- Insertion
    INSERT INTO "user"(email, password, role)
    VALUES (
        p_email,
        encode(digest(p_password, 'sha1'), 'hex'),
        p_role
    );

END;
$_$;


ALTER FUNCTION public.create_user(p_email character varying, p_password character varying, p_role character varying) OWNER TO postgres;

--
-- TOC entry 280 (class 1255 OID 24661)
-- Name: display_message_on_supplier_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.display_message_on_supplier_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
raise notice '« Un ajout de fournisseur va être fait. Le nouveau fournisseur est %', NEW.name;
return NEW;
END;
$$;


ALTER FUNCTION public.display_message_on_supplier_insert() OWNER TO postgres;

--
-- TOC entry 281 (class 1255 OID 24664)
-- Name: display_update_supplier(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.display_update_supplier() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
raise notice ' Mise à jour de la table des fournisseurs ';
raise notice ' Le nom de l''ancien fournisseur est %', OLD.name;
raise notice ' Le nom du nouveau fournisseur est %', NEW.name;
return NEW;
END;
$$;


ALTER FUNCTION public.display_update_supplier() OWNER TO postgres;

--
-- TOC entry 263 (class 1255 OID 24657)
-- Name: prevent_delete_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_delete_admin() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.role = 'MAIN_ADMIN' THEN
        RAISE EXCEPTION 'Suppression du MAIN_ADMIN interdite';
    END IF;
    RETURN OLD;
END;
$$;


ALTER FUNCTION public.prevent_delete_admin() OWNER TO postgres;

--
-- TOC entry 261 (class 1255 OID 16507)
-- Name: sales_revenue(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sales_revenue(supplier_id_param integer, year_param integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    total numeric;
BEGIN
    SELECT SUM(ol.ordered_quantity * ol.unit_price * 1.2)
    INTO total
    FROM order_line ol
    JOIN "order" o ON o.id = ol.order_id
    WHERE EXTRACT(YEAR FROM o.date) = year_param;

    RETURN COALESCE(total, 0);
END;
$$;


ALTER FUNCTION public.sales_revenue(supplier_id_param integer, year_param integer) OWNER TO postgres;

--
-- TOC entry 265 (class 1255 OID 24695)
-- Name: stock_not_negative(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.stock_not_negative() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if NEW.stock < 0 THEN
        raise exception 'Le stock ne peut pas être négatif.';
    end if;

    return new;

end;
$$;


ALTER FUNCTION public.stock_not_negative() OWNER TO postgres;

--
-- TOC entry 264 (class 1255 OID 24693)
-- Name: update_items_to_order(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_items_to_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	UPDATE items_to_order
	SET quantity = NEW.stock,
		date_update = CURRENT_DATE
	WHERE item_id = NEW.id;
	RETURN NEW;
end;
$$;


ALTER FUNCTION public.update_items_to_order() OWNER TO postgres;

--
-- TOC entry 279 (class 1255 OID 24660)
-- Name: user_connection(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_connection(user_email text, user_password text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
user_id_reference int; -- l'identifiant de l'utilisateur récupéré en base de données
user_password_reference text; -- le mot de passe de l'utilisateur récupéré en base de données
user_exists boolean; -- un indicateur d'existence de l'utilisateur
hashed_password text; -- va contenir le mot de passe haché
begin
-- vérification de l'existence de l'utilisateur
user_exists = exists(select *
from "user" u
where u.email like user_email);
-- si l'utilisateur existe, on vérifie son mot de passe
if user_exists then
-- récupération du mot de passe stocké en BDD
select "password"
into user_password_reference
from "user" u
where u.email like user_email;
-- calcul du hash du mot de passe passé en paramètre et vérification avec le hash en BDD
hashed_password = encode(digest(user_password, 'sha1'), 'hex');
if hashed_password like user_password_reference then
return true;
end if;
end if;
-- alert pour l'utilisateur
raise notice 'L''utilisateur ayant pour email % n''existe pas en base de données.',
user_email;
return false;
END
$$;


ALTER FUNCTION public.user_connection(user_email text, user_password text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 16385)
-- Name: order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."order" (
    id integer NOT NULL,
    supplier_id integer,
    date date DEFAULT CURRENT_DATE NOT NULL,
    comments character varying(800)
);


ALTER TABLE public."order" OWNER TO postgres;

--
-- TOC entry 3582 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN "order".comments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."order".comments IS 'Commentaires concernant la commande.';


--
-- TOC entry 221 (class 1259 OID 16393)
-- Name: entcom_numcom_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.entcom_numcom_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.entcom_numcom_seq OWNER TO postgres;

--
-- TOC entry 3583 (class 0 OID 0)
-- Dependencies: 221
-- Name: entcom_numcom_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.entcom_numcom_seq OWNED BY public."order".id;


--
-- TOC entry 222 (class 1259 OID 16394)
-- Name: supplier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.supplier (
    id integer NOT NULL,
    name character varying(30),
    address character varying(30),
    postal_code character varying(5),
    city character varying(25),
    contact_name character varying(15),
    satisfaction_index integer DEFAULT NULL::numeric
);


ALTER TABLE public.supplier OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16399)
-- Name: fournis_numfou_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fournis_numfou_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fournis_numfou_seq OWNER TO postgres;

--
-- TOC entry 3584 (class 0 OID 0)
-- Dependencies: 223
-- Name: fournis_numfou_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fournis_numfou_seq OWNED BY public.supplier.id;


--
-- TOC entry 224 (class 1259 OID 16400)
-- Name: item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item (
    id integer NOT NULL,
    item_code character(4) NOT NULL,
    name character varying(25),
    stock_alert integer NOT NULL,
    stock integer NOT NULL,
    yearly_consumption integer NOT NULL,
    unit character varying(15)
);


ALTER TABLE public.item OWNER TO postgres;

--
-- TOC entry 3585 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN item.yearly_consumption; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item.yearly_consumption IS 'Consommation annuelle estimée.';


--
-- TOC entry 239 (class 1259 OID 24698)
-- Name: item_audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_audit (
    id integer NOT NULL,
    item_id integer,
    operation character varying
);


ALTER TABLE public.item_audit OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 24697)
-- Name: item_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_audit_id_seq OWNER TO postgres;

--
-- TOC entry 3586 (class 0 OID 0)
-- Dependencies: 238
-- Name: item_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_audit_id_seq OWNED BY public.item_audit.id;


--
-- TOC entry 237 (class 1259 OID 24675)
-- Name: items_to_order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.items_to_order (
    id integer NOT NULL,
    item_id integer NOT NULL,
    quantity integer,
    date_update date
);


ALTER TABLE public.items_to_order OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 24674)
-- Name: items_to_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.items_to_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.items_to_order_id_seq OWNER TO postgres;

--
-- TOC entry 3587 (class 0 OID 0)
-- Dependencies: 236
-- Name: items_to_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.items_to_order_id_seq OWNED BY public.items_to_order.id;


--
-- TOC entry 225 (class 1259 OID 16408)
-- Name: order_line; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_line (
    order_id integer NOT NULL,
    item_id integer NOT NULL,
    line_number numeric(3,0) NOT NULL,
    ordered_quantity integer NOT NULL,
    unit_price double precision NOT NULL,
    delivered_quantity numeric(6,0) DEFAULT NULL::numeric,
    last_delivery_date date
);


ALTER TABLE public.order_line OWNER TO postgres;

--
-- TOC entry 3588 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN order_line.line_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.order_line.line_number IS 'Numéro de la ligne de commande.';


--
-- TOC entry 3589 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN order_line.ordered_quantity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.order_line.ordered_quantity IS 'Le nombre d''articles commandés.';


--
-- TOC entry 226 (class 1259 OID 16417)
-- Name: ligcom_numcom_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ligcom_numcom_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ligcom_numcom_seq OWNER TO postgres;

--
-- TOC entry 3590 (class 0 OID 0)
-- Dependencies: 226
-- Name: ligcom_numcom_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ligcom_numcom_seq OWNED BY public.order_line.order_id;


--
-- TOC entry 227 (class 1259 OID 16418)
-- Name: produit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.produit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.produit_id_seq OWNER TO postgres;

--
-- TOC entry 3591 (class 0 OID 0)
-- Dependencies: 227
-- Name: produit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.produit_id_seq OWNED BY public.item.id;


--
-- TOC entry 228 (class 1259 OID 16419)
-- Name: sale_offer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sale_offer (
    item_id integer NOT NULL,
    supplier_id integer NOT NULL,
    delivery_time numeric(6,0) NOT NULL,
    price integer NOT NULL,
    date date
);


ALTER TABLE public.sale_offer OWNER TO postgres;

--
-- TOC entry 3592 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN sale_offer.delivery_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sale_offer.delivery_time IS 'Délait de livraison estimé par le fournisseur.';


--
-- TOC entry 3593 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN sale_offer.price; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sale_offer.price IS 'Prix unitaire pour le produit.';


--
-- TOC entry 3594 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN sale_offer.date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sale_offer.date IS 'Date de l''offre.';


--
-- TOC entry 235 (class 1259 OID 16526)
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."user" (
    id integer NOT NULL,
    email character varying NOT NULL,
    last_login timestamp without time zone,
    password character varying NOT NULL,
    role character varying NOT NULL,
    connexion_attempt integer DEFAULT 0,
    blocked_account boolean DEFAULT false
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16525)
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_id_seq OWNER TO postgres;

--
-- TOC entry 3595 (class 0 OID 0)
-- Dependencies: 234
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- TOC entry 3378 (class 2604 OID 16426)
-- Name: item id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item ALTER COLUMN id SET DEFAULT nextval('public.produit_id_seq'::regclass);


--
-- TOC entry 3385 (class 2604 OID 24701)
-- Name: item_audit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_audit ALTER COLUMN id SET DEFAULT nextval('public.item_audit_id_seq'::regclass);


--
-- TOC entry 3384 (class 2604 OID 24678)
-- Name: items_to_order id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items_to_order ALTER COLUMN id SET DEFAULT nextval('public.items_to_order_id_seq'::regclass);


--
-- TOC entry 3374 (class 2604 OID 16427)
-- Name: order id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."order" ALTER COLUMN id SET DEFAULT nextval('public.entcom_numcom_seq'::regclass);


--
-- TOC entry 3379 (class 2604 OID 16428)
-- Name: order_line order_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line ALTER COLUMN order_id SET DEFAULT nextval('public.ligcom_numcom_seq'::regclass);


--
-- TOC entry 3376 (class 2604 OID 16429)
-- Name: supplier id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier ALTER COLUMN id SET DEFAULT nextval('public.fournis_numfou_seq'::regclass);


--
-- TOC entry 3381 (class 2604 OID 16529)
-- Name: user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- TOC entry 3565 (class 0 OID 16400)
-- Dependencies: 224
-- Data for Name: item; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.item VALUES (0, 'B001', 'Bande magnetique 1200', 20, 87, 240, 'unite');
INSERT INTO public.item VALUES (1, 'B002', 'Bande magnétique 6250', 20, 12, 410, 'unite');
INSERT INTO public.item VALUES (2, 'D035', 'CD R slim 80 mm', 40, 42, 150, 'B010');
INSERT INTO public.item VALUES (3, 'D050', 'CD R-W 80mm', 50, 4, 0, 'B010');
INSERT INTO public.item VALUES (4, 'I100', 'Papier 1 ex continu', 100, 557, 3500, 'B1000');
INSERT INTO public.item VALUES (5, 'I105', 'Papier 2 ex continu', 75, 5, 2300, 'B1000');
INSERT INTO public.item VALUES (6, 'I108', 'Papier 3 ex continu', 200, 557, 3500, 'B500');
INSERT INTO public.item VALUES (7, 'I110', 'Papier 4 ex continu', 10, 12, 63, 'B400');
INSERT INTO public.item VALUES (8, 'P220', 'Pre-imprime commande', 500, 2500, 24500, 'B500');
INSERT INTO public.item VALUES (9, 'P230', 'Pre-imprime facture', 500, 250, 12500, 'B500');
INSERT INTO public.item VALUES (10, 'P240', 'Pre-imprime bulletin paie', 500, 3000, 6250, 'B500');
INSERT INTO public.item VALUES (11, 'P250', 'Pre-imprime bon livraison', 500, 2500, 24500, 'B500');
INSERT INTO public.item VALUES (12, 'P270', 'Pre-imprime bon fabricati', 500, 2500, 24500, 'B500');
INSERT INTO public.item VALUES (13, 'R080', 'ruban Epson 850', 10, 2, 120, 'unite');
INSERT INTO public.item VALUES (14, '14  ', 'ruban impl 1200 lignes', 25, 200, 182, 'unite');


--
-- TOC entry 3575 (class 0 OID 24698)
-- Dependencies: 239
-- Data for Name: item_audit; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3573 (class 0 OID 24675)
-- Dependencies: 237
-- Data for Name: items_to_order; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3561 (class 0 OID 16385)
-- Dependencies: 220
-- Data for Name: order; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."order" VALUES (70010, 120, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70011, 540, '2021-01-15', 'Commande urgente');
INSERT INTO public."order" VALUES (70020, 9180, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70025, 9150, '2021-01-15', 'Commande urgente');
INSERT INTO public."order" VALUES (70210, 120, '2021-01-15', 'Commande cadencée');
INSERT INTO public."order" VALUES (70250, 8700, '2021-01-15', 'Commande cadencée');
INSERT INTO public."order" VALUES (70300, 9120, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70620, 540, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70625, 120, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70629, 9180, '2021-01-15', NULL);


--
-- TOC entry 3566 (class 0 OID 16408)
-- Dependencies: 225
-- Data for Name: order_line; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.order_line VALUES (70010, 6, 3, 1000, 680, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70010, 8, 5, 6000, 999.99, 6000, '2021-01-15');
INSERT INTO public.order_line VALUES (70010, 10, 6, 6000, 999.99, 2000, '2021-01-15');
INSERT INTO public.order_line VALUES (70010, 13, 2, 10000, 999.99, 10000, '2021-01-15');
INSERT INTO public.order_line VALUES (70011, 5, 1, 1000, 600, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70020, 1, 2, 200, 140, NULL, NULL);
INSERT INTO public.order_line VALUES (70025, 4, 1, 1000, 590, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70025, 5, 2, 500, 590, 500, '2021-01-15');
INSERT INTO public.order_line VALUES (70210, 4, 1, 1000, 470, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70250, 8, 2, 10000, 999.99, 10000, '2021-01-15');
INSERT INTO public.order_line VALUES (70250, 9, 1, 15000, 999.99, 12000, '2021-01-15');
INSERT INTO public.order_line VALUES (70300, 7, 1, 50, 790, 50, '2021-01-15');
INSERT INTO public.order_line VALUES (70620, 5, 1, 200, 600, 200, '2021-01-15');
INSERT INTO public.order_line VALUES (70625, 4, 1, 1000, 470, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70625, 8, 2, 10000, 999.99, 10000, '2021-01-15');
INSERT INTO public.order_line VALUES (70629, 1, 2, 200, 140, NULL, NULL);
INSERT INTO public.order_line VALUES (70010, 2, 4, 200, 40, 200, '2021-01-15');
INSERT INTO public.order_line VALUES (70010, 5, 2, 2000, 485, 1500, '2021-01-15');
INSERT INTO public.order_line VALUES (70020, 0, 1, 200, 140, 100, NULL);


--
-- TOC entry 3569 (class 0 OID 16419)
-- Dependencies: 228
-- Data for Name: sale_offer; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.sale_offer VALUES (0, 8700, 15, 150, NULL);
INSERT INTO public.sale_offer VALUES (1, 8700, 15, 210, NULL);
INSERT INTO public.sale_offer VALUES (2, 120, 0, 40, NULL);
INSERT INTO public.sale_offer VALUES (2, 9120, 5, 40, NULL);
INSERT INTO public.sale_offer VALUES (4, 120, 90, 700, NULL);
INSERT INTO public.sale_offer VALUES (4, 540, 70, 710, NULL);
INSERT INTO public.sale_offer VALUES (4, 9120, 60, 800, NULL);
INSERT INTO public.sale_offer VALUES (4, 9150, 90, 650, NULL);
INSERT INTO public.sale_offer VALUES (4, 9180, 30, 720, NULL);
INSERT INTO public.sale_offer VALUES (5, 120, 90, 705, NULL);
INSERT INTO public.sale_offer VALUES (5, 540, 70, 810, NULL);
INSERT INTO public.sale_offer VALUES (5, 8700, 30, 720, NULL);
INSERT INTO public.sale_offer VALUES (5, 9120, 60, 920, NULL);
INSERT INTO public.sale_offer VALUES (5, 9150, 90, 685, NULL);
INSERT INTO public.sale_offer VALUES (6, 120, 90, 795, NULL);
INSERT INTO public.sale_offer VALUES (6, 9120, 60, 920, NULL);
INSERT INTO public.sale_offer VALUES (7, 9120, 60, 950, NULL);
INSERT INTO public.sale_offer VALUES (7, 9180, 90, 900, NULL);
INSERT INTO public.sale_offer VALUES (13, 9120, 10, 120, NULL);
INSERT INTO public.sale_offer VALUES (14, 9120, 5, 275, NULL);


--
-- TOC entry 3563 (class 0 OID 16394)
-- Dependencies: 222
-- Data for Name: supplier; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.supplier VALUES (120, 'GROBRIGAN', '20 rue du papier', '92200', 'papercity', 'georges', 8);
INSERT INTO public.supplier VALUES (540, 'ECLIPSE', '53 rue laisse flotter', '78250', 'bugbugville', 'nestor', 7);
INSERT INTO public.supplier VALUES (8700, 'MEDICIS', '120 rue des plantes', '75014', 'paris', 'lison', NULL);
INSERT INTO public.supplier VALUES (9120, 'DICOBOL', '11 rue des sports', '85100', 'roche/yon', 'hercule', 8);
INSERT INTO public.supplier VALUES (9150, 'DEPANPAP', '26 av des loco', '59987', 'coroncountry', 'pollux', 5);
INSERT INTO public.supplier VALUES (9180, 'HURRYTAPE', '68 bvd des octets', '04044', 'Dumpville', 'Track', NULL);
INSERT INTO public.supplier VALUES (1, 'TEST', '10 rue du test', '17000', 'La Rochelle', 'DUfont', 3);
INSERT INTO public.supplier VALUES (20, 'esperce', 'jfdgdfg', '40000', 'gfdgdfg', 'fdgdfg', NULL);


--
-- TOC entry 3571 (class 0 OID 16526)
-- Dependencies: 235
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3596 (class 0 OID 0)
-- Dependencies: 221
-- Name: entcom_numcom_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.entcom_numcom_seq', 1, false);


--
-- TOC entry 3597 (class 0 OID 0)
-- Dependencies: 223
-- Name: fournis_numfou_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fournis_numfou_seq', 21, true);


--
-- TOC entry 3598 (class 0 OID 0)
-- Dependencies: 238
-- Name: item_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_audit_id_seq', 1, false);


--
-- TOC entry 3599 (class 0 OID 0)
-- Dependencies: 236
-- Name: items_to_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.items_to_order_id_seq', 1, false);


--
-- TOC entry 3600 (class 0 OID 0)
-- Dependencies: 226
-- Name: ligcom_numcom_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ligcom_numcom_seq', 1, false);


--
-- TOC entry 3601 (class 0 OID 0)
-- Dependencies: 227
-- Name: produit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.produit_id_seq', 1, false);


--
-- TOC entry 3602 (class 0 OID 0)
-- Dependencies: 234
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_id_seq', 1, false);


--
-- TOC entry 3401 (class 2606 OID 24706)
-- Name: item_audit item_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_audit
    ADD CONSTRAINT item_audit_pkey PRIMARY KEY (id);


--
-- TOC entry 3391 (class 2606 OID 16431)
-- Name: item item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (id);


--
-- TOC entry 3399 (class 2606 OID 24682)
-- Name: items_to_order items_to_order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items_to_order
    ADD CONSTRAINT items_to_order_pkey PRIMARY KEY (id);


--
-- TOC entry 3393 (class 2606 OID 16433)
-- Name: order_line order_line_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line
    ADD CONSTRAINT order_line_pkey PRIMARY KEY (order_id, item_id);


--
-- TOC entry 3387 (class 2606 OID 16435)
-- Name: order order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."order"
    ADD CONSTRAINT order_pkey PRIMARY KEY (id);


--
-- TOC entry 3395 (class 2606 OID 16437)
-- Name: sale_offer sale_offer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sale_offer
    ADD CONSTRAINT sale_offer_pkey PRIMARY KEY (item_id, supplier_id);


--
-- TOC entry 3389 (class 2606 OID 16439)
-- Name: supplier supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT supplier_pkey PRIMARY KEY (id);


--
-- TOC entry 3397 (class 2606 OID 16539)
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- TOC entry 3409 (class 2620 OID 24694)
-- Name: item after_update_item; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER after_update_item AFTER UPDATE ON public.item FOR EACH ROW EXECUTE FUNCTION public.update_items_to_order();


--
-- TOC entry 3407 (class 2620 OID 24662)
-- Name: supplier before_insert_supplier; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER before_insert_supplier BEFORE INSERT ON public.supplier FOR EACH ROW EXECUTE FUNCTION public.display_message_on_supplier_insert();


--
-- TOC entry 3410 (class 2620 OID 24696)
-- Name: item stock_before_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER stock_before_update BEFORE UPDATE ON public.item FOR EACH ROW EXECUTE FUNCTION public.stock_not_negative();


--
-- TOC entry 3408 (class 2620 OID 24663)
-- Name: supplier trg_insert_supplier; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_insert_supplier BEFORE INSERT ON public.supplier FOR EACH ROW EXECUTE FUNCTION public.display_message_on_supplier_insert();


--
-- TOC entry 3411 (class 2620 OID 24710)
-- Name: item trgg_audit_item; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trgg_audit_item AFTER INSERT OR DELETE OR UPDATE ON public.item FOR EACH ROW EXECUTE FUNCTION public.audit_item();


--
-- TOC entry 3412 (class 2620 OID 24673)
-- Name: order_line trgg_check_orderline_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trgg_check_orderline_delete BEFORE DELETE ON public.order_line FOR EACH ROW EXECUTE FUNCTION public.check_orderline_delete();


--
-- TOC entry 3413 (class 2620 OID 24670)
-- Name: user trigger_delete_user; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_delete_user BEFORE DELETE ON public."user" FOR EACH ROW EXECUTE FUNCTION public.check_user_delete();


--
-- TOC entry 3403 (class 2606 OID 16440)
-- Name: order_line fk_ligcom_entcom; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line
    ADD CONSTRAINT fk_ligcom_entcom FOREIGN KEY (order_id) REFERENCES public."order"(id) ON DELETE CASCADE;


--
-- TOC entry 3404 (class 2606 OID 16445)
-- Name: order_line fk_ligcom_produit; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line
    ADD CONSTRAINT fk_ligcom_produit FOREIGN KEY (item_id) REFERENCES public.item(id);


--
-- TOC entry 3402 (class 2606 OID 16450)
-- Name: order fk_order_supplier; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."order"
    ADD CONSTRAINT fk_order_supplier FOREIGN KEY (supplier_id) REFERENCES public.supplier(id) ON DELETE SET NULL;


--
-- TOC entry 3405 (class 2606 OID 16455)
-- Name: sale_offer supplier_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sale_offer
    ADD CONSTRAINT supplier_ibfk_1 FOREIGN KEY (supplier_id) REFERENCES public.supplier(id);


--
-- TOC entry 3406 (class 2606 OID 16460)
-- Name: sale_offer supplier_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sale_offer
    ADD CONSTRAINT supplier_ibfk_2 FOREIGN KEY (item_id) REFERENCES public.item(id);


-- Completed on 2026-04-22 14:17:14

--
-- PostgreSQL database dump complete
--

\unrestrict HDucs5LXUWqzG2PjNIWAbIAeqEPB84WqEp4xgTruGlfrgiYLcynhBEBE7hzsj6R

