# bcfishpass_rail

A sample collection of queries for `bcfishpass` reporting:

- report on modelled impacts of railways to habitat connectivity for salmon (Chinook, Coho, Steelhead) and Steelhead in the Fraser basin
- for the most part, reporting be adjusted to accomodate any supported feature type (eg, roads, dams), species, or area of interest

## Running the reports

With the `bcfishpass` database loaded and set as your `$DATABASE_URL`, the report is a collection of queries:

1. Generate a study area

        psql $DATABASE_URL -c sql/study_area.sql


2. Generate summaries per watershed group within study area

        psql2csv $DATABASE_URL sql/overview.sql > overview.csv

3. Generate per-crossing report

        psql2csv $DATABASE_URL sql/rail_crossings.sql > rail_crossings.csv

4. Generate draft lateral habitat report

        psql2csv $DATABASE_URL sql/rail_lateral.sql > rail_lateral.csv


## General reporting metrics

- total length of railway
- total number of rail crossings
- total number of rail crossings modelled as potential barriers
- total number of rail crossings modelled as potential barriers on potentially accessible CH/CO/SK/ST streams and potential spawning/rearing streams
- length of potential rearing/spawning stream for CH/CO/SK/ST above potential rail barriers
- length of potential rearing/spawning stream for CH/CO/SK/ST above potential barriers but below other potential/known anthropogenic barriers
- length of potential rearing/spawning stream for CH/CO/SK/ST below rail barriers but above other known/potential anthropogenic barriers
- number of road crossings upstream of rail crossings (total and per barrier)
- number of road crossings downstream of rail crossings (total and per barrier)
- area and percentage of potential lateral habitat modelled as disconnected






