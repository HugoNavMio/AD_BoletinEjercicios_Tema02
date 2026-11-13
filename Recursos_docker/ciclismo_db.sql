
-- Base de datos de ciclismo (esquema 'public') - tiempos corregidos por posición
-- Archivo generado el 2025-10-30

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_etapa') THEN
        CREATE TYPE tipo_etapa AS ENUM ('Llana','Quebrada','Montaña','CRI','CRE');
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_resultado') THEN
        CREATE TYPE estado_resultado AS ENUM ('FINALIZADO','DNF','DNS','DSQ');
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'categoria_puerto') THEN
        CREATE TYPE categoria_puerto AS ENUM ('HC','1','2','3','4');
    END IF;
END $$;

CREATE TABLE equipos (
    id_equipo SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    pais   TEXT NOT NULL
);
CREATE TABLE ciclistas (
    id_ciclista SERIAL PRIMARY KEY,
    id_equipo   INT NOT NULL REFERENCES equipos(id_equipo) ON DELETE RESTRICT,
    nombre      TEXT NOT NULL,
    pais        TEXT NOT NULL,
    fecha_nac   DATE NOT NULL,
    UNIQUE (nombre, fecha_nac)
);
CREATE TABLE carreras (
    id_carrera  SERIAL PRIMARY KEY,
    nombre      TEXT NOT NULL,
    anio        INT NOT NULL CHECK (anio BETWEEN 1990 AND 2100),
    fecha_inicio DATE NOT NULL,
    fecha_fin    DATE NOT NULL,
    UNIQUE (nombre, anio),
    CHECK (fecha_fin >= fecha_inicio)
);
CREATE TABLE etapas (
    id_etapa   SERIAL PRIMARY KEY,
    id_carrera INT NOT NULL REFERENCES carreras(id_carrera) ON DELETE CASCADE,
    num_etapa  INT NOT NULL CHECK (num_etapa >= 1),
    fecha      DATE NOT NULL,
    salida     TEXT NOT NULL,
    llegada    TEXT NOT NULL,
    distancia_km NUMERIC(6,2) NOT NULL CHECK (distancia_km > 0),
    tipo       tipo_etapa NOT NULL,
    UNIQUE (id_carrera, num_etapa)
);
CREATE OR REPLACE FUNCTION trg_valida_fecha_etapa_fn() RETURNS TRIGGER AS $$
DECLARE f_ini DATE; f_fin DATE;
BEGIN
  SELECT fecha_inicio, fecha_fin INTO f_ini, f_fin FROM carreras WHERE id_carrera = NEW.id_carrera;
  IF f_ini IS NULL THEN RAISE EXCEPTION 'Carrera % no existe', NEW.id_carrera USING ERRCODE='23503'; END IF;
  IF NOT (NEW.fecha BETWEEN f_ini AND f_fin) THEN
    RAISE EXCEPTION 'Fecha de etapa % fuera del rango [% - %] para carrera %',
      NEW.fecha, f_ini, f_fin, NEW.id_carrera USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_valida_fecha_etapa BEFORE INSERT OR UPDATE ON etapas
FOR EACH ROW EXECUTE FUNCTION trg_valida_fecha_etapa_fn();

CREATE TABLE resultados_etapa (
    id_etapa    INT NOT NULL REFERENCES etapas(id_etapa) ON DELETE CASCADE,
    id_ciclista INT NOT NULL REFERENCES ciclistas(id_ciclista) ON DELETE CASCADE,
    posicion    INT CHECK (posicion IS NULL OR posicion >= 1),
    tiempo      INTERVAL,
    diferencia  INTERVAL,
    estado      estado_resultado NOT NULL DEFAULT 'FINALIZADO',
    PRIMARY KEY (id_etapa, id_ciclista),
    CHECK ( (estado <> 'FINALIZADO' AND tiempo IS NULL AND posicion IS NULL)
         OR (estado = 'FINALIZADO' AND tiempo IS NOT NULL AND posicion IS NOT NULL) )
);
CREATE TABLE sprints (
    id_sprint  SERIAL PRIMARY KEY,
    id_etapa   INT NOT NULL REFERENCES etapas(id_etapa) ON DELETE CASCADE,
    km         NUMERIC(6,2) NOT NULL CHECK (km >= 0),
    UNIQUE (id_etapa, km)
);
CREATE TABLE resultados_sprint (
    id_sprint   INT NOT NULL REFERENCES sprints(id_sprint) ON DELETE CASCADE,
    id_ciclista INT NOT NULL REFERENCES ciclistas(id_ciclista) ON DELETE CASCADE,
    posicion    INT NOT NULL CHECK (posicion >= 1),
    puntos      INT NOT NULL CHECK (puntos >= 0),
    PRIMARY KEY (id_sprint, id_ciclista),
    UNIQUE (id_sprint, posicion)
);
CREATE TABLE puntos_meta (
    id_etapa    INT NOT NULL REFERENCES etapas(id_etapa) ON DELETE CASCADE,
    id_ciclista INT NOT NULL REFERENCES ciclistas(id_ciclista) ON DELETE CASCADE,
    posicion    INT NOT NULL CHECK (posicion >= 1),
    puntos      INT NOT NULL CHECK (puntos >= 0),
    PRIMARY KEY (id_etapa, id_ciclista),
    UNIQUE (id_etapa, posicion)
);
CREATE TABLE puertos (
    id_puerto  SERIAL PRIMARY KEY,
    id_etapa   INT NOT NULL REFERENCES etapas(id_etapa) ON DELETE CASCADE,
    nombre     TEXT NOT NULL,
    km         NUMERIC(6,2) NOT NULL CHECK (km >= 0),
    categoria  categoria_puerto NOT NULL,
    UNIQUE (id_etapa, nombre)
);
CREATE TABLE resultados_puerto (
    id_puerto   INT NOT NULL REFERENCES puertos(id_puerto) ON DELETE CASCADE,
    id_ciclista INT NOT NULL REFERENCES ciclistas(id_ciclista) ON DELETE CASCADE,
    posicion    INT NOT NULL CHECK (posicion >= 1),
    puntos      INT NOT NULL CHECK (puntos >= 0),
    PRIMARY KEY (id_puerto, id_ciclista),
    UNIQUE (id_puerto, posicion)
);
CREATE INDEX idx_ciclistas_equipo ON ciclistas(id_equipo);
CREATE INDEX idx_resultados_etapa_etapa ON resultados_etapa(id_etapa);
CREATE INDEX idx_resultados_etapa_ciclista ON resultados_etapa(id_ciclista);
CREATE INDEX idx_resultados_sprint_ciclista ON resultados_sprint(id_ciclista);
CREATE INDEX idx_puntos_meta_ciclista ON puntos_meta(id_ciclista);
CREATE INDEX idx_resultados_puerto_ciclista ON resultados_puerto(id_ciclista);

-- Equipos
INSERT INTO equipos (nombre, pais) VALUES
('Iberia Pro Cycling', 'ESP'),
('AlpenStars', 'SUI'),
('Nordic Hammer', 'NOR'),
('Blue Coast Racing', 'POR'),
('Gaul Vélocité', 'FRA'),
('Teutonic Wheels', 'GER'),
('Azzurri Sprint', 'ITA');

-- Ciclistas
INSERT INTO ciclistas (id_equipo, nombre, pais, fecha_nac) VALUES
(1, 'Carlos Ruiz', 'ESP', '1994-01-01'),
(1, 'Miguel Santos', 'ESP', '1995-02-02'),
(1, 'Javier León', 'ESP', '1996-03-03'),
(1, 'Óscar Vega', 'ESP', '1997-04-04'),
(1, 'Adrián Flores', 'ESP', '1998-05-05'),
(1, 'Pablo Núñez', 'ESP', '1999-06-06'),
(1, 'Sergio Arias', 'ESP', '1994-07-07'),
(2, 'Lukas Meier', 'SUI', '1994-01-01'),
(2, 'Noah Schmid', 'SUI', '1995-02-02'),
(2, 'Fabian Keller', 'SUI', '1996-03-03'),
(2, 'Timo Vogel', 'GER', '1997-04-04'),
(2, 'Jonas Ritter', 'SUI', '1998-05-05'),
(2, 'Marco Lüthi', 'SUI', '1999-06-06'),
(2, 'Sven Albrecht', 'GER', '1994-07-07'),
(3, 'Erik Johansen', 'NOR', '1994-01-01'),
(3, 'Mats Solberg', 'NOR', '1995-02-02'),
(3, 'Henrik Nilsen', 'NOR', '1996-03-03'),
(3, 'Sindre Aas', 'NOR', '1997-04-04'),
(3, 'Kasper Lunde', 'NOR', '1998-05-05'),
(3, 'Tobias Hauge', 'NOR', '1999-06-06'),
(3, 'Lars Eik', 'NOR', '1994-07-07'),
(4, 'Tiago Mendes', 'POR', '1994-01-01'),
(4, 'Rui Carvalho', 'POR', '1995-02-02'),
(4, 'Diogo Rocha', 'POR', '1996-03-03'),
(4, 'Pedro Faria', 'POR', '1997-04-04'),
(4, 'André Reis', 'POR', '1998-05-05'),
(4, 'Hugo Teixeira', 'POR', '1999-06-06'),
(4, 'Nuno Duarte', 'POR', '1994-07-07'),
(5, 'Louis Martin', 'FRA', '1994-01-01'),
(5, 'Thomas Dubois', 'FRA', '1995-02-02'),
(5, 'Antoine Leroy', 'FRA', '1996-03-03'),
(5, 'Julien Garnier', 'FRA', '1997-04-04'),
(5, 'Hugo Robert', 'FRA', '1998-05-05'),
(5, 'Nicolas Bernard', 'FRA', '1999-06-06'),
(5, 'Paul Fontaine', 'FRA', '1994-07-07'),
(6, 'Felix Weber', 'GER', '1994-01-01'),
(6, 'Moritz Braun', 'GER', '1995-02-02'),
(6, 'Leon Fischer', 'GER', '1996-03-03'),
(6, 'Jan Richter', 'GER', '1997-04-04'),
(6, 'Klaus Hofmann', 'GER', '1998-05-05'),
(6, 'Timo Berg', 'GER', '1999-06-06'),
(6, 'Arne Beck', 'GER', '1994-07-07'),
(7, 'Marco Bianchi', 'ITA', '1994-01-01'),
(7, 'Luca Moretti', 'ITA', '1995-02-02'),
(7, 'Giovanni Conti', 'ITA', '1996-03-03'),
(7, 'Andrea Rizzi', 'ITA', '1997-04-04'),
(7, 'Riccardo Sala', 'ITA', '1998-05-05'),
(7, 'Davide Neri', 'ITA', '1999-06-06'),
(7, 'Tommaso Galli', 'ITA', '1994-07-07');

INSERT INTO carreras (nombre, anio, fecha_inicio, fecha_fin) VALUES
('Vuelta Atlántica', 2025, '2025-05-01', '2025-05-14');

-- Etapas
INSERT INTO etapas (id_carrera, num_etapa, fecha, salida, llegada, distancia_km, tipo) VALUES
(1, 1, '2025-05-01', 'Lisboa', 'Setúbal', 168.00, 'Llana'),
(1, 2, '2025-05-02', 'Setúbal', 'Évora', 182.00, 'Quebrada'),
(1, 3, '2025-05-03', 'Évora', 'Beja', 160.00, 'Llana'),
(1, 4, '2025-05-04', 'Beja', 'Faro', 175.00, 'Quebrada'),
(1, 5, '2025-05-05', 'Faro', 'Portimão', 190.00, 'Montaña'),
(1, 6, '2025-05-06', 'Portimão', 'Lagos', 155.00, 'Llana'),
(1, 7, '2025-05-07', 'Lagos', 'Sagres', 40.00, 'CRI'),
(1, 8, '2025-05-08', 'Sagres', 'Sines', 170.00, 'Quebrada'),
(1, 9, '2025-05-09', 'Sines', 'Setúbal', 165.00, 'Llana'),
(1, 10, '2025-05-10', 'Setúbal', 'Lisboa', 192.00, 'Montaña'),
(1, 11, '2025-05-11', 'Lisboa', 'Sintra', 178.00, 'Quebrada'),
(1, 12, '2025-05-12', 'Sintra', 'Mafra', 150.00, 'Llana'),
(1, 13, '2025-05-13', 'Mafra', 'Torres Vedras', 158.00, 'Llana'),
(1, 14, '2025-05-14', 'Torres Vedras', 'Caldas da Rainha', 184.00, 'Quebrada');

-- Resultados de etapa y puntos de meta
INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(1, 1, 1, '03:50:00', '00:00:00', 'FINALIZADO'),
(1, 2, 2, '03:50:01', '00:00:01', 'FINALIZADO'),
(1, 3, 3, '03:50:02', '00:00:02', 'FINALIZADO'),
(1, 4, 4, '03:50:03', '00:00:03', 'FINALIZADO'),
(1, 5, 5, '03:50:04', '00:00:04', 'FINALIZADO'),
(1, 6, 6, '03:50:05', '00:00:05', 'FINALIZADO'),
(1, 7, 7, '03:50:06', '00:00:06', 'FINALIZADO'),
(1, 8, 8, '03:50:07', '00:00:07', 'FINALIZADO'),
(1, 9, 9, '03:50:08', '00:00:08', 'FINALIZADO'),
(1, 10, 10, '03:50:09', '00:00:09', 'FINALIZADO'),
(1, 11, 11, '03:50:10', '00:00:10', 'FINALIZADO'),
(1, 12, 12, '03:50:11', '00:00:11', 'FINALIZADO'),
(1, 13, 13, '03:50:12', '00:00:12', 'FINALIZADO'),
(1, 14, 14, '03:50:13', '00:00:13', 'FINALIZADO'),
(1, 15, 15, '03:50:14', '00:00:14', 'FINALIZADO'),
(1, 16, 16, '03:50:15', '00:00:15', 'FINALIZADO'),
(1, 17, 17, '03:50:16', '00:00:16', 'FINALIZADO'),
(1, 18, 18, '03:50:17', '00:00:17', 'FINALIZADO'),
(1, 19, 19, '03:50:18', '00:00:18', 'FINALIZADO'),
(1, 20, 20, '03:50:19', '00:00:19', 'FINALIZADO'),
(1, 21, 21, '03:50:21', '00:00:21', 'FINALIZADO'),
(1, 22, 22, '03:50:22', '00:00:22', 'FINALIZADO'),
(1, 23, 23, '03:50:23', '00:00:23', 'FINALIZADO'),
(1, 24, 24, '03:50:24', '00:00:24', 'FINALIZADO'),
(1, 25, 25, '03:50:25', '00:00:25', 'FINALIZADO'),
(1, 26, 26, '03:50:26', '00:00:26', 'FINALIZADO'),
(1, 27, 27, '03:50:27', '00:00:27', 'FINALIZADO'),
(1, 28, 28, '03:50:28', '00:00:28', 'FINALIZADO'),
(1, 29, 29, '03:50:29', '00:00:29', 'FINALIZADO'),
(1, 30, 30, '03:50:30', '00:00:30', 'FINALIZADO'),
(1, 31, 31, '03:50:31', '00:00:31', 'FINALIZADO'),
(1, 32, 32, '03:50:32', '00:00:32', 'FINALIZADO'),
(1, 33, 33, '03:50:33', '00:00:33', 'FINALIZADO'),
(1, 34, 34, '03:50:34', '00:00:34', 'FINALIZADO'),
(1, 35, 35, '03:50:35', '00:00:35', 'FINALIZADO'),
(1, 36, 36, '03:50:36', '00:00:36', 'FINALIZADO'),
(1, 37, 37, '03:50:37', '00:00:37', 'FINALIZADO'),
(1, 38, 38, '03:50:38', '00:00:38', 'FINALIZADO'),
(1, 39, 39, '03:50:39', '00:00:39', 'FINALIZADO'),
(1, 40, 40, '03:50:40', '00:00:40', 'FINALIZADO'),
(1, 41, 41, '03:50:42', '00:00:42', 'FINALIZADO'),
(1, 42, 42, '03:50:43', '00:00:43', 'FINALIZADO'),
(1, 43, 43, '03:50:44', '00:00:44', 'FINALIZADO'),
(1, 44, 44, '03:50:45', '00:00:45', 'FINALIZADO'),
(1, 45, 45, '03:50:46', '00:00:46', 'FINALIZADO'),
(1, 46, 46, '03:50:47', '00:00:47', 'FINALIZADO'),
(1, 47, 47, '03:50:48', '00:00:48', 'FINALIZADO'),
(1, 48, 48, '03:50:49', '00:00:49', 'FINALIZADO'),
(1, 49, 49, '03:50:50', '00:00:50', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(2, 8, 1, '04:25:00', '00:00:00', 'FINALIZADO'),
(2, 9, 2, '04:25:01', '00:00:01', 'FINALIZADO'),
(2, 10, 3, '04:25:02', '00:00:02', 'FINALIZADO'),
(2, 11, 4, '04:25:03', '00:00:03', 'FINALIZADO'),
(2, 12, 5, '04:25:04', '00:00:04', 'FINALIZADO'),
(2, 13, 6, '04:25:05', '00:00:05', 'FINALIZADO'),
(2, 14, 7, '04:25:06', '00:00:06', 'FINALIZADO'),
(2, 15, 8, '04:25:07', '00:00:07', 'FINALIZADO'),
(2, 16, 9, '04:25:08', '00:00:08', 'FINALIZADO'),
(2, 17, 10, '04:25:09', '00:00:09', 'FINALIZADO'),
(2, 18, 11, '04:25:10', '00:00:10', 'FINALIZADO'),
(2, 19, 12, '04:25:11', '00:00:11', 'FINALIZADO'),
(2, 20, 13, '04:25:13', '00:00:13', 'FINALIZADO'),
(2, 21, 14, '04:25:14', '00:00:14', 'FINALIZADO'),
(2, 22, 15, '04:25:15', '00:00:15', 'FINALIZADO'),
(2, 23, 16, '04:25:16', '00:00:16', 'FINALIZADO'),
(2, 24, 17, '04:25:17', '00:00:17', 'FINALIZADO'),
(2, 25, 18, '04:25:18', '00:00:18', 'FINALIZADO'),
(2, 26, 19, '04:25:19', '00:00:19', 'FINALIZADO'),
(2, 27, 20, '04:25:20', '00:00:20', 'FINALIZADO'),
(2, 28, 21, '04:25:21', '00:00:21', 'FINALIZADO'),
(2, 29, 22, '04:25:22', '00:00:22', 'FINALIZADO'),
(2, 30, 23, '04:25:23', '00:00:23', 'FINALIZADO'),
(2, 31, 24, '04:25:24', '00:00:24', 'FINALIZADO'),
(2, 32, 25, '04:25:26', '00:00:26', 'FINALIZADO'),
(2, 33, 26, '04:25:27', '00:00:27', 'FINALIZADO'),
(2, 34, 27, '04:25:28', '00:00:28', 'FINALIZADO'),
(2, 35, 28, '04:25:29', '00:00:29', 'FINALIZADO'),
(2, 36, 29, '04:25:30', '00:00:30', 'FINALIZADO'),
(2, 37, 30, '04:25:31', '00:00:31', 'FINALIZADO'),
(2, 38, 31, '04:25:32', '00:00:32', 'FINALIZADO'),
(2, 39, 32, '04:25:33', '00:00:33', 'FINALIZADO'),
(2, 40, 33, '04:25:34', '00:00:34', 'FINALIZADO'),
(2, 41, 34, '04:25:35', '00:00:35', 'FINALIZADO'),
(2, 42, 35, '04:25:36', '00:00:36', 'FINALIZADO'),
(2, 43, 36, '04:25:37', '00:00:37', 'FINALIZADO'),
(2, 44, 37, '04:25:39', '00:00:39', 'FINALIZADO'),
(2, 45, 38, '04:25:40', '00:00:40', 'FINALIZADO'),
(2, 46, 39, '04:25:41', '00:00:41', 'FINALIZADO'),
(2, 47, 40, '04:25:42', '00:00:42', 'FINALIZADO'),
(2, 48, 41, '04:25:43', '00:00:43', 'FINALIZADO'),
(2, 49, 42, '04:25:44', '00:00:44', 'FINALIZADO'),
(2, 1, 43, '04:25:45', '00:00:45', 'FINALIZADO'),
(2, 2, 44, '04:25:46', '00:00:46', 'FINALIZADO'),
(2, 3, 45, '04:25:47', '00:00:47', 'FINALIZADO'),
(2, 4, 46, '04:25:48', '00:00:48', 'FINALIZADO'),
(2, 5, 47, '04:25:49', '00:00:49', 'FINALIZADO'),
(2, 6, 48, '04:25:50', '00:00:50', 'FINALIZADO'),
(2, 7, 49, '04:25:52', '00:00:52', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(3, 15, 1, '03:55:00', '00:00:00', 'FINALIZADO'),
(3, 16, 2, '03:55:01', '00:00:01', 'FINALIZADO'),
(3, 17, 3, '03:55:02', '00:00:02', 'FINALIZADO'),
(3, 18, 4, '03:55:03', '00:00:03', 'FINALIZADO'),
(3, 19, 5, '03:55:04', '00:00:04', 'FINALIZADO'),
(3, 20, 6, '03:55:05', '00:00:05', 'FINALIZADO'),
(3, 21, 7, '03:55:06', '00:00:06', 'FINALIZADO'),
(3, 22, 8, '03:55:07', '00:00:07', 'FINALIZADO'),
(3, 23, 9, '03:55:08', '00:00:08', 'FINALIZADO'),
(3, 24, 10, '03:55:09', '00:00:09', 'FINALIZADO'),
(3, 25, 11, '03:55:10', '00:00:10', 'FINALIZADO'),
(3, 26, 12, '03:55:11', '00:00:11', 'FINALIZADO'),
(3, 27, 13, '03:55:12', '00:00:12', 'FINALIZADO'),
(3, 28, 14, '03:55:13', '00:00:13', 'FINALIZADO'),
(3, 29, 15, '03:55:14', '00:00:14', 'FINALIZADO'),
(3, 30, 16, '03:55:15', '00:00:15', 'FINALIZADO'),
(3, 31, 17, '03:55:16', '00:00:16', 'FINALIZADO'),
(3, 32, 18, '03:55:17', '00:00:17', 'FINALIZADO'),
(3, 33, 19, '03:55:18', '00:00:18', 'FINALIZADO'),
(3, 34, 20, '03:55:19', '00:00:19', 'FINALIZADO'),
(3, 35, 21, '03:55:21', '00:00:21', 'FINALIZADO'),
(3, 36, 22, '03:55:22', '00:00:22', 'FINALIZADO'),
(3, 37, 23, '03:55:23', '00:00:23', 'FINALIZADO'),
(3, 38, 24, '03:55:24', '00:00:24', 'FINALIZADO'),
(3, 39, 25, '03:55:25', '00:00:25', 'FINALIZADO'),
(3, 40, 26, '03:55:26', '00:00:26', 'FINALIZADO'),
(3, 41, 27, '03:55:27', '00:00:27', 'FINALIZADO'),
(3, 42, 28, '03:55:28', '00:00:28', 'FINALIZADO'),
(3, 43, 29, '03:55:29', '00:00:29', 'FINALIZADO'),
(3, 44, 30, '03:55:30', '00:00:30', 'FINALIZADO'),
(3, 45, 31, '03:55:31', '00:00:31', 'FINALIZADO'),
(3, 46, 32, '03:55:32', '00:00:32', 'FINALIZADO'),
(3, 47, 33, '03:55:33', '00:00:33', 'FINALIZADO'),
(3, 48, 34, '03:55:34', '00:00:34', 'FINALIZADO'),
(3, 49, 35, '03:55:35', '00:00:35', 'FINALIZADO'),
(3, 1, 36, '03:55:36', '00:00:36', 'FINALIZADO'),
(3, 2, 37, '03:55:37', '00:00:37', 'FINALIZADO'),
(3, 3, 38, '03:55:38', '00:00:38', 'FINALIZADO'),
(3, 4, 39, '03:55:39', '00:00:39', 'FINALIZADO'),
(3, 5, 40, '03:55:40', '00:00:40', 'FINALIZADO'),
(3, 6, 41, '03:55:42', '00:00:42', 'FINALIZADO'),
(3, 7, 42, '03:55:43', '00:00:43', 'FINALIZADO'),
(3, 8, 43, '03:55:44', '00:00:44', 'FINALIZADO'),
(3, 9, 44, '03:55:45', '00:00:45', 'FINALIZADO'),
(3, 10, 45, '03:55:46', '00:00:46', 'FINALIZADO'),
(3, 11, 46, '03:55:47', '00:00:47', 'FINALIZADO'),
(3, 12, 47, '03:55:48', '00:00:48', 'FINALIZADO'),
(3, 13, 48, '03:55:49', '00:00:49', 'FINALIZADO'),
(3, 14, 49, '03:55:50', '00:00:50', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(4, 22, 1, '04:20:00', '00:00:00', 'FINALIZADO'),
(4, 23, 2, '04:20:01', '00:00:01', 'FINALIZADO'),
(4, 24, 3, '04:20:02', '00:00:02', 'FINALIZADO'),
(4, 25, 4, '04:20:03', '00:00:03', 'FINALIZADO'),
(4, 26, 5, '04:20:04', '00:00:04', 'FINALIZADO'),
(4, 27, 6, '04:20:05', '00:00:05', 'FINALIZADO'),
(4, 28, 7, '04:20:06', '00:00:06', 'FINALIZADO'),
(4, 29, 8, '04:20:07', '00:00:07', 'FINALIZADO'),
(4, 30, 9, '04:20:08', '00:00:08', 'FINALIZADO'),
(4, 31, 10, '04:20:09', '00:00:09', 'FINALIZADO'),
(4, 32, 11, '04:20:10', '00:00:10', 'FINALIZADO'),
(4, 33, 12, '04:20:11', '00:00:11', 'FINALIZADO'),
(4, 34, 13, '04:20:13', '00:00:13', 'FINALIZADO'),
(4, 35, 14, '04:20:14', '00:00:14', 'FINALIZADO'),
(4, 36, 15, '04:20:15', '00:00:15', 'FINALIZADO'),
(4, 37, 16, '04:20:16', '00:00:16', 'FINALIZADO'),
(4, 38, 17, '04:20:17', '00:00:17', 'FINALIZADO'),
(4, 39, 18, '04:20:18', '00:00:18', 'FINALIZADO'),
(4, 40, 19, '04:20:19', '00:00:19', 'FINALIZADO'),
(4, 41, 20, '04:20:20', '00:00:20', 'FINALIZADO'),
(4, 42, 21, '04:20:21', '00:00:21', 'FINALIZADO'),
(4, 43, 22, '04:20:22', '00:00:22', 'FINALIZADO'),
(4, 44, 23, '04:20:23', '00:00:23', 'FINALIZADO'),
(4, 45, 24, '04:20:24', '00:00:24', 'FINALIZADO'),
(4, 46, 25, '04:20:26', '00:00:26', 'FINALIZADO'),
(4, 47, 26, '04:20:27', '00:00:27', 'FINALIZADO'),
(4, 48, 27, '04:20:28', '00:00:28', 'FINALIZADO'),
(4, 49, 28, '04:20:29', '00:00:29', 'FINALIZADO'),
(4, 1, 29, '04:20:30', '00:00:30', 'FINALIZADO'),
(4, 2, 30, '04:20:31', '00:00:31', 'FINALIZADO'),
(4, 3, 31, '04:20:32', '00:00:32', 'FINALIZADO'),
(4, 4, 32, '04:20:33', '00:00:33', 'FINALIZADO'),
(4, 5, 33, '04:20:34', '00:00:34', 'FINALIZADO'),
(4, 6, 34, '04:20:35', '00:00:35', 'FINALIZADO'),
(4, 7, 35, '04:20:36', '00:00:36', 'FINALIZADO'),
(4, 8, 36, '04:20:37', '00:00:37', 'FINALIZADO'),
(4, 9, 37, '04:20:39', '00:00:39', 'FINALIZADO'),
(4, 10, 38, '04:20:40', '00:00:40', 'FINALIZADO'),
(4, 11, 39, '04:20:41', '00:00:41', 'FINALIZADO'),
(4, 12, 40, '04:20:42', '00:00:42', 'FINALIZADO'),
(4, 13, 41, '04:20:43', '00:00:43', 'FINALIZADO'),
(4, 14, 42, '04:20:44', '00:00:44', 'FINALIZADO'),
(4, 15, 43, '04:20:45', '00:00:45', 'FINALIZADO'),
(4, 16, 44, '04:20:46', '00:00:46', 'FINALIZADO'),
(4, 17, 45, '04:20:47', '00:00:47', 'FINALIZADO'),
(4, 18, 46, '04:20:48', '00:00:48', 'FINALIZADO'),
(4, 19, 47, '04:20:49', '00:00:49', 'FINALIZADO'),
(4, 20, 48, '04:20:50', '00:00:50', 'FINALIZADO'),
(4, 21, 49, '04:20:52', '00:00:52', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(5, 29, 1, '04:40:00', '00:00:00', 'FINALIZADO'),
(5, 30, 2, '04:40:01', '00:00:01', 'FINALIZADO'),
(5, 31, 3, '04:40:02', '00:00:02', 'FINALIZADO'),
(5, 32, 4, '04:40:03', '00:00:03', 'FINALIZADO'),
(5, 33, 5, '04:40:04', '00:00:04', 'FINALIZADO'),
(5, 34, 6, '04:40:05', '00:00:05', 'FINALIZADO'),
(5, 35, 7, '04:40:06', '00:00:06', 'FINALIZADO'),
(5, 36, 8, '04:40:07', '00:00:07', 'FINALIZADO'),
(5, 37, 9, '04:40:10', '00:00:10', 'FINALIZADO'),
(5, 38, 10, '04:40:11', '00:00:11', 'FINALIZADO'),
(5, 39, 11, '04:40:12', '00:00:12', 'FINALIZADO'),
(5, 40, 12, '04:40:13', '00:00:13', 'FINALIZADO'),
(5, 41, 13, '04:40:14', '00:00:14', 'FINALIZADO'),
(5, 42, 14, '04:40:15', '00:00:15', 'FINALIZADO'),
(5, 43, 15, '04:40:16', '00:00:16', 'FINALIZADO'),
(5, 44, 16, '04:40:17', '00:00:17', 'FINALIZADO'),
(5, 45, 17, '04:40:20', '00:00:20', 'FINALIZADO'),
(5, 46, 18, '04:40:21', '00:00:21', 'FINALIZADO'),
(5, 47, 19, '04:40:22', '00:00:22', 'FINALIZADO'),
(5, 48, 20, '04:40:23', '00:00:23', 'FINALIZADO'),
(5, 49, 21, '04:40:24', '00:00:24', 'FINALIZADO'),
(5, 1, 22, '04:40:25', '00:00:25', 'FINALIZADO'),
(5, 2, 23, '04:40:26', '00:00:26', 'FINALIZADO'),
(5, 3, 24, '04:40:27', '00:00:27', 'FINALIZADO'),
(5, 4, 25, '04:40:30', '00:00:30', 'FINALIZADO'),
(5, 5, 26, '04:40:31', '00:00:31', 'FINALIZADO'),
(5, 6, 27, '04:40:32', '00:00:32', 'FINALIZADO'),
(5, 7, 28, '04:40:33', '00:00:33', 'FINALIZADO'),
(5, 8, 29, '04:40:34', '00:00:34', 'FINALIZADO'),
(5, 9, 30, '04:40:35', '00:00:35', 'FINALIZADO'),
(5, 10, 31, '04:40:36', '00:00:36', 'FINALIZADO'),
(5, 11, 32, '04:40:37', '00:00:37', 'FINALIZADO'),
(5, 12, 33, '04:40:40', '00:00:40', 'FINALIZADO'),
(5, 13, 34, '04:40:41', '00:00:41', 'FINALIZADO'),
(5, 14, 35, '04:40:42', '00:00:42', 'FINALIZADO'),
(5, 15, 36, '04:40:43', '00:00:43', 'FINALIZADO'),
(5, 16, 37, '04:40:44', '00:00:44', 'FINALIZADO'),
(5, 17, 38, '04:40:45', '00:00:45', 'FINALIZADO'),
(5, 18, 39, '04:40:46', '00:00:46', 'FINALIZADO'),
(5, 19, 40, '04:40:47', '00:00:47', 'FINALIZADO'),
(5, 20, 41, '04:40:50', '00:00:50', 'FINALIZADO'),
(5, 21, 42, '04:40:51', '00:00:51', 'FINALIZADO'),
(5, 22, 43, '04:40:52', '00:00:52', 'FINALIZADO'),
(5, 23, 44, '04:40:53', '00:00:53', 'FINALIZADO'),
(5, 24, 45, '04:40:54', '00:00:54', 'FINALIZADO'),
(5, 25, 46, '04:40:55', '00:00:55', 'FINALIZADO'),
(5, 26, 47, '04:40:56', '00:00:56', 'FINALIZADO'),
(5, 27, 48, '04:40:57', '00:00:57', 'FINALIZADO'),
(5, 28, 49, '04:41:00', '00:01:00', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(6, 36, 1, '03:48:00', '00:00:00', 'FINALIZADO'),
(6, 37, 2, '03:48:01', '00:00:01', 'FINALIZADO'),
(6, 38, 3, '03:48:02', '00:00:02', 'FINALIZADO'),
(6, 39, 4, '03:48:03', '00:00:03', 'FINALIZADO'),
(6, 40, 5, '03:48:04', '00:00:04', 'FINALIZADO'),
(6, 41, 6, '03:48:05', '00:00:05', 'FINALIZADO'),
(6, 42, 7, '03:48:06', '00:00:06', 'FINALIZADO'),
(6, 43, 8, '03:48:07', '00:00:07', 'FINALIZADO'),
(6, 44, 9, '03:48:08', '00:00:08', 'FINALIZADO'),
(6, 45, 10, '03:48:09', '00:00:09', 'FINALIZADO'),
(6, 46, 11, '03:48:10', '00:00:10', 'FINALIZADO'),
(6, 47, 12, '03:48:11', '00:00:11', 'FINALIZADO'),
(6, 48, 13, '03:48:12', '00:00:12', 'FINALIZADO'),
(6, 49, 14, '03:48:13', '00:00:13', 'FINALIZADO'),
(6, 1, 15, '03:48:14', '00:00:14', 'FINALIZADO'),
(6, 2, 16, '03:48:15', '00:00:15', 'FINALIZADO'),
(6, 3, 17, '03:48:16', '00:00:16', 'FINALIZADO'),
(6, 4, 18, '03:48:17', '00:00:17', 'FINALIZADO'),
(6, 5, 19, '03:48:18', '00:00:18', 'FINALIZADO'),
(6, 6, 20, '03:48:19', '00:00:19', 'FINALIZADO'),
(6, 7, 21, '03:48:21', '00:00:21', 'FINALIZADO'),
(6, 8, 22, '03:48:22', '00:00:22', 'FINALIZADO'),
(6, 9, 23, '03:48:23', '00:00:23', 'FINALIZADO'),
(6, 10, 24, '03:48:24', '00:00:24', 'FINALIZADO'),
(6, 11, 25, '03:48:25', '00:00:25', 'FINALIZADO'),
(6, 12, 26, '03:48:26', '00:00:26', 'FINALIZADO'),
(6, 13, 27, '03:48:27', '00:00:27', 'FINALIZADO'),
(6, 14, 28, '03:48:28', '00:00:28', 'FINALIZADO'),
(6, 15, 29, '03:48:29', '00:00:29', 'FINALIZADO'),
(6, 16, 30, '03:48:30', '00:00:30', 'FINALIZADO'),
(6, 17, 31, '03:48:31', '00:00:31', 'FINALIZADO'),
(6, 18, 32, '03:48:32', '00:00:32', 'FINALIZADO'),
(6, 19, 33, '03:48:33', '00:00:33', 'FINALIZADO'),
(6, 20, 34, '03:48:34', '00:00:34', 'FINALIZADO'),
(6, 21, 35, '03:48:35', '00:00:35', 'FINALIZADO'),
(6, 22, 36, '03:48:36', '00:00:36', 'FINALIZADO'),
(6, 23, 37, '03:48:37', '00:00:37', 'FINALIZADO'),
(6, 24, 38, '03:48:38', '00:00:38', 'FINALIZADO'),
(6, 25, 39, '03:48:39', '00:00:39', 'FINALIZADO'),
(6, 26, 40, '03:48:40', '00:00:40', 'FINALIZADO'),
(6, 27, 41, '03:48:42', '00:00:42', 'FINALIZADO'),
(6, 28, 42, '03:48:43', '00:00:43', 'FINALIZADO'),
(6, 29, 43, '03:48:44', '00:00:44', 'FINALIZADO'),
(6, 30, 44, '03:48:45', '00:00:45', 'FINALIZADO'),
(6, 31, 45, '03:48:46', '00:00:46', 'FINALIZADO'),
(6, 32, 46, '03:48:47', '00:00:47', 'FINALIZADO'),
(6, 33, 47, '03:48:48', '00:00:48', 'FINALIZADO'),
(6, 34, 48, '03:48:49', '00:00:49', 'FINALIZADO'),
(6, 35, 49, '03:48:50', '00:00:50', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(7, 43, 1, '00:42:00', '00:00:00', 'FINALIZADO'),
(7, 44, 2, '00:42:01', '00:00:01', 'FINALIZADO'),
(7, 45, 3, '00:42:02', '00:00:02', 'FINALIZADO'),
(7, 46, 4, '00:42:03', '00:00:03', 'FINALIZADO'),
(7, 47, 5, '00:42:04', '00:00:04', 'FINALIZADO'),
(7, 48, 6, '00:42:05', '00:00:05', 'FINALIZADO'),
(7, 49, 7, '00:42:06', '00:00:06', 'FINALIZADO'),
(7, 1, 8, '00:42:07', '00:00:07', 'FINALIZADO'),
(7, 2, 9, '00:42:08', '00:00:08', 'FINALIZADO'),
(7, 3, 10, '00:42:09', '00:00:09', 'FINALIZADO'),
(7, 4, 11, '00:42:10', '00:00:10', 'FINALIZADO'),
(7, 5, 12, '00:42:11', '00:00:11', 'FINALIZADO'),
(7, 6, 13, '00:42:12', '00:00:12', 'FINALIZADO'),
(7, 7, 14, '00:42:13', '00:00:13', 'FINALIZADO'),
(7, 8, 15, '00:42:14', '00:00:14', 'FINALIZADO'),
(7, 9, 16, '00:42:15', '00:00:15', 'FINALIZADO'),
(7, 10, 17, '00:42:16', '00:00:16', 'FINALIZADO'),
(7, 11, 18, '00:42:17', '00:00:17', 'FINALIZADO'),
(7, 12, 19, '00:42:18', '00:00:18', 'FINALIZADO'),
(7, 13, 20, '00:42:19', '00:00:19', 'FINALIZADO'),
(7, 14, 21, '00:42:20', '00:00:20', 'FINALIZADO'),
(7, 15, 22, '00:42:21', '00:00:21', 'FINALIZADO'),
(7, 16, 23, '00:42:22', '00:00:22', 'FINALIZADO'),
(7, 17, 24, '00:42:23', '00:00:23', 'FINALIZADO'),
(7, 18, 25, '00:42:24', '00:00:24', 'FINALIZADO'),
(7, 19, 26, '00:42:25', '00:00:25', 'FINALIZADO'),
(7, 20, 27, '00:42:26', '00:00:26', 'FINALIZADO'),
(7, 21, 28, '00:42:27', '00:00:27', 'FINALIZADO'),
(7, 22, 29, '00:42:28', '00:00:28', 'FINALIZADO'),
(7, 23, 30, '00:42:29', '00:00:29', 'FINALIZADO'),
(7, 24, 31, '00:42:30', '00:00:30', 'FINALIZADO'),
(7, 25, 32, '00:42:31', '00:00:31', 'FINALIZADO'),
(7, 26, 33, '00:42:32', '00:00:32', 'FINALIZADO'),
(7, 27, 34, '00:42:33', '00:00:33', 'FINALIZADO'),
(7, 28, 35, '00:42:34', '00:00:34', 'FINALIZADO'),
(7, 29, 36, '00:42:35', '00:00:35', 'FINALIZADO'),
(7, 30, 37, '00:42:36', '00:00:36', 'FINALIZADO'),
(7, 31, 38, '00:42:37', '00:00:37', 'FINALIZADO'),
(7, 32, 39, '00:42:38', '00:00:38', 'FINALIZADO'),
(7, 33, 40, '00:42:39', '00:00:39', 'FINALIZADO'),
(7, 34, 41, '00:42:40', '00:00:40', 'FINALIZADO'),
(7, 35, 42, '00:42:41', '00:00:41', 'FINALIZADO'),
(7, 36, 43, '00:42:42', '00:00:42', 'FINALIZADO'),
(7, 37, 44, '00:42:43', '00:00:43', 'FINALIZADO'),
(7, 38, 45, '00:42:44', '00:00:44', 'FINALIZADO'),
(7, 39, 46, '00:42:45', '00:00:45', 'FINALIZADO'),
(7, 40, 47, '00:42:46', '00:00:46', 'FINALIZADO'),
(7, 41, 48, '00:42:47', '00:00:47', 'FINALIZADO'),
(7, 42, 49, '00:42:48', '00:00:48', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(8, 1, 1, '04:15:00', '00:00:00', 'FINALIZADO'),
(8, 2, 2, '04:15:01', '00:00:01', 'FINALIZADO'),
(8, 3, 3, '04:15:02', '00:00:02', 'FINALIZADO'),
(8, 4, 4, '04:15:03', '00:00:03', 'FINALIZADO'),
(8, 5, 5, '04:15:04', '00:00:04', 'FINALIZADO'),
(8, 6, 6, '04:15:05', '00:00:05', 'FINALIZADO'),
(8, 7, 7, '04:15:06', '00:00:06', 'FINALIZADO'),
(8, 8, 8, '04:15:07', '00:00:07', 'FINALIZADO'),
(8, 9, 9, '04:15:08', '00:00:08', 'FINALIZADO'),
(8, 10, 10, '04:15:09', '00:00:09', 'FINALIZADO'),
(8, 11, 11, '04:15:10', '00:00:10', 'FINALIZADO'),
(8, 12, 12, '04:15:11', '00:00:11', 'FINALIZADO'),
(8, 13, 13, '04:15:13', '00:00:13', 'FINALIZADO'),
(8, 14, 14, '04:15:14', '00:00:14', 'FINALIZADO'),
(8, 15, 15, '04:15:15', '00:00:15', 'FINALIZADO'),
(8, 16, 16, '04:15:16', '00:00:16', 'FINALIZADO'),
(8, 17, 17, '04:15:17', '00:00:17', 'FINALIZADO'),
(8, 18, 18, '04:15:18', '00:00:18', 'FINALIZADO'),
(8, 19, 19, '04:15:19', '00:00:19', 'FINALIZADO'),
(8, 20, 20, '04:15:20', '00:00:20', 'FINALIZADO'),
(8, 21, 21, '04:15:21', '00:00:21', 'FINALIZADO'),
(8, 22, 22, '04:15:22', '00:00:22', 'FINALIZADO'),
(8, 23, 23, '04:15:23', '00:00:23', 'FINALIZADO'),
(8, 24, 24, '04:15:24', '00:00:24', 'FINALIZADO'),
(8, 25, 25, '04:15:26', '00:00:26', 'FINALIZADO'),
(8, 26, 26, '04:15:27', '00:00:27', 'FINALIZADO'),
(8, 27, 27, '04:15:28', '00:00:28', 'FINALIZADO'),
(8, 28, 28, '04:15:29', '00:00:29', 'FINALIZADO'),
(8, 29, 29, '04:15:30', '00:00:30', 'FINALIZADO'),
(8, 30, 30, '04:15:31', '00:00:31', 'FINALIZADO'),
(8, 31, 31, '04:15:32', '00:00:32', 'FINALIZADO'),
(8, 32, 32, '04:15:33', '00:00:33', 'FINALIZADO'),
(8, 33, 33, '04:15:34', '00:00:34', 'FINALIZADO'),
(8, 34, 34, '04:15:35', '00:00:35', 'FINALIZADO'),
(8, 35, 35, '04:15:36', '00:00:36', 'FINALIZADO'),
(8, 36, 36, '04:15:37', '00:00:37', 'FINALIZADO'),
(8, 37, 37, '04:15:39', '00:00:39', 'FINALIZADO'),
(8, 38, 38, '04:15:40', '00:00:40', 'FINALIZADO'),
(8, 39, 39, '04:15:41', '00:00:41', 'FINALIZADO'),
(8, 40, 40, '04:15:42', '00:00:42', 'FINALIZADO'),
(8, 41, 41, '04:15:43', '00:00:43', 'FINALIZADO'),
(8, 42, 42, '04:15:44', '00:00:44', 'FINALIZADO'),
(8, 43, 43, '04:15:45', '00:00:45', 'FINALIZADO'),
(8, 44, 44, '04:15:46', '00:00:46', 'FINALIZADO'),
(8, 45, 45, '04:15:47', '00:00:47', 'FINALIZADO'),
(8, 46, 46, '04:15:48', '00:00:48', 'FINALIZADO'),
(8, 47, 47, '04:15:49', '00:00:49', 'FINALIZADO'),
(8, 48, 48, '04:15:50', '00:00:50', 'FINALIZADO'),
(8, 49, 49, '04:15:52', '00:00:52', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(9, 8, 1, '03:45:00', '00:00:00', 'FINALIZADO'),
(9, 9, 2, '03:45:01', '00:00:01', 'FINALIZADO'),
(9, 10, 3, '03:45:02', '00:00:02', 'FINALIZADO'),
(9, 11, 4, '03:45:03', '00:00:03', 'FINALIZADO'),
(9, 12, 5, '03:45:04', '00:00:04', 'FINALIZADO'),
(9, 13, 6, '03:45:05', '00:00:05', 'FINALIZADO'),
(9, 14, 7, '03:45:06', '00:00:06', 'FINALIZADO'),
(9, 15, 8, '03:45:07', '00:00:07', 'FINALIZADO'),
(9, 16, 9, '03:45:08', '00:00:08', 'FINALIZADO'),
(9, 17, 10, '03:45:09', '00:00:09', 'FINALIZADO'),
(9, 18, 11, '03:45:10', '00:00:10', 'FINALIZADO'),
(9, 19, 12, '03:45:11', '00:00:11', 'FINALIZADO'),
(9, 20, 13, '03:45:12', '00:00:12', 'FINALIZADO'),
(9, 21, 14, '03:45:13', '00:00:13', 'FINALIZADO'),
(9, 22, 15, '03:45:14', '00:00:14', 'FINALIZADO'),
(9, 23, 16, '03:45:15', '00:00:15', 'FINALIZADO'),
(9, 24, 17, '03:45:16', '00:00:16', 'FINALIZADO'),
(9, 25, 18, '03:45:17', '00:00:17', 'FINALIZADO'),
(9, 26, 19, '03:45:18', '00:00:18', 'FINALIZADO'),
(9, 27, 20, '03:45:19', '00:00:19', 'FINALIZADO'),
(9, 28, 21, '03:45:21', '00:00:21', 'FINALIZADO'),
(9, 29, 22, '03:45:22', '00:00:22', 'FINALIZADO'),
(9, 30, 23, '03:45:23', '00:00:23', 'FINALIZADO'),
(9, 31, 24, '03:45:24', '00:00:24', 'FINALIZADO'),
(9, 32, 25, '03:45:25', '00:00:25', 'FINALIZADO'),
(9, 33, 26, '03:45:26', '00:00:26', 'FINALIZADO'),
(9, 34, 27, '03:45:27', '00:00:27', 'FINALIZADO'),
(9, 35, 28, '03:45:28', '00:00:28', 'FINALIZADO'),
(9, 36, 29, '03:45:29', '00:00:29', 'FINALIZADO'),
(9, 37, 30, '03:45:30', '00:00:30', 'FINALIZADO'),
(9, 38, 31, '03:45:31', '00:00:31', 'FINALIZADO'),
(9, 39, 32, '03:45:32', '00:00:32', 'FINALIZADO'),
(9, 40, 33, '03:45:33', '00:00:33', 'FINALIZADO'),
(9, 41, 34, '03:45:34', '00:00:34', 'FINALIZADO'),
(9, 42, 35, '03:45:35', '00:00:35', 'FINALIZADO'),
(9, 43, 36, '03:45:36', '00:00:36', 'FINALIZADO'),
(9, 44, 37, '03:45:37', '00:00:37', 'FINALIZADO'),
(9, 45, 38, '03:45:38', '00:00:38', 'FINALIZADO'),
(9, 46, 39, '03:45:39', '00:00:39', 'FINALIZADO'),
(9, 47, 40, '03:45:40', '00:00:40', 'FINALIZADO'),
(9, 48, 41, '03:45:42', '00:00:42', 'FINALIZADO'),
(9, 49, 42, '03:45:43', '00:00:43', 'FINALIZADO'),
(9, 1, 43, '03:45:44', '00:00:44', 'FINALIZADO'),
(9, 2, 44, '03:45:45', '00:00:45', 'FINALIZADO'),
(9, 3, 45, '03:45:46', '00:00:46', 'FINALIZADO'),
(9, 4, 46, '03:45:47', '00:00:47', 'FINALIZADO'),
(9, 5, 47, '03:45:48', '00:00:48', 'FINALIZADO'),
(9, 6, 48, '03:45:49', '00:00:49', 'FINALIZADO'),
(9, 7, 49, '03:45:50', '00:00:50', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(10, 15, 1, '04:35:00', '00:00:00', 'FINALIZADO'),
(10, 16, 2, '04:35:01', '00:00:01', 'FINALIZADO'),
(10, 17, 3, '04:35:02', '00:00:02', 'FINALIZADO'),
(10, 18, 4, '04:35:03', '00:00:03', 'FINALIZADO'),
(10, 19, 5, '04:35:04', '00:00:04', 'FINALIZADO'),
(10, 20, 6, '04:35:05', '00:00:05', 'FINALIZADO'),
(10, 21, 7, '04:35:06', '00:00:06', 'FINALIZADO'),
(10, 22, 8, '04:35:07', '00:00:07', 'FINALIZADO'),
(10, 23, 9, '04:35:10', '00:00:10', 'FINALIZADO'),
(10, 24, 10, '04:35:11', '00:00:11', 'FINALIZADO'),
(10, 25, 11, '04:35:12', '00:00:12', 'FINALIZADO'),
(10, 26, 12, '04:35:13', '00:00:13', 'FINALIZADO'),
(10, 27, 13, '04:35:14', '00:00:14', 'FINALIZADO'),
(10, 28, 14, '04:35:15', '00:00:15', 'FINALIZADO'),
(10, 29, 15, '04:35:16', '00:00:16', 'FINALIZADO'),
(10, 30, 16, '04:35:17', '00:00:17', 'FINALIZADO'),
(10, 31, 17, '04:35:20', '00:00:20', 'FINALIZADO'),
(10, 32, 18, '04:35:21', '00:00:21', 'FINALIZADO'),
(10, 33, 19, '04:35:22', '00:00:22', 'FINALIZADO'),
(10, 34, 20, '04:35:23', '00:00:23', 'FINALIZADO'),
(10, 35, 21, '04:35:24', '00:00:24', 'FINALIZADO'),
(10, 36, 22, '04:35:25', '00:00:25', 'FINALIZADO'),
(10, 37, 23, '04:35:26', '00:00:26', 'FINALIZADO'),
(10, 38, 24, '04:35:27', '00:00:27', 'FINALIZADO'),
(10, 39, 25, '04:35:30', '00:00:30', 'FINALIZADO'),
(10, 40, 26, '04:35:31', '00:00:31', 'FINALIZADO'),
(10, 41, 27, '04:35:32', '00:00:32', 'FINALIZADO'),
(10, 42, 28, '04:35:33', '00:00:33', 'FINALIZADO'),
(10, 43, 29, '04:35:34', '00:00:34', 'FINALIZADO'),
(10, 44, 30, '04:35:35', '00:00:35', 'FINALIZADO'),
(10, 45, 31, '04:35:36', '00:00:36', 'FINALIZADO'),
(10, 46, 32, '04:35:37', '00:00:37', 'FINALIZADO'),
(10, 47, 33, '04:35:40', '00:00:40', 'FINALIZADO'),
(10, 48, 34, '04:35:41', '00:00:41', 'FINALIZADO'),
(10, 49, 35, '04:35:42', '00:00:42', 'FINALIZADO'),
(10, 1, 36, '04:35:43', '00:00:43', 'FINALIZADO'),
(10, 2, 37, '04:35:44', '00:00:44', 'FINALIZADO'),
(10, 3, 38, '04:35:45', '00:00:45', 'FINALIZADO'),
(10, 4, 39, '04:35:46', '00:00:46', 'FINALIZADO'),
(10, 5, 40, '04:35:47', '00:00:47', 'FINALIZADO'),
(10, 6, 41, '04:35:50', '00:00:50', 'FINALIZADO'),
(10, 7, 42, '04:35:51', '00:00:51', 'FINALIZADO'),
(10, 8, 43, '04:35:52', '00:00:52', 'FINALIZADO'),
(10, 9, 44, '04:35:53', '00:00:53', 'FINALIZADO'),
(10, 10, 45, '04:35:54', '00:00:54', 'FINALIZADO'),
(10, 11, 46, '04:35:55', '00:00:55', 'FINALIZADO'),
(10, 12, 47, '04:35:56', '00:00:56', 'FINALIZADO'),
(10, 13, 48, '04:35:57', '00:00:57', 'FINALIZADO'),
(10, 14, 49, '04:36:00', '00:01:00', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(11, 22, 1, '04:10:00', '00:00:00', 'FINALIZADO'),
(11, 23, 2, '04:10:01', '00:00:01', 'FINALIZADO'),
(11, 24, 3, '04:10:02', '00:00:02', 'FINALIZADO'),
(11, 25, 4, '04:10:03', '00:00:03', 'FINALIZADO'),
(11, 26, 5, '04:10:04', '00:00:04', 'FINALIZADO'),
(11, 27, 6, '04:10:05', '00:00:05', 'FINALIZADO'),
(11, 28, 7, '04:10:06', '00:00:06', 'FINALIZADO'),
(11, 29, 8, '04:10:07', '00:00:07', 'FINALIZADO'),
(11, 30, 9, '04:10:08', '00:00:08', 'FINALIZADO'),
(11, 31, 10, '04:10:09', '00:00:09', 'FINALIZADO'),
(11, 32, 11, '04:10:10', '00:00:10', 'FINALIZADO'),
(11, 33, 12, '04:10:11', '00:00:11', 'FINALIZADO'),
(11, 34, 13, '04:10:13', '00:00:13', 'FINALIZADO'),
(11, 35, 14, '04:10:14', '00:00:14', 'FINALIZADO'),
(11, 36, 15, '04:10:15', '00:00:15', 'FINALIZADO'),
(11, 37, 16, '04:10:16', '00:00:16', 'FINALIZADO'),
(11, 38, 17, '04:10:17', '00:00:17', 'FINALIZADO'),
(11, 39, 18, '04:10:18', '00:00:18', 'FINALIZADO'),
(11, 40, 19, '04:10:19', '00:00:19', 'FINALIZADO'),
(11, 41, 20, '04:10:20', '00:00:20', 'FINALIZADO'),
(11, 42, 21, '04:10:21', '00:00:21', 'FINALIZADO'),
(11, 43, 22, '04:10:22', '00:00:22', 'FINALIZADO'),
(11, 44, 23, '04:10:23', '00:00:23', 'FINALIZADO'),
(11, 45, 24, '04:10:24', '00:00:24', 'FINALIZADO'),
(11, 46, 25, '04:10:26', '00:00:26', 'FINALIZADO'),
(11, 47, 26, '04:10:27', '00:00:27', 'FINALIZADO'),
(11, 48, 27, '04:10:28', '00:00:28', 'FINALIZADO'),
(11, 49, 28, '04:10:29', '00:00:29', 'FINALIZADO'),
(11, 1, 29, '04:10:30', '00:00:30', 'FINALIZADO'),
(11, 2, 30, '04:10:31', '00:00:31', 'FINALIZADO'),
(11, 3, 31, '04:10:32', '00:00:32', 'FINALIZADO'),
(11, 4, 32, '04:10:33', '00:00:33', 'FINALIZADO'),
(11, 5, 33, '04:10:34', '00:00:34', 'FINALIZADO'),
(11, 6, 34, '04:10:35', '00:00:35', 'FINALIZADO'),
(11, 7, 35, '04:10:36', '00:00:36', 'FINALIZADO'),
(11, 8, 36, '04:10:37', '00:00:37', 'FINALIZADO'),
(11, 9, 37, '04:10:39', '00:00:39', 'FINALIZADO'),
(11, 10, 38, '04:10:40', '00:00:40', 'FINALIZADO'),
(11, 11, 39, '04:10:41', '00:00:41', 'FINALIZADO'),
(11, 12, 40, '04:10:42', '00:00:42', 'FINALIZADO'),
(11, 13, 41, '04:10:43', '00:00:43', 'FINALIZADO'),
(11, 14, 42, '04:10:44', '00:00:44', 'FINALIZADO'),
(11, 15, 43, '04:10:45', '00:00:45', 'FINALIZADO'),
(11, 16, 44, '04:10:46', '00:00:46', 'FINALIZADO'),
(11, 17, 45, '04:10:47', '00:00:47', 'FINALIZADO'),
(11, 18, 46, '04:10:48', '00:00:48', 'FINALIZADO'),
(11, 19, 47, '04:10:49', '00:00:49', 'FINALIZADO'),
(11, 20, 48, '04:10:50', '00:00:50', 'FINALIZADO'),
(11, 21, 49, '04:10:52', '00:00:52', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(12, 29, 1, '03:40:00', '00:00:00', 'FINALIZADO'),
(12, 30, 2, '03:40:01', '00:00:01', 'FINALIZADO'),
(12, 31, 3, '03:40:02', '00:00:02', 'FINALIZADO'),
(12, 32, 4, '03:40:03', '00:00:03', 'FINALIZADO'),
(12, 33, 5, '03:40:04', '00:00:04', 'FINALIZADO'),
(12, 34, 6, '03:40:05', '00:00:05', 'FINALIZADO'),
(12, 35, 7, '03:40:06', '00:00:06', 'FINALIZADO'),
(12, 36, 8, '03:40:07', '00:00:07', 'FINALIZADO'),
(12, 37, 9, '03:40:08', '00:00:08', 'FINALIZADO'),
(12, 38, 10, '03:40:09', '00:00:09', 'FINALIZADO'),
(12, 39, 11, '03:40:10', '00:00:10', 'FINALIZADO'),
(12, 40, 12, '03:40:11', '00:00:11', 'FINALIZADO'),
(12, 41, 13, '03:40:12', '00:00:12', 'FINALIZADO'),
(12, 42, 14, '03:40:13', '00:00:13', 'FINALIZADO'),
(12, 43, 15, '03:40:14', '00:00:14', 'FINALIZADO'),
(12, 44, 16, '03:40:15', '00:00:15', 'FINALIZADO'),
(12, 45, 17, '03:40:16', '00:00:16', 'FINALIZADO'),
(12, 46, 18, '03:40:17', '00:00:17', 'FINALIZADO'),
(12, 47, 19, '03:40:18', '00:00:18', 'FINALIZADO'),
(12, 48, 20, '03:40:19', '00:00:19', 'FINALIZADO'),
(12, 49, 21, '03:40:21', '00:00:21', 'FINALIZADO'),
(12, 1, 22, '03:40:22', '00:00:22', 'FINALIZADO'),
(12, 2, 23, '03:40:23', '00:00:23', 'FINALIZADO'),
(12, 3, 24, '03:40:24', '00:00:24', 'FINALIZADO'),
(12, 4, 25, '03:40:25', '00:00:25', 'FINALIZADO'),
(12, 5, 26, '03:40:26', '00:00:26', 'FINALIZADO'),
(12, 6, 27, '03:40:27', '00:00:27', 'FINALIZADO'),
(12, 7, 28, '03:40:28', '00:00:28', 'FINALIZADO'),
(12, 8, 29, '03:40:29', '00:00:29', 'FINALIZADO'),
(12, 9, 30, '03:40:30', '00:00:30', 'FINALIZADO'),
(12, 10, 31, '03:40:31', '00:00:31', 'FINALIZADO'),
(12, 11, 32, '03:40:32', '00:00:32', 'FINALIZADO'),
(12, 12, 33, '03:40:33', '00:00:33', 'FINALIZADO'),
(12, 13, 34, '03:40:34', '00:00:34', 'FINALIZADO'),
(12, 14, 35, '03:40:35', '00:00:35', 'FINALIZADO'),
(12, 15, 36, '03:40:36', '00:00:36', 'FINALIZADO'),
(12, 16, 37, '03:40:37', '00:00:37', 'FINALIZADO'),
(12, 17, 38, '03:40:38', '00:00:38', 'FINALIZADO'),
(12, 18, 39, '03:40:39', '00:00:39', 'FINALIZADO'),
(12, 19, 40, '03:40:40', '00:00:40', 'FINALIZADO'),
(12, 20, 41, '03:40:42', '00:00:42', 'FINALIZADO'),
(12, 21, 42, '03:40:43', '00:00:43', 'FINALIZADO'),
(12, 22, 43, '03:40:44', '00:00:44', 'FINALIZADO'),
(12, 23, 44, '03:40:45', '00:00:45', 'FINALIZADO'),
(12, 24, 45, '03:40:46', '00:00:46', 'FINALIZADO'),
(12, 25, 46, '03:40:47', '00:00:47', 'FINALIZADO'),
(12, 26, 47, '03:40:48', '00:00:48', 'FINALIZADO'),
(12, 27, 48, '03:40:49', '00:00:49', 'FINALIZADO'),
(12, 28, 49, '03:40:50', '00:00:50', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(13, 36, 1, '03:38:00', '00:00:00', 'FINALIZADO'),
(13, 37, 2, '03:38:01', '00:00:01', 'FINALIZADO'),
(13, 38, 3, '03:38:02', '00:00:02', 'FINALIZADO'),
(13, 39, 4, '03:38:03', '00:00:03', 'FINALIZADO'),
(13, 40, 5, '03:38:04', '00:00:04', 'FINALIZADO'),
(13, 41, 6, '03:38:05', '00:00:05', 'FINALIZADO'),
(13, 42, 7, '03:38:06', '00:00:06', 'FINALIZADO'),
(13, 43, 8, '03:38:07', '00:00:07', 'FINALIZADO'),
(13, 44, 9, '03:38:08', '00:00:08', 'FINALIZADO'),
(13, 45, 10, '03:38:09', '00:00:09', 'FINALIZADO'),
(13, 46, 11, '03:38:10', '00:00:10', 'FINALIZADO'),
(13, 47, 12, '03:38:11', '00:00:11', 'FINALIZADO'),
(13, 48, 13, '03:38:12', '00:00:12', 'FINALIZADO'),
(13, 49, 14, '03:38:13', '00:00:13', 'FINALIZADO'),
(13, 1, 15, '03:38:14', '00:00:14', 'FINALIZADO'),
(13, 2, 16, '03:38:15', '00:00:15', 'FINALIZADO'),
(13, 3, 17, '03:38:16', '00:00:16', 'FINALIZADO'),
(13, 4, 18, '03:38:17', '00:00:17', 'FINALIZADO'),
(13, 5, 19, '03:38:18', '00:00:18', 'FINALIZADO'),
(13, 6, 20, '03:38:19', '00:00:19', 'FINALIZADO'),
(13, 7, 21, '03:38:21', '00:00:21', 'FINALIZADO'),
(13, 8, 22, '03:38:22', '00:00:22', 'FINALIZADO'),
(13, 9, 23, '03:38:23', '00:00:23', 'FINALIZADO'),
(13, 10, 24, '03:38:24', '00:00:24', 'FINALIZADO'),
(13, 11, 25, '03:38:25', '00:00:25', 'FINALIZADO'),
(13, 12, 26, '03:38:26', '00:00:26', 'FINALIZADO'),
(13, 13, 27, '03:38:27', '00:00:27', 'FINALIZADO'),
(13, 14, 28, '03:38:28', '00:00:28', 'FINALIZADO'),
(13, 15, 29, '03:38:29', '00:00:29', 'FINALIZADO'),
(13, 16, 30, '03:38:30', '00:00:30', 'FINALIZADO'),
(13, 17, 31, '03:38:31', '00:00:31', 'FINALIZADO'),
(13, 18, 32, '03:38:32', '00:00:32', 'FINALIZADO'),
(13, 19, 33, '03:38:33', '00:00:33', 'FINALIZADO'),
(13, 20, 34, '03:38:34', '00:00:34', 'FINALIZADO'),
(13, 21, 35, '03:38:35', '00:00:35', 'FINALIZADO'),
(13, 22, 36, '03:38:36', '00:00:36', 'FINALIZADO'),
(13, 23, 37, '03:38:37', '00:00:37', 'FINALIZADO'),
(13, 24, 38, '03:38:38', '00:00:38', 'FINALIZADO'),
(13, 25, 39, '03:38:39', '00:00:39', 'FINALIZADO'),
(13, 26, 40, '03:38:40', '00:00:40', 'FINALIZADO'),
(13, 27, 41, '03:38:42', '00:00:42', 'FINALIZADO'),
(13, 28, 42, '03:38:43', '00:00:43', 'FINALIZADO'),
(13, 29, 43, '03:38:44', '00:00:44', 'FINALIZADO'),
(13, 30, 44, '03:38:45', '00:00:45', 'FINALIZADO'),
(13, 31, 45, '03:38:46', '00:00:46', 'FINALIZADO'),
(13, 32, 46, '03:38:47', '00:00:47', 'FINALIZADO'),
(13, 33, 47, '03:38:48', '00:00:48', 'FINALIZADO'),
(13, 34, 48, '03:38:49', '00:00:49', 'FINALIZADO'),
(13, 35, 49, '03:38:50', '00:00:50', 'FINALIZADO');

INSERT INTO resultados_etapa (id_etapa, id_ciclista, posicion, tiempo, diferencia, estado) VALUES
(14, 43, 1, '04:05:00', '00:00:00', 'FINALIZADO'),
(14, 44, 2, '04:05:01', '00:00:01', 'FINALIZADO'),
(14, 45, 3, '04:05:02', '00:00:02', 'FINALIZADO'),
(14, 46, 4, '04:05:03', '00:00:03', 'FINALIZADO'),
(14, 47, 5, '04:05:04', '00:00:04', 'FINALIZADO'),
(14, 48, 6, '04:05:05', '00:00:05', 'FINALIZADO'),
(14, 49, 7, '04:05:06', '00:00:06', 'FINALIZADO'),
(14, 1, 8, '04:05:07', '00:00:07', 'FINALIZADO'),
(14, 2, 9, '04:05:08', '00:00:08', 'FINALIZADO'),
(14, 3, 10, '04:05:09', '00:00:09', 'FINALIZADO'),
(14, 4, 11, '04:05:10', '00:00:10', 'FINALIZADO'),
(14, 5, 12, '04:05:11', '00:00:11', 'FINALIZADO'),
(14, 6, 13, '04:05:13', '00:00:13', 'FINALIZADO'),
(14, 7, 14, '04:05:14', '00:00:14', 'FINALIZADO'),
(14, 8, 15, '04:05:15', '00:00:15', 'FINALIZADO'),
(14, 9, 16, '04:05:16', '00:00:16', 'FINALIZADO'),
(14, 10, 17, '04:05:17', '00:00:17', 'FINALIZADO'),
(14, 11, 18, '04:05:18', '00:00:18', 'FINALIZADO'),
(14, 12, 19, '04:05:19', '00:00:19', 'FINALIZADO'),
(14, 13, 20, '04:05:20', '00:00:20', 'FINALIZADO'),
(14, 14, 21, '04:05:21', '00:00:21', 'FINALIZADO'),
(14, 15, 22, '04:05:22', '00:00:22', 'FINALIZADO'),
(14, 16, 23, '04:05:23', '00:00:23', 'FINALIZADO'),
(14, 17, 24, '04:05:24', '00:00:24', 'FINALIZADO'),
(14, 18, 25, '04:05:26', '00:00:26', 'FINALIZADO'),
(14, 19, 26, '04:05:27', '00:00:27', 'FINALIZADO'),
(14, 20, 27, '04:05:28', '00:00:28', 'FINALIZADO'),
(14, 21, 28, '04:05:29', '00:00:29', 'FINALIZADO'),
(14, 22, 29, '04:05:30', '00:00:30', 'FINALIZADO'),
(14, 23, 30, '04:05:31', '00:00:31', 'FINALIZADO'),
(14, 24, 31, '04:05:32', '00:00:32', 'FINALIZADO'),
(14, 25, 32, '04:05:33', '00:00:33', 'FINALIZADO'),
(14, 26, 33, '04:05:34', '00:00:34', 'FINALIZADO'),
(14, 27, 34, '04:05:35', '00:00:35', 'FINALIZADO'),
(14, 28, 35, '04:05:36', '00:00:36', 'FINALIZADO'),
(14, 29, 36, '04:05:37', '00:00:37', 'FINALIZADO'),
(14, 30, 37, '04:05:39', '00:00:39', 'FINALIZADO'),
(14, 31, 38, '04:05:40', '00:00:40', 'FINALIZADO'),
(14, 32, 39, '04:05:41', '00:00:41', 'FINALIZADO'),
(14, 33, 40, '04:05:42', '00:00:42', 'FINALIZADO'),
(14, 34, 41, '04:05:43', '00:00:43', 'FINALIZADO'),
(14, 35, 42, '04:05:44', '00:00:44', 'FINALIZADO'),
(14, 36, 43, '04:05:45', '00:00:45', 'FINALIZADO'),
(14, 37, 44, '04:05:46', '00:00:46', 'FINALIZADO'),
(14, 38, 45, '04:05:47', '00:00:47', 'FINALIZADO'),
(14, 39, 46, '04:05:48', '00:00:48', 'FINALIZADO'),
(14, 40, 47, '04:05:49', '00:00:49', 'FINALIZADO'),
(14, 41, 48, '04:05:50', '00:00:50', 'FINALIZADO'),
(14, 42, 49, '04:05:52', '00:00:52', 'FINALIZADO');

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(1, 1, 1, 50),
(1, 2, 2, 30),
(1, 3, 3, 20),
(1, 4, 4, 12),
(1, 5, 5, 10),
(1, 6, 6, 8),
(1, 7, 7, 6),
(1, 8, 8, 4),
(1, 9, 9, 2),
(1, 10, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(2, 8, 1, 50),
(2, 9, 2, 30),
(2, 10, 3, 20),
(2, 11, 4, 12),
(2, 12, 5, 10),
(2, 13, 6, 8),
(2, 14, 7, 6),
(2, 15, 8, 4),
(2, 16, 9, 2),
(2, 17, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(3, 15, 1, 50),
(3, 16, 2, 30),
(3, 17, 3, 20),
(3, 18, 4, 12),
(3, 19, 5, 10),
(3, 20, 6, 8),
(3, 21, 7, 6),
(3, 22, 8, 4),
(3, 23, 9, 2),
(3, 24, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(4, 22, 1, 50),
(4, 23, 2, 30),
(4, 24, 3, 20),
(4, 25, 4, 12),
(4, 26, 5, 10),
(4, 27, 6, 8),
(4, 28, 7, 6),
(4, 29, 8, 4),
(4, 30, 9, 2),
(4, 31, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(5, 29, 1, 50),
(5, 30, 2, 30),
(5, 31, 3, 20),
(5, 32, 4, 12),
(5, 33, 5, 10),
(5, 34, 6, 8),
(5, 35, 7, 6),
(5, 36, 8, 4),
(5, 37, 9, 2),
(5, 38, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(6, 36, 1, 50),
(6, 37, 2, 30),
(6, 38, 3, 20),
(6, 39, 4, 12),
(6, 40, 5, 10),
(6, 41, 6, 8),
(6, 42, 7, 6),
(6, 43, 8, 4),
(6, 44, 9, 2),
(6, 45, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(7, 43, 1, 50),
(7, 44, 2, 30),
(7, 45, 3, 20),
(7, 46, 4, 12),
(7, 47, 5, 10),
(7, 48, 6, 8),
(7, 49, 7, 6),
(7, 1, 8, 4),
(7, 2, 9, 2),
(7, 3, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(8, 1, 1, 50),
(8, 2, 2, 30),
(8, 3, 3, 20),
(8, 4, 4, 12),
(8, 5, 5, 10),
(8, 6, 6, 8),
(8, 7, 7, 6),
(8, 8, 8, 4),
(8, 9, 9, 2),
(8, 10, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(9, 8, 1, 50),
(9, 9, 2, 30),
(9, 10, 3, 20),
(9, 11, 4, 12),
(9, 12, 5, 10),
(9, 13, 6, 8),
(9, 14, 7, 6),
(9, 15, 8, 4),
(9, 16, 9, 2),
(9, 17, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(10, 15, 1, 50),
(10, 16, 2, 30),
(10, 17, 3, 20),
(10, 18, 4, 12),
(10, 19, 5, 10),
(10, 20, 6, 8),
(10, 21, 7, 6),
(10, 22, 8, 4),
(10, 23, 9, 2),
(10, 24, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(11, 22, 1, 50),
(11, 23, 2, 30),
(11, 24, 3, 20),
(11, 25, 4, 12),
(11, 26, 5, 10),
(11, 27, 6, 8),
(11, 28, 7, 6),
(11, 29, 8, 4),
(11, 30, 9, 2),
(11, 31, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(12, 29, 1, 50),
(12, 30, 2, 30),
(12, 31, 3, 20),
(12, 32, 4, 12),
(12, 33, 5, 10),
(12, 34, 6, 8),
(12, 35, 7, 6),
(12, 36, 8, 4),
(12, 37, 9, 2),
(12, 38, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(13, 36, 1, 50),
(13, 37, 2, 30),
(13, 38, 3, 20),
(13, 39, 4, 12),
(13, 40, 5, 10),
(13, 41, 6, 8),
(13, 42, 7, 6),
(13, 43, 8, 4),
(13, 44, 9, 2),
(13, 45, 10, 1);

INSERT INTO puntos_meta (id_etapa, id_ciclista, posicion, puntos) VALUES
(14, 43, 1, 50),
(14, 44, 2, 30),
(14, 45, 3, 20),
(14, 46, 4, 12),
(14, 47, 5, 10),
(14, 48, 6, 8),
(14, 49, 7, 6),
(14, 1, 8, 4),
(14, 2, 9, 2),
(14, 3, 10, 1);

-- Sprints intermedios y resultados
INSERT INTO sprints (id_etapa, km) VALUES (1, 56.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(1, 1, 1, 10),
(1, 2, 2, 6),
(1, 3, 3, 4),
(1, 4, 4, 2),
(1, 5, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (1, 112.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(2, 2, 1, 10),
(2, 3, 2, 6),
(2, 4, 3, 4),
(2, 5, 4, 2),
(2, 6, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (2, 91.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(3, 2, 1, 10),
(3, 3, 2, 6),
(3, 4, 3, 4),
(3, 5, 4, 2),
(3, 6, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (3, 80.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(4, 3, 1, 10),
(4, 4, 2, 6),
(4, 5, 3, 4),
(4, 6, 4, 2),
(4, 7, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (4, 87.5);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(5, 4, 1, 10),
(5, 5, 2, 6),
(5, 6, 3, 4),
(5, 7, 4, 2),
(5, 8, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (6, 51.67);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(6, 6, 1, 10),
(6, 7, 2, 6),
(6, 8, 3, 4),
(6, 9, 4, 2),
(6, 10, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (6, 103.33);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(7, 7, 1, 10),
(7, 8, 2, 6),
(7, 9, 3, 4),
(7, 10, 4, 2),
(7, 11, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (8, 85.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(8, 8, 1, 10),
(8, 9, 2, 6),
(8, 10, 3, 4),
(8, 11, 4, 2),
(8, 12, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (9, 55.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(9, 9, 1, 10),
(9, 10, 2, 6),
(9, 11, 3, 4),
(9, 12, 4, 2),
(9, 13, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (9, 110.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(10, 10, 1, 10),
(10, 11, 2, 6),
(10, 12, 3, 4),
(10, 13, 4, 2),
(10, 14, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (11, 89.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(11, 11, 1, 10),
(11, 12, 2, 6),
(11, 13, 3, 4),
(11, 14, 4, 2),
(11, 15, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (12, 50.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(12, 12, 1, 10),
(12, 13, 2, 6),
(12, 14, 3, 4),
(12, 15, 4, 2),
(12, 16, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (12, 100.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(13, 13, 1, 10),
(13, 14, 2, 6),
(13, 15, 3, 4),
(13, 16, 4, 2),
(13, 17, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (13, 52.67);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(14, 13, 1, 10),
(14, 14, 2, 6),
(14, 15, 3, 4),
(14, 16, 4, 2),
(14, 17, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (13, 105.33);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(15, 14, 1, 10),
(15, 15, 2, 6),
(15, 16, 3, 4),
(15, 17, 4, 2),
(15, 18, 5, 1);

INSERT INTO sprints (id_etapa, km) VALUES (14, 92.0);
INSERT INTO resultados_sprint (id_sprint, id_ciclista, posicion, puntos) VALUES
(16, 14, 1, 10),
(16, 15, 2, 6),
(16, 16, 3, 4),
(16, 17, 4, 2),
(16, 18, 5, 1);

-- Puertos y resultados de montaña
INSERT INTO puertos (id_etapa, nombre, km, categoria) VALUES (2, 'Alto do Pego', 120.0, '3');
INSERT INTO resultados_puerto (id_puerto, id_ciclista, posicion, puntos) VALUES
(1, 6, 1, 5),
(1, 7, 2, 3),
(1, 8, 3, 2),
(1, 9, 4, 1);

INSERT INTO puertos (id_etapa, nombre, km, categoria) VALUES (4, 'Serra de Monchique', 150.0, '2');
INSERT INTO resultados_puerto (id_puerto, id_ciclista, posicion, puntos) VALUES
(2, 16, 1, 10),
(2, 17, 2, 6),
(2, 18, 3, 4),
(2, 19, 4, 2),
(2, 20, 5, 1);

INSERT INTO puertos (id_etapa, nombre, km, categoria) VALUES (5, 'Foia', 155.0, 'HC');
INSERT INTO resultados_puerto (id_puerto, id_ciclista, posicion, puntos) VALUES
(3, 21, 1, 20),
(3, 22, 2, 15),
(3, 23, 3, 10),
(3, 24, 4, 6),
(3, 25, 5, 4),
(3, 26, 6, 2);

INSERT INTO puertos (id_etapa, nombre, km, categoria) VALUES (5, 'Picota', 60.0, '2');
INSERT INTO resultados_puerto (id_puerto, id_ciclista, posicion, puntos) VALUES
(4, 21, 1, 10),
(4, 22, 2, 6),
(4, 23, 3, 4),
(4, 24, 4, 2),
(4, 25, 5, 1);

INSERT INTO puertos (id_etapa, nombre, km, categoria) VALUES (8, 'Cercal', 100.0, '3');
INSERT INTO resultados_puerto (id_puerto, id_ciclista, posicion, puntos) VALUES
(5, 36, 1, 5),
(5, 37, 2, 3),
(5, 38, 3, 2),
(5, 39, 4, 1);

INSERT INTO puertos (id_etapa, nombre, km, categoria) VALUES (10, 'Arrábida', 130.0, '2');
INSERT INTO resultados_puerto (id_puerto, id_ciclista, posicion, puntos) VALUES
(6, 46, 1, 10),
(6, 47, 2, 6),
(6, 48, 3, 4),
(6, 49, 4, 2),
(6, 1, 5, 1);

INSERT INTO puertos (id_etapa, nombre, km, categoria) VALUES (10, 'Alto da Caparica', 80.0, '3');
INSERT INTO resultados_puerto (id_puerto, id_ciclista, posicion, puntos) VALUES
(7, 46, 1, 5),
(7, 47, 2, 3),
(7, 48, 3, 2),
(7, 49, 4, 1);

INSERT INTO puertos (id_etapa, nombre, km, categoria) VALUES (11, 'Peninha', 90.0, '2');
INSERT INTO resultados_puerto (id_puerto, id_ciclista, posicion, puntos) VALUES
(8, 2, 1, 10),
(8, 3, 2, 6),
(8, 4, 3, 4),
(8, 5, 4, 2),
(8, 6, 5, 1);

INSERT INTO puertos (id_etapa, nombre, km, categoria) VALUES (14, 'Serra do Montejunto', 95.0, '2');
INSERT INTO resultados_puerto (id_puerto, id_ciclista, posicion, puntos) VALUES
(9, 17, 1, 10),
(9, 18, 2, 6),
(9, 19, 3, 4),
(9, 20, 4, 2),
(9, 21, 5, 1);
