infrarisk
=========

Kildekode for risikomodellen brukt i infrarisk-prosjektet, heretter kalt CMR (CICERO Multi Risk)

Installasjon
------------
For å kjøre modellen trenger du ArcGIS (10.1) og Microsoft SQL Server/SQL Server Express.
Du kan laste ned og installere MS SqlExpress gratis (herfra)[https://www.microsoft.com/en-us/sqlserver/editions/2012-editions/express.aspx].

Først:
-Opprett en ny database på SQL serveren (la oss kallen den cmr).
-Kjør sql-scriptet (tsql/build_application.sql) i SQL server for å opprette de nødvendige tabeller etc.
-Legg toolboxen (toolbox/CMR Toolbox.tbx) til i ArcGIS.

Fra toolboxen i ArcGIS kan du kjøre Run CMR Model. Du får da opp en dialogboks. I denne må du velge:
-SDE Connection: en connection til databasen du har opprettet på SQL serveren
-Study id (optional): en selvvalgt (numerisk) id for studieområdet ditt
-Study name og description: selvvalgt tekst som beskriver studiet
-Hazard zones: Feature layer med polygoner
-Process type id field: felt med en numerisk id som beskriver hva slags hazard det er snakk om (slås opp mot [proceesstype_id] tabellen cmrT_processType i databasen)
-Event frequency field: felt med returperiode (beklageligvis har jeg ikke tatt høyde for at returperioden kan være < 1)
-Input elements: Feature layer med polylines (typisk veger eller jernbane)
-Element type field: felt med elementtype (character), typisk 'EV', 'RV' osv (slås opp mot 'elementtype_code' i tabellen cmrT_ElementType)
-Route field: felt med en unik id (character) for ruter/strekninger
-AADT field: felt med AADT/ÅDT for persontrafikk
-AADT goods field: felt med AADT/ÅDT for godstrafikk
-Diversion time field: felt med omkjøringstid (bør være samme for alle objekter med samme rute)
-Output GDB (optional): Path til en geodatabase der kartresultater kan lagres 

Til slutt
-------------
Du må regne med å fikle litt med dette før du får det til å funke. Og, når du har fått det til å funke, så må du regne med å bruke et par dager på å forstå resultatene.
Modellen er laget for infrarisk prosjektet og den er ikke 100% generisk, det er sikkert ting som ikke passer helt til ditt behov. Send en epost dersom du har spørsmål, eller har forslag til endringer.


Du bør regne med å bruke et par dager på å skjønne hvordan dette funker. 
