#!/bin/bash
set -euxo pipefail

# create optimized (subdivided) study area geometries
psql $DATABASE_URL -f sql/rail_studyarea.sql  

# run linear habitat reports
psql $DATABASE_URL --csv < sql/overview.sql > output/overview.csv # not required but valuable for QA if needed
psql $DATABASE_URL --csv < sql/output1.sql > output/output1.csv
psql $DATABASE_URL --csv < sql/table2.sql > output/table2.csv
psql $DATABASE_URL < sql/table3_railbarriers.sql                                  # generate initial table
psql $DATABASE_URL --csv < sql/table3_crossings.sql                               # add first columns
psql $DATABASE_URL -c "select * from temp.table3_crossings" --csv > output/table3_crossings.csv # dump to file
psql $DATABASE_URL --csv < sql/table3.sql > output/table3.csv # list all crossings in table 3
psql $DATABASE_URL --csv < sql/rail_crossings.sql > output/rail_crossings.csv


# build lateral study area
# Load lower Fraser exclusion area (downstream of Agassiz is too developed for meaningful modelling)
ogr2ogr -f PostgreSQL $DATABASE_URL \
  -lco OVERWRITE=YES \
  -t_srs EPSG:3005 \
  -s_srs EPSG:4326 \
  -lco SCHEMA=temp \
  -lco GEOMETRY_NAME=geom \
  -nln lateral_exclusion \
  -nlt PROMOTE_TO_MULTI \
  data/lower_fraser.geojson
  
psql $DATABASE_URL -f sql/lateral_studyarea.sql

# lateral report
psql $DATABASE_URL --csv < sql/lateral_report.sql > output/lateral_report.csv

# summaries
psql $DATABASE_URL -c "drop table if exists temp.rail_studyarea_lateral_merged;
create table temp.rail_studyarea_lateral_merged
  as select 
    (st_dump(st_union(geom))).geom as geom
  from temp.rail_studyarea_lateral;
create index on temp.rail_studyarea_lateral using gist (geom);"
psql $DATABASE_URL --csv < sql/summary.sql > output/summary.csv