CREATE EXTENSION postgis;
CREATE SCHEMA cw3
--1. Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana
--pomiędzy 2018 a 2019) 

SELECT DISTINCT COUNT(b2.polygon_id) FROM cw3.T2018_KAR_BUILDINGS b1 FULL JOIN cw3.T2019_KAR_BUILDINGS b2 ON b1.polygon_id=b2.polygon_id 
WHERE (b1.type IS NULL AND b2.type IS NOT NULL) OR (b2.height != b1.height) OR b2.geom > b1.geom OR b2.geom < b1.geom

--2. Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub
--wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.
CREATE TABLE cw3.renovated_buildings AS 
SELECT b2.* FROM cw3.t2018_kar_buildings b1  FULL JOIN cw3.t2019_kar_buildings b2 ON b1.polygon_id=b2.polygon_id 
WHERE (b1.type IS NULL AND b2.type IS NOT NULL OR b2.height != b1.height) OR b1.geom < b2.geom 
SELECT * FROM cw3.renovated_buildings
SELECT p2.poi_id FROM cw3.t2019_kar_poi_table p1
FULL JOIN cw3.t2019_kar_poi_table p2 ON p1.poi_id=p2.poi_id WHERE p2.poi_id != p1.poi_id

--3. Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
--T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.
CREATE TABLE cw3.streets_reprojected AS SELECT gid, link_id, st_name, ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l, dir_travel, ST_Transform(geom, 3068) AS geom  FROM cw3.t2019_kar_streets 
SELECT * FROM cw3.streets_reprojected
SELECT ST_SRID(geom) FROM cw3.streets_reprojected
--4. Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
CREATE TABLE cw3.input_points (geom GEOMETRY) 
INSERT INTO cw3.input_points VALUES (ST_GeomFromText('POINT(8.36093 49.03174)', 4326))
INSERT INTO cw3.input_points VALUES (ST_GeomFromText('POINT(8.39876 49.00644)', 4326))
SELECT ST_SRID(geom) FROM cw3.input_points
SELECT * FROM cw3.input_points
--5. Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
--DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText()SELECT ST_Transform(ip.geom, 3068) FROM cw3.input_points ip
UPDATE cw3.input_points inp SET geom=ST_Transform(inp.geom, 3068)
SELECT ST_SRID(geom) FROM cw3.input_points
SELECT ST_AsText(geom) FROM cw3.input_points
--6. Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
--z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
--reprojekcji geometrii, aby była zgodna z resztą tabel.
SELECT * FROM cw3.t2019_kar_street_node
SELECT ST_SRID(geom) FROM cw3.t2019_kar_street_node
SELECT UpdateGeometrySRID('cw3','t2019_kar_street_node','geom',3068);
UPDATE cw3.t2019_kar_street_node nod SET geom=ST_Transform(nod.geom, 3068) 
SELECT ST_SRID(geom) FROM cw3.t2019_kar_street_node
SELECT DISTINCT * FROM cw3.t2019_kar_street_node nod WHERE nod.intersect='Y' AND
ST_DWithin(ST_SetSRID(ST_ShortestLine('POINT(8.36093 49.03174)','POINT(8.39876 49.00644)'), 3068),nod.geom,200)
SELECT nod.node_id FROM cw3.t2019_kar_street_node nod WHERE ST_Distance(nod.geom,ST_ShortestLine('POINT(-344665.6101066416 -353239.62974793336)','POINT(-342099.7650728856 -356243.3017531191)'))
AND SELECT * FROM cw3.input_points
--7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
--w odległości 300 m od parków (LAND_USE_A).
SELECT DISTINCT p2.poi_name, p2.type FROM public.t2019_kar_poi_table p2, public.t2019_kar_land_use_a lu 
WHERE ST_DWithin(lu.geom, p2.geom, 0.0027) AND p2.type = 'Sporting Goods Store' AND lu.type='Park (City/County)';
--8. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
--w odległości 300 m od parków (LAND_USE_A).
SELECT *, ST_AsText(geom) FROM cw3.t2019_kar_railways;
SELECT *, ST_AsText(geom) FROM cw3.t2019_kar_water_lines;
SELECT DISTINCT
cast(DENSE_RANK() OVER (ORDER BY  ST_Intersection(r.geom, li.geom)) AS INT) AS id,ST_AsText(ST_Intersection(r.geom, li.geom)) AS geom
FROM cw3.t2019_kar_railways r, cw3.t2019_kar_water_lines li; 
SELECT DISTINCT cast(DENSE_RANK() OVER (ORDER BY  ST_Intersection(r.geom, li.geom)) AS INT) AS id, ST_Intersection(r.geom, li.geom) AS geom
INTO TABLE cw3.T2019_KAR_BRIDGES FROM cw3.t2019_kar_railways r, cw3.t2019_kar_water_lines li;
SELECT * FROM cw3.T2019_KAR_BRIDGES;

