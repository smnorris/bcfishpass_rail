# bcfishpass_rail

Using `bcfishpass`, report on modelled impacts of railways to passage of Pacific Salmon and Steelhead in the Fraser basin.

## Methods

Reporting area includes all salmon streams in the Fraser Basin modelled by `bcfishpass` as accessible to Pacific Salmon and Steelhead (but is easily adjusted to include any area in BC modelled as supporting these species).

Report on:

- total length of railway
- total number of rail crossings
- total number of rail crossings modelled as potential barriers
- length of potential rearing/spawning stream for CH/CO/SK/ST above potential rail barriers (total and per barrier)
- length of potential rearing/spawning stream for CH/CO/SK/ST above potential barriers but below other potential/known anthropogenic barriers (total and per barrier)
- length of potential rearing/spawning stream for CH/CO/SK/ST below rail barriers but above other known/potential anthropogenic barriers
- number of road crossings upstream of rail crossings (total and per barrier)
- number of road crossings downstream of rail crossings (total and per barrier)
- area and percentage of potential lateral habitat modelled as disconnected


## Report

With the `bcfishpass` database loaded and set as your `$DATABASE_URL`, the report is a collection of queries:

    psql2csv sql/report.sql > rail_report.csv
