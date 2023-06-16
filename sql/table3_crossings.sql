-- for table 3, column "c", we want 
-- "Spawning or rearing habitat upstream of rail barriers 
-- with no non-rail barriers downstream, to the next non-rail barrier (if any; km)"

-- finding the next non-rail barrier(s) upstream to make the net habitat calculation is tricky with
-- the fields in the crossings table. 
-- To make reporting simple, create two tables with required records/columns and run the load_dnstr function.

-- rail barriers with no barriers downstream
drop table if exists temp.table3_crossings;
create table temp.table3_crossings as
with rail as
(
  select a.aggregated_crossings_id,
    c.blue_line_key,
    c.downstream_route_measure,
    c.wscode_ltree,
    c.localcode_ltree,
    c.crossing_feature_type,
    c.geom
  from temp.table3_railbarriers a
  inner join bcfishpass.crossings c on a.aggregated_crossings_id = c.aggregated_crossings_id
  where a.non_rail_barriers_dnstr = 0
),

-- find all non-rail crossings upstream of barriers selected above (and on/dnstr of habitat)
nonrail_upstr as
(
  select distinct
    b.aggregated_crossings_id,
    b.blue_line_key,
    b.downstream_route_measure,
    b.wscode_ltree,
    b.localcode_ltree,
    b.crossing_feature_type,
    b.geom
  from temp.table3c_rail a
  inner join bcfishpass.crossings b
  on fwa_upstream(
    a.blue_line_key,
    a.downstream_route_measure,
    a.wscode_ltree,
    a.localcode_ltree,
    b.blue_line_key,
    b.downstream_route_measure,
    b.wscode_ltree,
    b.localcode_ltree,
    false,
    1
  )
  where b.barrier_status in ('BARRIER','POTENTIAL')
  and b.blue_line_key = b.watershed_key
  and b.crossing_feature_type != 'RAIL'
  and (
      b.ch_spawning_km > 0 or
      b.ch_rearing_km > 0 or
      b.cm_spawning_km > 0 or
      b.co_spawning_km > 0 or
      b.co_rearing_km > 0 or
      b.pk_spawning_km > 0 or
      b.sk_spawning_km > 0 or
      b.sk_rearing_km > 0 or
      b.st_spawning_km > 0 or
      b.st_rearing_km > 0
    )
),

-- combine all barriers into single set
barrierset as
(
  select * from rail
  union all
  select * from nonrail_upstr
),

-- index in order downstream
indexed as
(
  select
    aggregated_crossings_id,
    array_agg(downstream_id) filter (where downstream_id is not null) as features_dnstr
  from
      (select
          a.aggregated_crossings_id,
          b.aggregated_crossings_id as downstream_id
      from
          barrierset a
      inner join barrierset b on
      fwa_downstream(
          a.blue_line_key,
          a.downstream_route_measure,
          a.wscode_ltree,
          a.localcode_ltree,
          b.blue_line_key,
          b.downstream_route_measure,
          b.wscode_ltree,
          b.localcode_ltree,
          false,
          1
      )
      order by
        a.aggregated_crossings_id,
        b.wscode_ltree desc,
        b.localcode_ltree desc,
        b.downstream_route_measure desc
      ) as d
  group by aggregated_crossings_id
),

-- find the non-rail barriers that are immediately upstream of the rail barriers,
-- sum the habitat upstr
above_next_barriers as
(
  select
  r.aggregated_crossings_id,
  sum(c.all_spawningrearing_km) as all_spawningrearing_km
  from rail r
  inner join indexed i on r.aggregated_crossings_id = i.features_dnstr[1]
  inner join bcfishpass.crossings c on i.aggregated_crossings_id = c.aggregated_crossings_id
  group by r.aggregated_crossings_id
  order by r.aggregated_crossings_id
),

-- finally, find habitat upstream of the rail barriers and subtract that of non-rail barriers immediately upstream
column_c as
(
  select
    r.aggregated_crossings_id,
    round((c.all_spawningrearing_km - coalesce(a.all_spawningrearing_km, 0))::numeric, 2) as all_spawningrearing_belowupstrbarriers_km
  from rail r
  inner join bcfishpass.crossings c on r.aggregated_crossings_id = c.aggregated_crossings_id
  left outer join above_next_barriers a on r.aggregated_crossings_id = a.aggregated_crossings_id
)

-- table 3 crossings, all columns
select a.*, c.all_spawningrearing_belowupstrbarriers_km as spawningrearing_upstr_tonextbarrier
from temp.table3_railbarriers a
left outer join column_c c on a.aggregated_crossings_id = c.aggregated_crossings_id
order by a.aggregated_crossings_id
