--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2
-- Dumped by pg_dump version 13.2

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
-- Name: gatunki_zwierzat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gatunki_zwierzat (
    id_gatunku integer NOT NULL,
    nazwa_gatunku character varying,
    gromada character varying,
    rzad character varying,
    dlugosc_zycia integer,
    kategoria_zagrozenia character varying,
    rodzaj_pozywienia character varying
);


ALTER TABLE public.gatunki_zwierzat OWNER TO postgres;

--
-- Name: zwierzeta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zwierzeta (
    id_zwierzecia integer NOT NULL,
    nazwa character varying,
    plec character varying,
    wiek integer,
    id_pokarmu integer,
    id_gatunku integer,
    id_sektoru integer
);


ALTER TABLE public.zwierzeta OWNER TO postgres;

--
-- Name: emerytowane_zwierzeta; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.emerytowane_zwierzeta AS
 SELECT z.nazwa,
    g.nazwa_gatunku,
    g.dlugosc_zycia,
    z.wiek
   FROM (public.zwierzeta z
     JOIN public.gatunki_zwierzat g ON ((z.id_gatunku = g.id_gatunku)))
  WHERE ((g.dlugosc_zycia / 2) < z.wiek);


ALTER TABLE public.emerytowane_zwierzeta OWNER TO postgres;

--
-- Name: gatunki_zagrozone_wyginieciem; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.gatunki_zagrozone_wyginieciem AS
 SELECT z.nazwa,
    g.nazwa_gatunku,
    g.gromada,
    g.rzad,
    g.kategoria_zagrozenia
   FROM (public.zwierzeta z
     JOIN public.gatunki_zwierzat g ON ((z.id_gatunku = g.id_gatunku)))
  WHERE ((g.kategoria_zagrozenia)::text = ANY ((ARRAY['CR'::character varying, 'EN'::character varying, 'VU'::character varying])::text[]));


ALTER TABLE public.gatunki_zagrozone_wyginieciem OWNER TO postgres;

--
-- Name: liczba_gromad; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.liczba_gromad AS
 SELECT g.gromada,
    count(*) AS liczba_zwierzat
   FROM (public.gatunki_zwierzat g
     JOIN public.zwierzeta z ON ((g.id_gatunku = z.id_gatunku)))
  GROUP BY g.gromada;


ALTER TABLE public.liczba_gromad OWNER TO postgres;

--
-- Name: liczba_rzedow; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.liczba_rzedow AS
 SELECT g.rzad,
    count(*) AS liczba_zwierzat
   FROM (public.gatunki_zwierzat g
     JOIN public.zwierzeta z ON ((g.id_gatunku = z.id_gatunku)))
  GROUP BY g.rzad;


ALTER TABLE public.liczba_rzedow OWNER TO postgres;

--
-- Name: najstarsze_zwierzeta; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.najstarsze_zwierzeta AS
 SELECT z.id_zwierzecia,
    z.nazwa,
    g.nazwa_gatunku,
    z.wiek,
    g.dlugosc_zycia
   FROM (public.zwierzeta z
     JOIN public.gatunki_zwierzat g ON ((z.id_gatunku = g.id_gatunku)))
  ORDER BY z.wiek DESC;


ALTER TABLE public.najstarsze_zwierzeta OWNER TO postgres;

--
-- Name: opiekunowie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.opiekunowie (
    id_opiekuna integer NOT NULL,
    imie character varying,
    nazwisko character varying,
    pensja integer,
    godzina_rozpoczecia time(0) without time zone,
    godzina_zakonczenia time(0) without time zone
);


ALTER TABLE public.opiekunowie OWNER TO postgres;

--
-- Name: sektor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sektor (
    id_sektoru integer NOT NULL,
    nazwa_sektoru character varying,
    rodzaj_srodowiska character varying,
    czas_sprzatania time(0) without time zone,
    czas_karmienia time(0) without time zone,
    id_opiekuna integer
);


ALTER TABLE public.sektor OWNER TO postgres;

--
-- Name: opiekunowie_i_zwierzeta; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.opiekunowie_i_zwierzeta AS
 SELECT z.nazwa,
    g.nazwa_gatunku,
    s.nazwa_sektoru,
    o.id_opiekuna,
    (((o.imie)::text || ' '::text) || (o.nazwisko)::text) AS opiekun
   FROM (((public.zwierzeta z
     JOIN public.gatunki_zwierzat g ON ((z.id_gatunku = g.id_gatunku)))
     JOIN public.sektor s ON ((z.id_sektoru = s.id_sektoru)))
     JOIN public.opiekunowie o ON ((s.id_opiekuna = o.id_opiekuna)));


ALTER TABLE public.opiekunowie_i_zwierzeta OWNER TO postgres;

--
-- Name: podzial_plci_w_sektorach; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.podzial_plci_w_sektorach AS
 SELECT g.nazwa_gatunku,
    s.nazwa_sektoru,
    count(
        CASE
            WHEN ((z.plec)::text = 'm'::text) THEN 1
            ELSE NULL::integer
        END) AS liczba_samcow,
    count(
        CASE
            WHEN ((z.plec)::text = 'f'::text) THEN 1
            ELSE NULL::integer
        END) AS liczba_samic,
    count(*) AS ogolem
   FROM ((public.sektor s
     JOIN public.zwierzeta z ON ((s.id_sektoru = z.id_sektoru)))
     JOIN public.gatunki_zwierzat g ON ((z.id_gatunku = g.id_gatunku)))
  GROUP BY g.nazwa_gatunku, s.nazwa_sektoru;


ALTER TABLE public.podzial_plci_w_sektorach OWNER TO postgres;

--
-- Name: pokarmy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pokarmy (
    id_pokarmu integer NOT NULL,
    nazwa_pokarmu character varying,
    typ_pokarmu character varying,
    jednostka_pokarmu character varying,
    ilosc_pokarmu integer
);


ALTER TABLE public.pokarmy OWNER TO postgres;

--
-- Name: rozklad_dnia_opiekuna; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.rozklad_dnia_opiekuna AS
 SELECT DISTINCT (((o.imie)::text || ' '::text) || (o.nazwisko)::text) AS opiekun,
    o.id_opiekuna,
    o.godzina_rozpoczecia,
    o.godzina_zakonczenia,
    s.czas_sprzatania,
    s.czas_karmienia,
    s.nazwa_sektoru AS obsluga_sektoru
   FROM (public.opiekunowie o
     JOIN public.sektor s ON ((o.id_opiekuna = s.id_opiekuna)));


ALTER TABLE public.rozklad_dnia_opiekuna OWNER TO postgres;

--
-- Name: rzedy_zwierzat_w_sektorach; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.rzedy_zwierzat_w_sektorach AS
 SELECT s.nazwa_sektoru,
    g.rzad,
    count(*) AS count
   FROM ((public.sektor s
     JOIN public.zwierzeta z ON ((s.id_sektoru = z.id_sektoru)))
     JOIN public.gatunki_zwierzat g ON ((z.id_gatunku = g.id_gatunku)))
  GROUP BY s.nazwa_sektoru, g.rzad;


ALTER TABLE public.rzedy_zwierzat_w_sektorach OWNER TO postgres;

--
-- Name: sektory_i_pozywienie; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.sektory_i_pozywienie AS
 SELECT DISTINCT s.nazwa_sektoru,
    g.nazwa_gatunku,
    p.nazwa_pokarmu,
    p.typ_pokarmu,
    ((p.ilosc_pokarmu || ''::text) || (p.jednostka_pokarmu)::text) AS ilosc_pokarmu
   FROM (((public.gatunki_zwierzat g
     JOIN public.zwierzeta z ON ((g.id_gatunku = z.id_gatunku)))
     JOIN public.sektor s ON ((z.id_sektoru = s.id_sektoru)))
     JOIN public.pokarmy p ON ((z.id_pokarmu = p.id_pokarmu)))
  ORDER BY g.nazwa_gatunku;


ALTER TABLE public.sektory_i_pozywienie OWNER TO postgres;

--
-- Name: sektory_sprzatane_o_godz_12; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.sektory_sprzatane_o_godz_12 AS
 SELECT s.id_sektoru,
    s.nazwa_sektoru,
    (((o.imie)::text || ' '::text) || (o.nazwisko)::text) AS opiekun
   FROM (public.sektor s
     JOIN public.opiekunowie o ON ((s.id_opiekuna = o.id_opiekuna)))
  WHERE (s.czas_karmienia = '12:00:00'::time without time zone);


ALTER TABLE public.sektory_sprzatane_o_godz_12 OWNER TO postgres;

--
-- Name: wykaz_karmienia; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.wykaz_karmienia AS
 SELECT DISTINCT p.nazwa_pokarmu,
    s.nazwa_sektoru,
    s.czas_karmienia,
    p.typ_pokarmu,
    p.ilosc_pokarmu,
    p.jednostka_pokarmu
   FROM ((public.sektor s
     JOIN public.zwierzeta z ON ((s.id_sektoru = z.id_sektoru)))
     JOIN public.pokarmy p ON ((z.id_pokarmu = p.id_pokarmu)));


ALTER TABLE public.wykaz_karmienia OWNER TO postgres;

--
-- Data for Name: gatunki_zwierzat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gatunki_zwierzat (id_gatunku, nazwa_gatunku, gromada, rzad, dlugosc_zycia, kategoria_zagrozenia, rodzaj_pozywienia) FROM stdin;
1	nosacz sundajski	ssaki	naczelne	20	EN	roslinorzerne
2	lew	ssaki	drapiezne	15	VU	miesorzerne
3	zyrafa	ssaki	cetartiodactyla	26	VU	roslinozerne
4	hipopotam	ssaki	parzystokopytne	50	VU	roslinorzerne
5	lama	ssaki	cetartiodactyla	20	LC	roslinorzene
7	lemur	ssaki	naczelne	19	CR	roslinorzerne
8	malpa kapucynka	ssaki	naczelne	25	LC	roslinorzene
9	iguana	gad	luskonosne	20	LC	wszystkorzerne
10	pingwin cesarski	ptaki	pingwiny	20	NT	miesorzerne
11	hiena	ssaki	drapiezne	20	NT	miesorzerne
12	surykatka	ssaki	drapiezne	14	LC	wszystkorzerne
6	kameleon jemenski	gad	luskonosne	8	LC	wszystkorzerne
\.


--
-- Data for Name: opiekunowie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.opiekunowie (id_opiekuna, imie, nazwisko, pensja, godzina_rozpoczecia, godzina_zakonczenia) FROM stdin;
1	Joanna	Kowalska	3300	07:00:00	15:00:00
2	Dariusz	Nowak	4200	10:00:00	18:00:00
3	Bruno	Kowalewski	3500	07:00:00	16:00:00
4	Maria	Nowicka	3400	06:00:00	14:00:00
5	Jan	Labuda	3900	08:00:00	16:00:00
\.


--
-- Data for Name: pokarmy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pokarmy (id_pokarmu, nazwa_pokarmu, typ_pokarmu, jednostka_pokarmu, ilosc_pokarmu) FROM stdin;
1	miks bananowy	roslinny	kg	4
2	udziedz antylopy	mieso	kg	8
3	mieszanka witaminowa	mieszane	kg	6
4	arbuzy	roslinny	szt	25
5	pasza	roslinny	kg	15
6	karmowka dla gadow	mieso	kg	2
11	warzywa lisciaste	roslinny	kg	13
7	kisc bananow	roslinny	szt	5
8	miks larw i owocow	mieszane	g	800
9	ryby	mieso	szt	17
10	mieso wolowe	mieso	kg	9
\.


--
-- Data for Name: sektor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sektor (id_sektoru, nazwa_sektoru, rodzaj_srodowiska, czas_sprzatania, czas_karmienia, id_opiekuna) FROM stdin;
1	drapiezniki	sahara	09:00:00	12:00:00	1
2	roslinorzercy	sawanna	13:00:00	07:00:00	4
3	gady i plazy	terraria	11:00:00	15:00:00	2
4	naczelne	malpi gaj	08:00:00	12:00:00	5
5	pingwiny	obnizona temperatura	07:00:00	10:00:00	3
6	gospodarcze	laki	12:00:00	16:00:00	2
\.


--
-- Data for Name: zwierzeta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zwierzeta (id_zwierzecia, nazwa, plec, wiek, id_pokarmu, id_gatunku, id_sektoru) FROM stdin;
1	Skoczek	m	10	1	1	4
2	Ada	f	7	1	1	4
3	Mufasa	m	2	2	2	1
4	Kiara	f	5	2	2	1
5	Leon	m	17	11	3	2
6	Luiza	f	15	11	3	2
7	Olek	m	45	4	4	2
8	Calineczka	f	25	4	4	2
9	Bigi	m	2	3	4	2
10	Karol	m	12	11	5	6
11	Elza	f	9	11	5	6
12	Edek	m	3	8	6	3
13	Julian	m	4	3	7	2
14	Mort	m	9	3	7	2
15	Moris	m	12	3	7	2
16	Mazak	m	16	1	8	2
17	Kretka	f	16	1	8	2
18	Pan Kipling	m	15	8	9	3
19	Skiper	m	8	9	10	5
20	Kowalski	m	8	9	10	5
21	Szeregowy	m	8	9	10	5
22	Rico	m	8	9	10	5
23	Shenzi	f	11	10	11	1
24	Banzi	m	10	10	11	1
25	Ed	m	14	10	11	1
26	Timon	m	6	8	12	1
\.


--
-- Name: gatunki_zwierzat gatunki_zwierzat_nazwa_gatunku_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gatunki_zwierzat
    ADD CONSTRAINT gatunki_zwierzat_nazwa_gatunku_key UNIQUE (nazwa_gatunku);


--
-- Name: gatunki_zwierzat gatunki_zwierzat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gatunki_zwierzat
    ADD CONSTRAINT gatunki_zwierzat_pkey PRIMARY KEY (id_gatunku);


--
-- Name: opiekunowie opiekunowie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.opiekunowie
    ADD CONSTRAINT opiekunowie_pkey PRIMARY KEY (id_opiekuna);


--
-- Name: pokarmy pokarmy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pokarmy
    ADD CONSTRAINT pokarmy_pkey PRIMARY KEY (id_pokarmu);


--
-- Name: sektor sektor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sektor
    ADD CONSTRAINT sektor_pkey PRIMARY KEY (id_sektoru);


--
-- Name: zwierzeta zwierzeta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zwierzeta
    ADD CONSTRAINT zwierzeta_pkey PRIMARY KEY (id_zwierzecia);


--
-- Name: sektor sektor_id_opiekuna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sektor
    ADD CONSTRAINT sektor_id_opiekuna_fkey FOREIGN KEY (id_opiekuna) REFERENCES public.opiekunowie(id_opiekuna);


--
-- Name: zwierzeta zwierzeta_id_gatunku_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zwierzeta
    ADD CONSTRAINT zwierzeta_id_gatunku_fkey FOREIGN KEY (id_gatunku) REFERENCES public.gatunki_zwierzat(id_gatunku);


--
-- Name: zwierzeta zwierzeta_id_pokarmu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zwierzeta
    ADD CONSTRAINT zwierzeta_id_pokarmu_fkey FOREIGN KEY (id_pokarmu) REFERENCES public.pokarmy(id_pokarmu);


--
-- Name: zwierzeta zwierzeta_id_sektoru_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zwierzeta
    ADD CONSTRAINT zwierzeta_id_sektoru_fkey FOREIGN KEY (id_sektoru) REFERENCES public.sektor(id_sektoru);


--
-- PostgreSQL database dump complete
--

