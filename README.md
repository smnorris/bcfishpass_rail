# bcfishpass_rail

Report on modelled impacts of railways to habitat connectivity for Pacific Salmon (Chinook, Chum, Coho, Pink, Sockeye) and Steelhead.

## Requirements

- requires `bcfishpass` and associated tools
- ensure the `$DATABASE_URL` environment variable points at the `bcfishpass` database of interest

## Prep data

- build `bcfishpass`, including lateral habitat model, modelling above noted species

- if `bcfishpass` included additional species modelling (eg `BT`), update totals to remove spawning/rearing for these species from stats (adapt/modify if any other non salmon/steelhead spawning/rearing are also included in the crossing_stats queries)

        # remove BT spawning and rearing output classification
        psql -c "update bcfishpass.streams set model_spawning_bt = null where model_spawning_bt is not null;"
        psql -c "update bcfishpass.streams set model_rearing_bt = null where model_rearing_bt is not null;"
        # with BT spawn/rear removed from streams table, update summaries for total spawning/rearing in 
        # the crossings tables
        rm .make/crossing_stats
        make .make/crossing_stats --debug=basic



## Run the reporting

    ./report.sh

See generated reports as csv in `/output`