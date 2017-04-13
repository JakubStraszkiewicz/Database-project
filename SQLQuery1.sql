CREATE TABLE firmy(
NIP CHAR(10) PRIMARY KEY,
nazwa VARCHAR(50) not null,
miasto VARCHAR(30) not null,
ulica VARCHAR(30) not null
);

CREATE TABLE pracownicy(
PESEL CHAR(11) PRIMARY KEY,
imie  VARCHAR(20) not null,
nazwisko VARCHAR(50) not null,
data_urodzenia DATE not null,
stanowisko VARCHAR(20) not null,
ilosc_godzin_w_pracy_dziennie int CHECK (ilosc_godzin_w_pracy_dziennie between 1 and 24),
firma CHAR(10) REFERENCES firmy ON DELETE cascade not null /*przy usuwaniu firmy usuwam wszystkich pracownikow firmy*/
);

CREATE TABLE faktury(
nr_faktury VARCHAR(30) PRIMARY KEY,
data_wystawienia DATE not null,
forma_platnosci VARCHAR(30) not null,
pracownik CHAR(11) REFERENCES pracownicy ON DELETE SET NULL /*moge usunac pracownikow nie moge usunac faktur ustawiam referencje na null*/
);

CREATE TABLE towary(
ID INT IDENTITY(1,1) PRIMARY KEY,
nazwa VARCHAR(256) not null,
cena DECIMAL(10,2) not null
);

CREATE TABLE PozFak(
Lp INT IDENTITY(1,1),
nr_faktury VARCHAR(30) REFERENCES faktury ON DELETE cascade, /*gdy usuwam fakture usuwam wszystkie pozycje tej faktury*/
PRIMARY KEY(Lp,nr_faktury),
cena_jednostkowa DECIMAL(10,2) not null,
ilosc int CHECK(ilosc between 1 and 1000) not null,
stawka_vat int CHECK(stawka_vat between 0 and 23) not null,
wartosc_brutto DECIMAL(10,2) not null,
towar INT REFERENCES towary not null
);

CREATE TABLE pomocnicza(
ID INT IDENTITY(1,1) PRIMARY KEY,
Lp_pom INT,
nr_faktury_pom VARCHAR(30),
FOREIGN KEY(Lp_pom,nr_faktury_pom) REFERENCES PozFak
);




CREATE TABLE pensje(
ID INT IDENTITY(1,1) PRIMARY KEY,
wartosc_brutto DECIMAL(10,2) not null,
wartosc_netto DECIMAL(10,2) not null
);

CREATE TABLE pobory(
ID INT IDENTITY(1,1) PRIMARY KEY,
data_wydania DATE not null,
forma_platnosci VARCHAR(30) not null,
wartosc_brutto DECIMAL(10,2) not null,
wartosc_netto DECIMAL(10,2) not null, 
pracownik CHAR(11) REFERENCES pracownicy ON DELETE cascade, /*jesli usuwa sie pracownik usuwa sie wszystkie jego pobory*/
pensja INT REFERENCES pensje 
);

CREATE TABLE podatki(
nazwa_podatku VARCHAR(256) PRIMARY KEY,
nazwa_urzedu VARCHAR(256) not null,
wartosc	DECIMAL(10,2) not null
);

CREATE TABLE dodatki(
ID INT IDENTITY(1,1) PRIMARY KEY,
wartosc	DECIMAL(10,2) not null,
na_plus_czy_minus BIT not null
);

CREATE TABLE DodPob(
pobor INT REFERENCES pobory ON DELETE cascade not null, 
dodatek INT REFERENCES dodatki ON DELETE cascade,
PRIMARY KEY(pobor,dodatek)
);

CREATE TABLE PodPob(
pobor INT REFERENCES pobory ON DELETE cascade not null,
podatek VARCHAR(256) REFERENCES podatki ON DELETE cascade not null,
PRIMARY KEY(pobor,podatek)
);
ALTER TABLE dodatki ADD opis VARCHAR(1024);




SELECT firmy.NIP,firmy.nazwa,COUNT(pracownicy.firma)
FROM firmy
JOIN pracownicy on firmy.NIP=pracownicy.firma
GROUP BY firmy.NIP,firmy.nazwa
HAVING COUNT(pracownicy.firma)>=3
/* wypisanie wszystkich firm ktore posiadaja wiecej niz 2 pracownikow*/

SELECT pracownicy.imie,pracownicy.nazwisko,pracownicy.ilosc_godzin_w_pracy_dziennie
FROM pracownicy
WHERE ilosc_godzin_w_pracy_dziennie>=(
										SELECT AVG(ilosc_godzin_w_pracy_dziennie) 
										FROM pracownicy)
ORDER BY ilosc_godzin_w_pracy_dziennie;
/*wypisanie pracownikow ktorzy pracuja dluzej niz srednia i grupowac ich od pracujacych najmniej*/

SELECT firmy.nazwa,SUM(pobory.wartosc_brutto)
FROM pobory
JOIN pracownicy on pracownicy.PESEL=pobory.pracownik
JOIN firmy on firmy.NIP=pracownicy.firma
GROUP BY nazwa
/*zwraca sumy wszystkich poborow pracownikow z danych firm*/


SELECT PESEL,imie,nazwisko,MIN(pobory.wartosc_brutto) AS Najmniejsza,MAX(pobory.wartosc_brutto) AS Najwieksza,AVG(pobory.wartosc_brutto) AS Srednia
FROM pobory
JOIN pracownicy ON pobory.pracownik=pracownicy.PESEL
GROUP BY imie,nazwisko,PESEL
ORDER BY nazwisko
/*zwraca najmniejsza,najwieksza i srednia wartosc poboru dla poszczegolnych pracownikow*/

CREATE VIEW widoczek
AS SELECT PESEL,imie,nazwisko,wartosc_brutto,wartosc_netto
	FROM pracownicy JOIN pobory ON pracownicy.PESEL = pobory.pracownik

SELECT PESEL,imie,nazwisko,SUM(wartosc_brutto) AS wartosc_brutto, SUM(wartosc_netto) AS wartosc_netto
FROM widoczek
GROUP BY PESEL,imie,nazwisko
ORDER BY nazwisko
/*zwraca sumy poborow danych osob netto i brutto*/

SELECT imie,nazwisko,SUM(dodatki.wartosc) AS suma_dodatkow,SUM(podatki.wartosc) AS suma_podatkow
FROM pracownicy 
	JOIN pobory ON pracownicy.PESEL=pobory.pracownik
	JOIN DodPob ON DodPob.pobor = pobory.ID
	JOIN dodatki ON dodatki.ID = DodPob.dodatek
	JOIN PodPob ON PodPob.pobor = pobory.ID
	JOIN podatki ON podatki.nazwa_podatku = PodPob.podatek
GROUP BY imie,nazwisko
ORDER BY nazwisko
/*zwraca sumy dodatkow i podatkow pracownikow*/

