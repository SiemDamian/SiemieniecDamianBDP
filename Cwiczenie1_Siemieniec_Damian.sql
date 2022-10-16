
CREATE EXTENSION postgis; 
CREATE SCHEMA cwiczenie1;

CREATE TABLE budynki (ID INT PRIMARY KEY, geometry GEOMETRY, name VARCHAR(100), wysokosc INT);

CREATE TABLE drogi (ID INT PRIMARY KEY, geometry GEOMETRY, name VARCHAR(100)); 

CREATE TABLE pktinfo (ID INT PRIMARY KEY, geometry GEOMETRY, name VARCHAR(100), liczbaprac INT);
				  
INSERT INTO budynki(ID, geometry, name, wysokosc) VALUES (1, ST_GeomFromText('POLYGON((8 4, 8 1.5, 10.5 1.5, 10.5 4, 8 4))',0), 'BuildingA', 10);
INSERT INTO budynki(ID, geometry, name, wysokosc) VALUES (2, ST_GeomFromText('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))',0), 'BuildingB', 20);
INSERT INTO budynki(ID, geometry, name, wysokosc) VALUES (3, ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))',0), 'BuildingC', 30);
INSERT INTO budynki(ID, geometry, name, wysokosc) VALUES (4, ST_GeomFromText('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))',0), 'BuildingD', 40);
INSERT INTO budynki(ID, geometry, name, wysokosc) VALUES (5, ST_GeomFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))',0), 'BuildingF', 50);
 
INSERT INTO drogi VALUES(1,ST_GeomFromText('LINESTRING(0 4.5, 4.5 12)',0), 'RoadX');
INSERT INTO drogi VALUES(2,ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)',0), 'RoadY');

INSERT INTO pktinfo(ID, geometry, name) VALUES (1, ST_GeomFromText('POINT(1 3.5)',0), 'G');
INSERT INTO pktinfo(ID, geometry, name) VALUES (2, ST_GeomFromText('POINT(5.5 1.5)',0), 'H');
INSERT INTO pktinfo(ID, geometry, name) VALUES (3, ST_GeomFromText('POINT(9.5 6)',0), 'I');
INSERT INTO pktinfo(ID, geometry, name) VALUES (4, ST_GeomFromText('POINT(6.5 6)',0), 'J');
INSERT INTO pktinfo(ID, geometry, name) VALUES (5, ST_GeomFromText('POINT(6 9.5)',0), 'K');

SELECT * FROM budynki;
SELECT * FROM drogi;
SELECT * FROM pktinfo;
--1. Wyznacz całkowitą długość dróg w analizowanym mieście

SELECT SUM(ST_Length(geometry)) FROM drogi;

--2. Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego BuildingA.

SELECT ST_AsText(geometry) AS WKT, ST_Area(geometry) AS Pole_Powierzchni, ST_Perimeter(geometry) AS Obwód 
FROM budynki
WHERE name = 'BuildingA';
	
--3. Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie. 
SELECT name, ST_Area(geometry) FROM budynki ORDER BY name;
	
--4. Wypisz nazwy i obwody 2 budynków o największej powierzchni.  

SELECT name, ST_perimeter(geometry) AS obwód FROM budynki ORDER BY obwód DESC LIMIT 2
	
--5. Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G. 

SELECT ST_Distance(budynki.geometry, pktinfo.geometry) FROM budynki, pktinfo 
WHERE budynki.name = 'BuildingC' AND pktinfo.name = 'G'
	
--6. Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB. 

SELECT ST_Area(ST_Difference((SELECT geometry FROM budynki WHERE name = 'BuildingC'), 
ST_Buffer((SELECT geometry FROM budynki WHERE name = 'BuildingB'), 0.5)));
		
--7. Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi RoadX. 


SELECT budynki.name FROM budynki, drogi WHERE drogi.name = 'RoadX' AND ST_Y(ST_Centroid(budynki.geometry)) > 
ST_Y(ST_Centroid(drogi.geometry));

--8. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 
--4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.

SELECT ST_Area(ST_SymDifference(geometry, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))) 
FROM budynki WHERE name = 'BuildingC'