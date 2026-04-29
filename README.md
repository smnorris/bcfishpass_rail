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

        # fix error in CM spawning habitat
        psql -c "update bcfishpass.streams set model_spawning_cm = False where blue_line_key = 360846255;
        
        update bcfishpass.crossings set cm_spawning_km = 0 where aggregated_crossings_id = '1012401286';
        update bcfishpass.crossings set cm_spawning_belowupstrbarriers_km = 0 where aggregated_crossings_id = '1012401286';
        update bcfishpass.crossings set all_spawning_km = 0 where aggregated_crossings_id = '1012401286';
        update bcfishpass.crossings set all_spawning_belowupstrbarriers_km = 0 where aggregated_crossings_id = '1012401286';
        update bcfishpass.crossings set all_spawningrearing_km = 0 where aggregated_crossings_id = '1012401286';
        update bcfishpass.crossings set all_spawningrearing_belowupstrbarriers_km = 0 where aggregated_crossings_id = '1012401286';
        update bcfishpass.crossings set all_spawningrearing_per_barrier = 0 where aggregated_crossings_id = '1012401286';
        update bcfishpass.barriers_anthropogenic set cm_spawning_km = 0 where barriers_anthropogenic_id = '1012401286';
        update bcfishpass.barriers_anthropogenic set cm_spawning_belowupstrbarriers_km = 0 where barriers_anthropogenic_id = '1012401286';
        update bcfishpass.barriers_anthropogenic set all_spawning_km = 0 where barriers_anthropogenic_id = '1012401286';
        update bcfishpass.barriers_anthropogenic set all_spawning_belowupstrbarriers_km = 0 where barriers_anthropogenic_id = '1012401286';
        update bcfishpass.barriers_anthropogenic set all_spawningrearing_km = 0 where barriers_anthropogenic_id = '1012401286';
        update bcfishpass.barriers_anthropogenic set all_spawningrearing_belowupstrbarriers_km = 0 where barriers_anthropogenic_id = '1012401286';"

## Run the reporting

    ./report.sh

See generated reports as csv in `/output`


## Archive data

So we have something to refer back to, dump most of the database to file:

    pg_dump -Fc $DATABASE_URL -T whse_basemapping.fwa* -T whse_basemapping.trim -N bcfishpass_ccira -N psf -N usgs -N whse_admin_boundaries -N whse_cadastre -N whse_forest_vegetation -N whse_legal_admin_boundaries > data/bcfishpass_rail_2023-07-26.dump