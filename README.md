# bcfishpass_rail

A sample collection of queries for `bcfishpass` reporting:

- report on modelled impacts of railways to habitat connectivity for salmon (Chinook, Coho, Steelhead) and Steelhead in the Fraser basin
- for the most part, reporting be adjusted to accomodate any supported feature type (eg, roads, dams), species, or area of interest

## Running the reports

With the `bcfishpass` database loaded and set as your `$DATABASE_URL`, the report is a collection of queries:

1. Generate a study area

        psql $DATABASE_URL -f sql/study_area.sql

2. Generate summaries per watershed group within study area

        psql2csv $DATABASE_URL < sql/overview.sql > overview.csv

3. Generate per-crossing report

        psql2csv $DATABASE_URL < sql/rail_crossings.sql > rail_crossings.csv

4. Generate data for `Output 1` table, per watershed group, and total for study area:

        psql2csv $DATABASE_URL < sql/output1.sql > output1.csv
        psql2csv $DATABASE_URL < sql/output1_studyarea.sql > output1_studyarea.csv

5. Generate draft lateral habitat report

        psql2csv $DATABASE_URL sql/rail_lateral.sql > rail_lateral.csv
