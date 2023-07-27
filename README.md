# bcfishpass_rail

Report on modelled impacts of railways to habitat connectivity for Pacific Salmon (Chinook, Chum, Coho, Pink, Sockeye) and Steelhead.

## Requirements

- requires `bcfishpass` and associated tools
- ensure the `$DATABASE_URL` environment variable points at the `bcfishpass` database of interest

## Prep data

- build `bcfishpass`, including lateral habitat model, modelling above noted species

- if `bcfishpass` included additional species modelling (eg `BT`), update totals to remove spawning/rearing for these species from stats (adapt/modify if any other non salmon/steelhead spawning/rearing are also included in the crossing_stats queries)

        # remove WCT/BT spawning and rearing output classification
        psql -c "update bcfishpass.streams set model_spawning_bt = null where model_spawning_bt is not null;"
        psql -c "update bcfishpass.streams set model_rearing_bt = null where model_rearing_bt is not null;"
        psql -c "update bcfishpass.streams set model_spawning_wct = null where model_spawning_wct is not null;"
        psql -c "update bcfishpass.streams set model_rearing_wct = null where model_rearing_wct is not null;"
        # with BT spawn/rear removed from streams table, update summaries for total spawning/rearing in 
        # the crossings tables
        rm .make/crossing_stats
        make .make/crossing_stats --debug=basic



## Run the reporting

    ./report.sh

See generated reports as csv in `/output`


## Archive data

So we have something to refer back to, dump most of the database to file:

    pg_dump -Fc $DATABASE_URL -T whse_basemapping.fwa* -T whse_basemapping.trim -N bcfishpass_ccira -N psf -N usgs -N whse_admin_boundaries -N whse_cadastre -N whse_forest_vegetation -N whse_legal_admin_boundaries > data/bcfishpass_rail_2023-07-26.dump