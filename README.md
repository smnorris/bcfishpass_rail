# bcfishpass_rail

A sample collection of queries for `bcfishpass` reporting:

- report on modelled impacts of railways to habitat connectivity for salmon (Chinook, Coho, Steelhead) and Steelhead in the Fraser basin
- for the most part, queries can be adjusted to accomodate any supported feature type (eg, roads, dams), species, or area of interest

## Running the reports

With the `bcfishpass` database loaded and set as your `$DATABASE_URL`, the report is a collection of queries:

1. Generate a study area

        psql $DATABASE_URL -f sql/study_area.sql

2. Generate summaries per watershed group within study area, columns are described in `overview_columns.csv`

        psql2csv $DATABASE_URL < sql/overview.sql > overview.csv

3. Generate per-crossing report, , columns are described in `rail_crossings_columns.csv`

        psql2csv $DATABASE_URL < sql/rail_crossings.sql > rail_crossings.csv

4. Sumarize length modelled habitat in the study area, and the length/pct potentially inaccessible due to rail barriers (first query summarizes per watershed group, second is total for the entire study area)

        psql2csv $DATABASE_URL < sql/output1.sql > output1.csv
        psql2csv $DATABASE_URL < sql/output1_studyarea.sql > output1_studyarea.csv

5. Generate draft lateral habitat report

        psql2csv $DATABASE_URL sql/rail_lateral.sql > rail_lateral.csv
