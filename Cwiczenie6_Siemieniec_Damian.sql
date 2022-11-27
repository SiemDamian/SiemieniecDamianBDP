
CREATE SCHEMA Siemieniec1
--przeciecie rastra z wektorem.
CREATE TABLE Siemieniec1.intersects AS 
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';
--serial primary key
alter table Siemieniec1.intersects
add column rid SERIAL PRIMARY KEY
--index przestrzenny
CREATE INDEX idx_intersects_rast_gist 
ON Siemieniec1.intersects
USING gist (ST_ConvexHull(rast));

-- schema::name table_name::name raster_column::name
--SELECT AddRasterConstraints('Siemieniec1'::name, 'intersects'::name,'rast'::name);

-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('siemieniec1'::name,
'intersects'::name,'rast'::name);
-- Przykład 2 - ST_Clip
CREATE TABLE Siemieniec1.clip AS 
SELECT ST_Clip(a.rast, b.geom, true), b.municipality 
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';


-- Przykład 3 - ST_Union
CREATE TABLE Siemieniec1.union AS 
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);



-- Przykład 1 - ST_AsRaster
--Przykład pokazuje użycie funkcji ST_AsRaster w celu rastrowania tabeli z parafiami o takiej
--samej charakterystyce przestrzennej tj.: wielkość piksela, zakresy itp.
CREATE TABLE Siemieniec1.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem 
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


-- Przykład 2 - ST_Union
--Wynikowy raster z poprzedniego zadania to jedna parafia na rekord, na wiersz tabeli. Użyj QGIS lub
--ArcGIS do wizualizacji wyników.
--Drugi przykład łączy rekordy z poprzedniego przykładu przy użyciu funkcji ST_UNION w pojedynczy
--raster

DROP TABLE Siemieniec1.porto_parishes; -- drop table porto_parishes first
CREATE TABLE Siemieniec1.porto_parishes AS
WITH r AS (
SELECT rast 
	FROM rasters.dem 
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- Przykład 3 - ST_Tile
DROP TABLE Siemieniec1.porto_parishes; -- drop table porto_parishes first
CREATE TABLE Siemieniec1.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem 
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


-- Przykład 1 - ST_Intersection
--Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile.

create table Siemieniec1.intersection as 
SELECT 
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b 
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


-- Przykład 2 - ST_DumpAsPolygons
--Funkcja St_Intersection jest podobna do ST_Clip. ST_Clip zwraca raster, a ST_Intersection zwraca
--zestaw par wartości geometria-piksel, ponieważ ta funkcja przekształca raster w wektor przed
--rzeczywistym „klipem”. Zazwyczaj ST_Intersection jest wolniejsze od ST_Clip więc zasadnym jest
--przeprowadzenie operacji ST_Clip na rastrze przed wykonaniem funkcji ST_Intersection.

CREATE TABLE Siemieniec1.dumppolygons AS
SELECT 
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b 
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przykład 1 - ST_Band 
--ST_DumpAsPolygons konwertuje rastry w wektory (poligony).

CREATE TABLE Siemieniec1.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

-- Przykład 2 - ST_Clip
--ST_Clip może być użyty do wycięcia rastra z innego rastra. Poniższy przykład wycina jedną parafię
--z tabeli vectors.porto_parishes. Wynik będzie potrzebny do wykonania kolejnych przykładów.

CREATE TABLE Siemieniec1.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przykład 3 - ST_Slope
--ST_Clip może być użyty do wycięcia rastra z innego rastra. Poniższy przykład wycina jedną parafię
--z tabeli vectors.porto_parishes. Wynik będzie potrzebny do wykonania kolejnych przykładów.

CREATE TABLE Siemieniec1.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM Siemieniec1.paranhos_dem AS a;

-- Przykład 4 - ST_Reclass
--Aby zreklasyfikować raster należy użyć funkcji ST_Reclass.

CREATE TABLE Siemieniec1.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3', 
'32BF',0)
FROM Siemieniec1.paranhos_slope AS a;

-- Przykład 5 - ST_SummaryStat
--Aby obliczyć statystyki rastra można użyć funkcji ST_SummaryStats. Poniższy przykład
--wygeneruje statystyki dla kafelka
SELECT st_summarystats(a.rast) AS stats
FROM Siemieniec1.paranhos_dem AS a;

-- Przykład 6 - ST_SummaryStats oraz Union
--Przy użyciu UNION można wygenerować jedną statystykę wybranego rastra.

SELECT st_summarystats(ST_Union(a.rast))
FROM Siemieniec1.paranhos_dem AS a;

-- Przykład 7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM Siemieniec1.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

-- Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, 
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

-- Przykład 9 - ST_Value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM 
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

-- Przykład 10 - ST_TPI
create table Siemieniec1.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON Siemieniec1.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('siemieniec1'::name, 
'tpi30'::name,'rast'::name);

 
create table Siemieniec1.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

CREATE INDEX idx_tpi30_porto_rast_gist ON Siemieniec1.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('siemieniec1'::name, 
'tpi30_porto'::name,'rast'::name);



-- Przykład 1 - Wyrażenie Algebry Map
CREATE TABLE Siemieniec1.porto_ndvi AS 
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] + 
[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON Siemieniec1.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('siemieniec1'::name, 
'porto_ndvi'::name,'rast'::name);

-- Przykład 2 – Funkcja zwrotna
create or replace function Siemieniec1.ndvi(
value double precision [] [] [], 
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS 
$$
BEGIN

RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value 
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE Siemieniec1.porto_ndvi2 AS 
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'Siemieniec1.ndvi(double precision[], 
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON Siemieniec1.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('siemieniec1'::name, 
'porto_ndvi2'::name,'rast'::name);

-- Przykład 1 - ST_AsTiff

SELECT ST_AsTiff(ST_Union(rast))
FROM Siemieniec1.porto_ndvi;

-- Przykład 2 - ST_AsGDALRaster

SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 
'PREDICTOR=2', 'PZLEVEL=9'])
FROM Siemieniec1.porto_ndvi;

SELECT ST_GDALDrivers();

-- Przykład 3 - Zapisywanie danych na dysku za pomocą dużego obiektu (large object, lo)

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
 ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 
'PREDICTOR=2', 'PZLEVEL=9'])
 ) AS loid
FROM Siemieniec1.porto_ndvi;


SELECT lo_export(loid, 'G:\myraster.tiff') FROM tmp_out;

SELECT lo_unlink(loid)
FROM tmp_out; 




 
 








