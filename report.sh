#!/bin/bash
set -euxo pipefail

# create optimized (subdivided) study area geometries
psql $DATABASE_URL -f sql/rail_studyarea.sql  

# run linear habitat reports
psql2csv $DATABASE_URL < sql/overview.sql > output/overview.csv # not required but valuable for QA if needed
psql2csv $DATABASE_URL < sql/output1.sql > output/output1.csv
psql2csv $DATABASE_URL < sql/table2.sql > output/table2.csv
psql2csv $DATABASE_URL < sql/rail_crossings.sql > output/rail_crossings.csv


# build lateral study area
# Load lower Fraser exclusion area (downstream of Agassiz is too developed for meaningful modelling)
#ogr2ogr -f PostgreSQL $DATABASE_URL \
#  -lco OVERWRITE=YES \
#  -t_srs EPSG:3005 \
#  -s_srs EPSG:4326 \
#  -lco SCHEMA=temp \
#  -lco GEOMETRY_NAME=geom \
#  -nln lateral_exclusion \
#  -nlt PROMOTE_TO_MULTI \
#  data/lower_fraser.geojson
  #
#psql $DATABASE_URL -f sql/lateral_studyarea.sql
#
## lateral report
#psql2csv $DATABASE_URL < sql/lateral_report.sql > output/lateral_report.csv
#
## summaries
#psql $DATBASE_URL -c "drop table if exists temp.rail_studyarea_lateral_merged;
#create table temp.rail_studyarea_lateral_merged
#  as select 
#    (st_dump(st_union(geom))).geom as geom
#  from temp.rail_studyarea_lateral;
#create index on temp.rail_studyarea_lateral using gist (geom);"
#psql2csv $DATABASE_URL < sql/summary.sql > output/summary.csv