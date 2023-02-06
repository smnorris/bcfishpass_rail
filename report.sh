#!/bin/bash
set -euxo pipefail

psql $DATABASE_URL sql/rail_studyarea.sql  # create optimized (subdivided) study area geometries

psql2csv $DATABASE_URL < sql/overview.sql > output/overview.csv # not required but valuable for QA if needed
psql2csv $DATABASE_URL < sql/output1.sql > output/output1.csv
psql2csv $DATABASE_URL < sql/rail_crossings.sql > output/rail_crossings.csv


psql $DATABASE_URL -f sql/lateral_studyarea.sql

psql $DATABASE_URL -c "select sum(st_area(geom)) / 10000 from bcfishpass.habitat_lateral"
psql $DATABASE_URL -c "select sum(st_area(geom)) / 10000 from bcfishpass.habitat_lateral_disconnected_rail"
psql $DATABASE_URL -c "select count(*) from bcfishpass.habitat_lateral_disconnected_rail"
psql $DATABASE_URL -c "select avg(st_area(geom) / 10000) from bcfishpass.habitat_lateral_disconnected_rail"
psql2csv $DATABASE_URL < sql/lateral_report.sql > output/lateral_report.csv

