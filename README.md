CICERO Risk Model (CMR)
=======================
Kildekode for risikomodellen som er brukt i [infrarisk-prosjektet](http://infrarisk.ngi.no)

Installasjon
------------
For å kjøre modellen trenger du ArcGIS (10.1) og Microsoft SQL Server/SQL Server Express.
SQL Server Express skal følge med ArcGIS, men dersom du ikke har den installert kan du laste den ned fra (https://www.microsoft.com/en-us/sqlserver/editions/2012-editions/express.aspx).

Først:
- I ArcCatalog, gå til Database Servers. Legg til/åpne sqlserveren og opprett en ny geodatabase ved navn cmrGeo.
- Opprett så en SDE connection til databasen (i ArcCatalog, velg Add Spatial Database Connection, velg server (localhost), service (sde:sqlserver:localhost\sqlexpress) og database (cmrGeo), bruk Operating system authentication og test at connection fungerer (prøv deg litt frem så finner du ut av det).
- Gi connection et fornuftig navn.
- Kjør sql-scriptet (tsql/build_application.sql) i SQL server for å opprette de nødvendige tabeller etc. i databasen (bruk f.eks. SSMS - SQL Server Management Studio - for å kjøre scriptet)

Så:
- Åpne testprosjektet (example_data\example_data.mxd) i ArcMap
- Legg toolboxen (toolbox/CMR Toolbox.tbx) til i ArcMap.
Fra toolboxen i ArcGIS kan du kjøre Run CMR Model. Du får da opp en dialogboks. I denne må du velge:
- SDE Connection: SDE connection til databasen som du opprettet ista
- Study id (optional): en selvvalgt (numerisk) id for studieområdet ditt
- Study name og description: selvvalgt tekst som beskriver studiet
- Hazard zones: Feature layer med polygoner
- Process type id field: felt med en numerisk id som beskriver hva slags hazard det er snakk om (slås opp mot [proceesstype_id] tabellen cmrT_processType i databasen)
- Event frequency field: felt med returperiode (beklageligvis har jeg ikke tatt høyde for at returperioden kan være < 1)
- Input elements: Feature layer med polylines (typisk veger eller jernbane)
- Element type field: felt med elementtype (character), typisk 'EV', 'RV' osv (slås opp mot 'elementtype_code' i tabellen cmrT_ElementType)
- Route field: felt med en unik id (character) for ruter/strekninger
- AADT field: felt med AADT/ÅDT for persontrafikk
- AADT goods field: felt med AADT/ÅDT for godstrafikk
- Diversion time field: felt med omkjøringstid (bør være samme for alle objekter med samme rute)
- Output GDB: Path til en geodatabase der kartresultater skal lagres 

Modellen bruker et minutt eller to på å kjøre gjennom den romlige analysen, avhengig av hvor rask maskina di er.
Etter at modellen har kjørt ferdig skal den ha laget tre nye layers i legenden din:
- ear_<study_id> er identisk med input elements, men hver lenke er splittet opp langs faresonegrensene.
- elementSummary_<study_id> er en join mellom ear og viewet cmrV_elementSummary, den viser risiko/kostnader pr element
- routeSummary_<study_id> er en join mellom ear og viewet cmrV_routeSummary, den viser risiko/kostnader pr rute/strekning

Prøv deg frem med vise ulike atributter i de to summary lagene

Alle modellparametrene er spesifisert i databasen og kan endre/legge til parametere etter at du har kjørt modellen.
Det liggeret enkelt MS Access grensesnitt for å endre på parametere i pams_interface\cmrInterface.accdb. Her må du først få lenket opp tabellene til databasen (gå til External Data fanen og klikk på Linked table manager).
Endringer i parameterverdier vil gjenspeiles i resultatene umiddelbart (men i ArcGIS må man gjøre en oppfrisking mot databasen først).


Til slutt
-------------
Du må regne med å fikle litt med dette før du får det til å funke. Og når du har fått det til å funke så må du regne med å bruke et par dager på å forstå resultatene.
Modellen er laget for infrarisk prosjektet og den er ikke 100% generisk, det er sikkert ting som ikke passer helt til ditt behov. Send en epost dersom du har spørsmål.
