CREATE EXTENSION postgis; 
--1.1 Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej. Układ odniesienia
--ustal jako niezdefiniowany. Definicja geometrii powinna odbyć się za pomocą typów złożonych, właściwych dla EWKT

CREATE TABLE obiekty (ID INT PRIMARY KEY, NAME VARCHAR(10), GEOMETRY GEOMETRY); 
--Tworzenie obiektów
-- obiekt 1:
INSERT INTO obiekty(ID,NAME,GEOMETRY)   
VALUES(1, 'obiekt1', ST_GeomFromText('MULTICURVE( (0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), 
CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))'));

--obiekt 2:
INSERT INTO obiekty(ID,NAME,GEOMETRY) 
VALUES(2, 'obiekt2', ST_GeomFromText('CURVEPOLYGON(COMPOUNDCURVE(CIRCULARSTRING(14 6, 16 4, 14 2),
CIRCULARSTRING(14 2, 12 0, 10 2), (10 2, 10 6, 14 6)), CIRCULARSTRING(11 2, 13 2, 11 2))'));

--obiekt 3:
INSERT INTO obiekty(ID,NAME,GEOMETRY)  
VALUES(3, 'obiekt3', ST_GeomFromText('POLYGON((7 15, 12 13, 10 17, 7 15))'));

--obiekt 4:
INSERT INTO obiekty(ID,NAME,GEOMETRY)  
VALUES(4, 'obiekt4', ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'));

--obiekt 5:
INSERT INTO obiekty(ID,NAME,GEOMETRY) 
VALUES(5, 'obiekt5', ST_GeomFromText('MULTIPOINT(30 30 59, 38 32 234)'));
	
--obiekt 6:
INSERT INTO obiekty(ID,NAME,GEOMETRY)  
VALUES(6, 'obiekt5', ST_GeomFromText('GEOMETRYCOLLECTION(POINT(4 2),LINESTRING(1 1,3 2))'));

--1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej obiekt 3 i 4.
SELECT ST_Area((SELECT ST_Buffer((SELECT ST_ShortestLine(
(SELECT geometry FROM obiekty WHERE name = 'obiekt3'), 
(SELECT geometry FROM obiekty WHERE name = 'obiekt4'))), 5)))
	
-- 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te warunki.
INSERT INTO obiekty(ID, NAME, GEOMETRY)  
VALUES(7, 'poligon4',ST_MakePolygon( ST_AddPoint((SELECT geometry FROM obiekty WHERE name = 'obiekt4'),
ST_StartPoint((SELECT geometry FROM obiekty WHERE name = 'obiekt4')))));
	 

-- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.
INSERT INTO obiekty(ID,NAME, GEOMETRY)  VALUES
(8, 'obiekt7', ST_Collect((SELECT geometry FROM obiekty WHERE name = 'obiekt3'),
(SELECT geometry FROM obiekty WHERE name = 'obiekt4')))
	
-- 4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie zawierających łuków.
SELECT ST_Area(ST_Buffer(GEOMETRY, 5))FROM obiekty WHERE NOT ST_HasArc(GEOMETRY)