--
-- PostgreSQL database dump
--

\restrict tl051tghSA3L7CGTKKxf9sgicsJPsYh1uE46DH0x6aWEVjiGh5cb6ePjq2VZT6D

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

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
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: carritos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.carritos (
    id integer NOT NULL,
    usuario_id integer NOT NULL
);


--
-- Name: carritos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.carritos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: carritos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.carritos_id_seq OWNED BY public.carritos.id;


--
-- Name: categorias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categorias (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion character varying(255),
    activo boolean NOT NULL
);


--
-- Name: categorias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categorias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categorias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categorias_id_seq OWNED BY public.categorias.id;


--
-- Name: colecciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.colecciones (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion character varying(255),
    activo boolean NOT NULL
);


--
-- Name: colecciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.colecciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colecciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.colecciones_id_seq OWNED BY public.colecciones.id;


--
-- Name: colores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.colores (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    codigo_hex character varying(7),
    activo boolean NOT NULL
);


--
-- Name: colores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.colores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.colores_id_seq OWNED BY public.colores.id;


--
-- Name: descuentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.descuentos (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    porcentaje numeric(5,2) NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: descuentos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.descuentos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: descuentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.descuentos_id_seq OWNED BY public.descuentos.id;


--
-- Name: detalles_carrito; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.detalles_carrito (
    id integer NOT NULL,
    carrito_id integer NOT NULL,
    variante_id integer NOT NULL,
    cantidad integer NOT NULL
);


--
-- Name: detalles_carrito_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.detalles_carrito_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: detalles_carrito_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.detalles_carrito_id_seq OWNED BY public.detalles_carrito.id;


--
-- Name: detalles_pedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.detalles_pedido (
    id integer NOT NULL,
    pedido_id integer NOT NULL,
    variante_id integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL
);


--
-- Name: detalles_pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.detalles_pedido_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: detalles_pedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.detalles_pedido_id_seq OWNED BY public.detalles_pedido.id;


--
-- Name: detalles_reserva; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.detalles_reserva (
    id integer NOT NULL,
    reserva_id integer NOT NULL,
    variante_id integer NOT NULL,
    cantidad integer NOT NULL
);


--
-- Name: detalles_reserva_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.detalles_reserva_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: detalles_reserva_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.detalles_reserva_id_seq OWNED BY public.detalles_reserva.id;


--
-- Name: devoluciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.devoluciones (
    id integer NOT NULL,
    pedido_id integer NOT NULL,
    variante_id integer NOT NULL,
    cantidad integer NOT NULL,
    motivo character varying(255) NOT NULL,
    estado character varying(30) NOT NULL,
    fecha_devolucion timestamp without time zone NOT NULL
);


--
-- Name: devoluciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.devoluciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: devoluciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.devoluciones_id_seq OWNED BY public.devoluciones.id;


--
-- Name: inventarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventarios (
    id integer NOT NULL,
    variante_id integer NOT NULL,
    sucursal_id integer NOT NULL,
    cantidad integer NOT NULL,
    cantidad_reservada integer NOT NULL
);


--
-- Name: inventarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventarios_id_seq OWNED BY public.inventarios.id;


--
-- Name: marcas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marcas (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion character varying(255),
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: marcas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marcas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marcas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marcas_id_seq OWNED BY public.marcas.id;


--
-- Name: notificaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notificaciones (
    id integer NOT NULL,
    usuario_id integer NOT NULL,
    titulo character varying(150) NOT NULL,
    mensaje character varying(500) NOT NULL,
    leida boolean NOT NULL,
    fecha_creacion timestamp without time zone NOT NULL
);


--
-- Name: notificaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notificaciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notificaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notificaciones_id_seq OWNED BY public.notificaciones.id;


--
-- Name: pagos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pagos (
    id integer NOT NULL,
    pedido_id integer NOT NULL,
    metodo character varying(30) NOT NULL,
    monto numeric(10,2) NOT NULL,
    estado character varying(30) NOT NULL,
    referencia character varying(150),
    fecha_pago timestamp without time zone
);


--
-- Name: pagos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pagos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pagos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pagos_id_seq OWNED BY public.pagos.id;


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedidos (
    id integer NOT NULL,
    usuario_id integer NOT NULL,
    fecha_pedido timestamp without time zone NOT NULL,
    estado character varying(30) NOT NULL,
    total numeric(10,2) NOT NULL
);


--
-- Name: pedidos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pedidos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pedidos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pedidos_id_seq OWNED BY public.pedidos.id;


--
-- Name: permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permisos (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion character varying(255) NOT NULL,
    activo boolean NOT NULL
);


--
-- Name: permisos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permisos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permisos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permisos_id_seq OWNED BY public.permisos.id;


--
-- Name: producto_variantes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.producto_variantes (
    id integer NOT NULL,
    producto_id integer NOT NULL,
    talla_id integer NOT NULL,
    color_id integer NOT NULL,
    activo boolean NOT NULL
);


--
-- Name: producto_variantes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.producto_variantes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: producto_variantes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.producto_variantes_id_seq OWNED BY public.producto_variantes.id;


--
-- Name: productos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.productos (
    id integer NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    precio numeric(10,2) NOT NULL,
    categoria_id integer NOT NULL,
    activo boolean NOT NULL,
    proveedor_id integer,
    temporada_id integer,
    coleccion_id integer,
    tipo_prenda_id integer,
    marca_id integer,
    descuento_id integer
);


--
-- Name: productos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.productos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: productos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.productos_id_seq OWNED BY public.productos.id;


--
-- Name: proveedores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proveedores (
    id integer NOT NULL,
    nombre character varying(150) NOT NULL,
    contacto character varying(100),
    telefono character varying(30),
    email character varying(150),
    direccion character varying(255),
    activo boolean NOT NULL
);


--
-- Name: proveedores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proveedores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: proveedores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proveedores_id_seq OWNED BY public.proveedores.id;


--
-- Name: reservas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservas (
    id integer NOT NULL,
    usuario_id integer NOT NULL,
    sucursal_id integer NOT NULL,
    fecha_reserva timestamp without time zone NOT NULL,
    estado character varying(30) NOT NULL,
    observaciones character varying(255)
);


--
-- Name: reservas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reservas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservas_id_seq OWNED BY public.reservas.id;


--
-- Name: rol_permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rol_permisos (
    id integer NOT NULL,
    rol character varying(30) NOT NULL,
    permiso_id integer NOT NULL
);


--
-- Name: rol_permisos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rol_permisos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rol_permisos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rol_permisos_id_seq OWNED BY public.rol_permisos.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre character varying(30) NOT NULL,
    descripcion character varying(150),
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: sucursales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sucursales (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    direccion character varying(255) NOT NULL,
    ciudad character varying(100) NOT NULL,
    telefono character varying(30),
    activo boolean NOT NULL
);


--
-- Name: sucursales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sucursales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sucursales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sucursales_id_seq OWNED BY public.sucursales.id;


--
-- Name: tallas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tallas (
    id integer NOT NULL,
    nombre character varying(20) NOT NULL,
    activo boolean NOT NULL
);


--
-- Name: tallas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tallas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tallas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tallas_id_seq OWNED BY public.tallas.id;


--
-- Name: temporadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.temporadas (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion character varying(255),
    activo boolean NOT NULL
);


--
-- Name: temporadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.temporadas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: temporadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.temporadas_id_seq OWNED BY public.temporadas.id;


--
-- Name: tipos_pago; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipos_pago (
    id integer NOT NULL,
    nombre character varying(30) NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: tipos_pago_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipos_pago_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_pago_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipos_pago_id_seq OWNED BY public.tipos_pago.id;


--
-- Name: tipos_prenda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipos_prenda (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion character varying(255),
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: tipos_prenda_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipos_prenda_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_prenda_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipos_prenda_id_seq OWNED BY public.tipos_prenda.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password_hash character varying(255) NOT NULL,
    activo boolean NOT NULL,
    fecha_creacion timestamp without time zone NOT NULL,
    rol character varying(30) NOT NULL
);


--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: carritos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carritos ALTER COLUMN id SET DEFAULT nextval('public.carritos_id_seq'::regclass);


--
-- Name: categorias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias ALTER COLUMN id SET DEFAULT nextval('public.categorias_id_seq'::regclass);


--
-- Name: colecciones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colecciones ALTER COLUMN id SET DEFAULT nextval('public.colecciones_id_seq'::regclass);


--
-- Name: colores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colores ALTER COLUMN id SET DEFAULT nextval('public.colores_id_seq'::regclass);


--
-- Name: descuentos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.descuentos ALTER COLUMN id SET DEFAULT nextval('public.descuentos_id_seq'::regclass);


--
-- Name: detalles_carrito id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_carrito ALTER COLUMN id SET DEFAULT nextval('public.detalles_carrito_id_seq'::regclass);


--
-- Name: detalles_pedido id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_pedido ALTER COLUMN id SET DEFAULT nextval('public.detalles_pedido_id_seq'::regclass);


--
-- Name: detalles_reserva id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_reserva ALTER COLUMN id SET DEFAULT nextval('public.detalles_reserva_id_seq'::regclass);


--
-- Name: devoluciones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devoluciones ALTER COLUMN id SET DEFAULT nextval('public.devoluciones_id_seq'::regclass);


--
-- Name: inventarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios ALTER COLUMN id SET DEFAULT nextval('public.inventarios_id_seq'::regclass);


--
-- Name: marcas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marcas ALTER COLUMN id SET DEFAULT nextval('public.marcas_id_seq'::regclass);


--
-- Name: notificaciones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificaciones ALTER COLUMN id SET DEFAULT nextval('public.notificaciones_id_seq'::regclass);


--
-- Name: pagos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos ALTER COLUMN id SET DEFAULT nextval('public.pagos_id_seq'::regclass);


--
-- Name: pedidos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN id SET DEFAULT nextval('public.pedidos_id_seq'::regclass);


--
-- Name: permisos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos ALTER COLUMN id SET DEFAULT nextval('public.permisos_id_seq'::regclass);


--
-- Name: producto_variantes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producto_variantes ALTER COLUMN id SET DEFAULT nextval('public.producto_variantes_id_seq'::regclass);


--
-- Name: productos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos ALTER COLUMN id SET DEFAULT nextval('public.productos_id_seq'::regclass);


--
-- Name: proveedores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedores ALTER COLUMN id SET DEFAULT nextval('public.proveedores_id_seq'::regclass);


--
-- Name: reservas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas ALTER COLUMN id SET DEFAULT nextval('public.reservas_id_seq'::regclass);


--
-- Name: rol_permisos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_permisos ALTER COLUMN id SET DEFAULT nextval('public.rol_permisos_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: sucursales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucursales ALTER COLUMN id SET DEFAULT nextval('public.sucursales_id_seq'::regclass);


--
-- Name: tallas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tallas ALTER COLUMN id SET DEFAULT nextval('public.tallas_id_seq'::regclass);


--
-- Name: temporadas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporadas ALTER COLUMN id SET DEFAULT nextval('public.temporadas_id_seq'::regclass);


--
-- Name: tipos_pago id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_pago ALTER COLUMN id SET DEFAULT nextval('public.tipos_pago_id_seq'::regclass);


--
-- Name: tipos_prenda id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_prenda ALTER COLUMN id SET DEFAULT nextval('public.tipos_prenda_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: carritos carritos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carritos
    ADD CONSTRAINT carritos_pkey PRIMARY KEY (id);


--
-- Name: categorias categorias_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_nombre_key UNIQUE (nombre);


--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- Name: colecciones colecciones_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colecciones
    ADD CONSTRAINT colecciones_nombre_key UNIQUE (nombre);


--
-- Name: colecciones colecciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colecciones
    ADD CONSTRAINT colecciones_pkey PRIMARY KEY (id);


--
-- Name: colores colores_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colores
    ADD CONSTRAINT colores_nombre_key UNIQUE (nombre);


--
-- Name: colores colores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colores
    ADD CONSTRAINT colores_pkey PRIMARY KEY (id);


--
-- Name: descuentos descuentos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.descuentos
    ADD CONSTRAINT descuentos_pkey PRIMARY KEY (id);


--
-- Name: detalles_carrito detalles_carrito_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_carrito
    ADD CONSTRAINT detalles_carrito_pkey PRIMARY KEY (id);


--
-- Name: detalles_pedido detalles_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_pedido
    ADD CONSTRAINT detalles_pedido_pkey PRIMARY KEY (id);


--
-- Name: detalles_reserva detalles_reserva_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_reserva
    ADD CONSTRAINT detalles_reserva_pkey PRIMARY KEY (id);


--
-- Name: devoluciones devoluciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devoluciones
    ADD CONSTRAINT devoluciones_pkey PRIMARY KEY (id);


--
-- Name: inventarios inventarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_pkey PRIMARY KEY (id);


--
-- Name: marcas marcas_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marcas
    ADD CONSTRAINT marcas_nombre_key UNIQUE (nombre);


--
-- Name: marcas marcas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marcas
    ADD CONSTRAINT marcas_pkey PRIMARY KEY (id);


--
-- Name: notificaciones notificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_pkey PRIMARY KEY (id);


--
-- Name: pagos pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (id);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);


--
-- Name: permisos permisos_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_nombre_key UNIQUE (nombre);


--
-- Name: permisos permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_pkey PRIMARY KEY (id);


--
-- Name: producto_variantes producto_variantes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producto_variantes
    ADD CONSTRAINT producto_variantes_pkey PRIMARY KEY (id);


--
-- Name: productos productos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_pkey PRIMARY KEY (id);


--
-- Name: proveedores proveedores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_pkey PRIMARY KEY (id);


--
-- Name: reservas reservas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas
    ADD CONSTRAINT reservas_pkey PRIMARY KEY (id);


--
-- Name: rol_permisos rol_permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_permisos
    ADD CONSTRAINT rol_permisos_pkey PRIMARY KEY (id);


--
-- Name: roles roles_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_nombre_key UNIQUE (nombre);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sucursales sucursales_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucursales
    ADD CONSTRAINT sucursales_nombre_key UNIQUE (nombre);


--
-- Name: sucursales sucursales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucursales
    ADD CONSTRAINT sucursales_pkey PRIMARY KEY (id);


--
-- Name: tallas tallas_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tallas
    ADD CONSTRAINT tallas_nombre_key UNIQUE (nombre);


--
-- Name: tallas tallas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tallas
    ADD CONSTRAINT tallas_pkey PRIMARY KEY (id);


--
-- Name: temporadas temporadas_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporadas
    ADD CONSTRAINT temporadas_nombre_key UNIQUE (nombre);


--
-- Name: temporadas temporadas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporadas
    ADD CONSTRAINT temporadas_pkey PRIMARY KEY (id);


--
-- Name: tipos_pago tipos_pago_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_pago
    ADD CONSTRAINT tipos_pago_nombre_key UNIQUE (nombre);


--
-- Name: tipos_pago tipos_pago_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_pago
    ADD CONSTRAINT tipos_pago_pkey PRIMARY KEY (id);


--
-- Name: tipos_prenda tipos_prenda_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_prenda
    ADD CONSTRAINT tipos_prenda_nombre_key UNIQUE (nombre);


--
-- Name: tipos_prenda tipos_prenda_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_prenda
    ADD CONSTRAINT tipos_prenda_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: ix_carritos_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_carritos_id ON public.carritos USING btree (id);


--
-- Name: ix_categorias_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_categorias_id ON public.categorias USING btree (id);


--
-- Name: ix_colecciones_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_colecciones_id ON public.colecciones USING btree (id);


--
-- Name: ix_colores_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_colores_id ON public.colores USING btree (id);


--
-- Name: ix_descuentos_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_descuentos_id ON public.descuentos USING btree (id);


--
-- Name: ix_detalles_carrito_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_detalles_carrito_id ON public.detalles_carrito USING btree (id);


--
-- Name: ix_detalles_pedido_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_detalles_pedido_id ON public.detalles_pedido USING btree (id);


--
-- Name: ix_detalles_reserva_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_detalles_reserva_id ON public.detalles_reserva USING btree (id);


--
-- Name: ix_devoluciones_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_devoluciones_id ON public.devoluciones USING btree (id);


--
-- Name: ix_inventarios_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventarios_id ON public.inventarios USING btree (id);


--
-- Name: ix_marcas_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_marcas_id ON public.marcas USING btree (id);


--
-- Name: ix_notificaciones_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notificaciones_id ON public.notificaciones USING btree (id);


--
-- Name: ix_pagos_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pagos_id ON public.pagos USING btree (id);


--
-- Name: ix_pedidos_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pedidos_id ON public.pedidos USING btree (id);


--
-- Name: ix_permisos_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_permisos_id ON public.permisos USING btree (id);


--
-- Name: ix_producto_variantes_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_producto_variantes_id ON public.producto_variantes USING btree (id);


--
-- Name: ix_productos_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_productos_id ON public.productos USING btree (id);


--
-- Name: ix_proveedores_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_proveedores_id ON public.proveedores USING btree (id);


--
-- Name: ix_reservas_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_reservas_id ON public.reservas USING btree (id);


--
-- Name: ix_rol_permisos_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_rol_permisos_id ON public.rol_permisos USING btree (id);


--
-- Name: ix_rol_permisos_rol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_rol_permisos_rol ON public.rol_permisos USING btree (rol);


--
-- Name: ix_roles_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_roles_id ON public.roles USING btree (id);


--
-- Name: ix_sucursales_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sucursales_id ON public.sucursales USING btree (id);


--
-- Name: ix_tallas_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tallas_id ON public.tallas USING btree (id);


--
-- Name: ix_temporadas_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_temporadas_id ON public.temporadas USING btree (id);


--
-- Name: ix_tipos_pago_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tipos_pago_id ON public.tipos_pago USING btree (id);


--
-- Name: ix_tipos_prenda_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tipos_prenda_id ON public.tipos_prenda USING btree (id);


--
-- Name: ix_usuarios_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_usuarios_email ON public.usuarios USING btree (email);


--
-- Name: ix_usuarios_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usuarios_id ON public.usuarios USING btree (id);


--
-- Name: carritos carritos_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carritos
    ADD CONSTRAINT carritos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: detalles_carrito detalles_carrito_carrito_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_carrito
    ADD CONSTRAINT detalles_carrito_carrito_id_fkey FOREIGN KEY (carrito_id) REFERENCES public.carritos(id);


--
-- Name: detalles_carrito detalles_carrito_variante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_carrito
    ADD CONSTRAINT detalles_carrito_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.producto_variantes(id);


--
-- Name: detalles_pedido detalles_pedido_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_pedido
    ADD CONSTRAINT detalles_pedido_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id);


--
-- Name: detalles_pedido detalles_pedido_variante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_pedido
    ADD CONSTRAINT detalles_pedido_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.producto_variantes(id);


--
-- Name: detalles_reserva detalles_reserva_reserva_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_reserva
    ADD CONSTRAINT detalles_reserva_reserva_id_fkey FOREIGN KEY (reserva_id) REFERENCES public.reservas(id);


--
-- Name: detalles_reserva detalles_reserva_variante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalles_reserva
    ADD CONSTRAINT detalles_reserva_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.producto_variantes(id);


--
-- Name: devoluciones devoluciones_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devoluciones
    ADD CONSTRAINT devoluciones_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id);


--
-- Name: devoluciones devoluciones_variante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devoluciones
    ADD CONSTRAINT devoluciones_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.producto_variantes(id);


--
-- Name: productos fk_productos_coleccion_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT fk_productos_coleccion_id FOREIGN KEY (coleccion_id) REFERENCES public.colecciones(id);


--
-- Name: productos fk_productos_descuento_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT fk_productos_descuento_id FOREIGN KEY (descuento_id) REFERENCES public.descuentos(id);


--
-- Name: productos fk_productos_marca_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT fk_productos_marca_id FOREIGN KEY (marca_id) REFERENCES public.marcas(id);


--
-- Name: productos fk_productos_proveedor_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT fk_productos_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES public.proveedores(id);


--
-- Name: productos fk_productos_temporada_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT fk_productos_temporada_id FOREIGN KEY (temporada_id) REFERENCES public.temporadas(id);


--
-- Name: productos fk_productos_tipo_prenda_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT fk_productos_tipo_prenda_id FOREIGN KEY (tipo_prenda_id) REFERENCES public.tipos_prenda(id);


--
-- Name: inventarios inventarios_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES public.sucursales(id);


--
-- Name: inventarios inventarios_variante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.producto_variantes(id);


--
-- Name: notificaciones notificaciones_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: pagos pagos_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id);


--
-- Name: pedidos pedidos_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: producto_variantes producto_variantes_color_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producto_variantes
    ADD CONSTRAINT producto_variantes_color_id_fkey FOREIGN KEY (color_id) REFERENCES public.colores(id);


--
-- Name: producto_variantes producto_variantes_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producto_variantes
    ADD CONSTRAINT producto_variantes_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(id);


--
-- Name: producto_variantes producto_variantes_talla_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producto_variantes
    ADD CONSTRAINT producto_variantes_talla_id_fkey FOREIGN KEY (talla_id) REFERENCES public.tallas(id);


--
-- Name: productos productos_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categorias(id);


--
-- Name: reservas reservas_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas
    ADD CONSTRAINT reservas_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES public.sucursales(id);


--
-- Name: reservas reservas_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas
    ADD CONSTRAINT reservas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: rol_permisos rol_permisos_permiso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_permisos
    ADD CONSTRAINT rol_permisos_permiso_id_fkey FOREIGN KEY (permiso_id) REFERENCES public.permisos(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict tl051tghSA3L7CGTKKxf9sgicsJPsYh1uE46DH0x6aWEVjiGh5cb6ePjq2VZT6D

