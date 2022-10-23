CREATE EXTENSION postgis; 

--4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty)
--położonych w odległości mniejszej niż 1000 m od głównych rzek. Budynki spełniające to
--kryterium zapisz do osobnej tabeli tableB.


SELECT COUNT (popp) FROM popp, majrivers
WHERE ST_Distance(popp.geom, majrivers.geom) < 1000 AND popp.f_codedesc LIKE 'Building'
SELECT popp.* INTO tableB FROM popp, majrivers
WHERE ST_Distance(popp.geom, majrivers.geom) < 1000 AND popp.f_codedesc LIKE 'Building'
SELECT * FROM tableB

--5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
--geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.
--a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.
--b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
--środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.
--Wysokość n.p.m. przyjmij dowolną.

SELECT name, geom, elev INTO airportsNew FROM airports
SELECT * FROM airportsNew

--a

SELECT name as Zach, ST_X(geom) FROM airportsNew ORDER BY ST_X(geom) DESC LIMIT 1;
SELECT name as Wsch, ST_X(geom)  FROM airportsNew ORDER BY ST_X(geom) ASC LIMIT 1;

--b

INSERT INTO airportsNew(name,geom,elev) VALUES
('airportB',10,(SELECT ST_Centroid(ST_ShortestLine(
(SELECT geom FROM airportsNew WHERE name LIKE 'ANNETTE ISLAND'), 
(SELECT geom FROM airportsNew WHERE name LIKE 'ATKA')
))));

SELECT * FROM airportsNew
	
--6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
--linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT ST_Area(ST_Buffer(ST_ShortestLine(lakes.geom, airportsNew.geom), 1000)) FROM lakes, airportsNew
WHERE airportsNew.name LIKE 'AMBLER'AND lakes.names LIKE 'Iliamna Lake'
	
--7. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
--poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps)

SELECT SUM(ST_Area(trees.geom)), trees.vegdesc FROM trees, tundra, swamp
WHERE ST_Within(trees.geom, tundra.geom) OR ST_Within(trees.geom, swamp.geom) GROUP BY trees.vegdesc