#!/bin/bash
set -euxo pipefail

psql2csv $DATABASE_URL < sql/overview.sql > output/overview.csv
psql2csv $DATABASE_URL < sql/rail_crossings.sql > output/rail_crossings.csv


#psql $DATABASE_URL -f sql/lateral_potential_fraser.sql 
#psql $DATABASE_URL -c "select sum(st_area(geom)) / 10000 from temp.lateral_potential_fraser"
#psql $DATABASE_URL -c "select sum(st_area(geom)) / 10000 from temp.lateral_disconnected_fraser"
#psql $DATABASE_URL -c "select count(*) from temp.lateral_disconnected_fraser"
#psql $DATABASE_URL -c "select avg(st_area(geom) / 10000) from temp.lateral_disconnected_fraser"
#psql2csv $DATABASE_URL < sql/lateral_by_wsg.sql > lateral_area_by_wsg.csv
#psql2csv $DATABASE_URL < sql/sets_of_five.sql > rail_sets_of_five.csv
