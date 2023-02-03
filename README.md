# bcfishpass_rail

Report on modelled impacts of railways to habitat connectivity for Pacific Salmon (Chinook, Chum, Coho, Pink, Sockeye) and Steelhead

## Prep data

Load lower Fraser exclusion area (for lateral analysis, we exclude the Fraser Valley downstream of Agassiz)
    
    ogr2ogr -f PostgreSQL $DATABASE_URL \
    -lco OVERWRITE=YES \
    -t_srs EPSG:3005 \
    -s_srs EPSG:4326 \
    -lco SCHEMA=temp \
    -lco GEOMETRY_NAME=geom \
    -nln lateral_exclusion \
    -nlt PROMOTE_TO_MULTI \
    data/lower_fraser.geojson

## Running the reports

With the `bcfishpass` database loaded and set as your `$DATABASE_URL`, the report is a collection of queries:

We are reporting on salmon/steelhead only. Totals columns in the crossings/barriers tables include bull trout - before summarizing, remove BT spawn/rear and re-run point report

        psql -c "update bcfishpass.streams set model_spawning_bt = null where model_spawning_bt is not null;"

        psql -c "update bcfishpass.streams set model_rearing_bt = null where model_rearing_bt is not null;"

        # in bcfishpass folder, re-run point stats to ensure all_spawningrearing columns are 
        # cleared of any bull trout spawning/rearing totals
        rm .make/crossing_stats
        make .make/crossing_stats --debug=basic


Run reports:

        ./report.sh