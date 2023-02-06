# bcfishpass_rail

Report on modelled impacts of railways to habitat connectivity for Pacific Salmon (Chinook, Chum, Coho, Pink, Sockeye) and Steelhead.

## Requirements

- requires `bcfishpass` and associated tools
- ensure the `$DATABASE_URL` environment variable points at the `bcfishpass` database of interest

## Prep data

- build `bcfishpass`, including lateral habitat model

- if `bcfishpass` inluded `BT` modelling, update totals to remove `BT` values from streams spawning/rearing and re-run crossing stats 
(adapt/modify if any other non salmon/steelhead spawning/rearing are also included in the crossing_stats queries)

        # in bcfishpass folder
        psql -c "update bcfishpass.streams set model_spawning_bt = null where model_spawning_bt is not null;"
        psql -c "update bcfishpass.streams set model_rearing_bt = null where model_rearing_bt is not null;"
        rm .make/crossing_stats
        make .make/crossing_stats --debug=basic



## Run the reporting

    ./report.sh