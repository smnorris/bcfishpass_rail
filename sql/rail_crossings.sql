-- per barrier report
-- extract rail barriers on potentially accessible streams within study area
with xings as
(
  select *
 
  from bcfishpass.crossings
  where
    watershed_group_code in (
      select distinct watershed_group_code from temp.rail_studyarea
    )
    and crossing_feature_type = 'RAIL'
    and barrier_status in ('BARRIER', 'POTENTIAL')
    and (barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] or barriers_st_dnstr = array[]::text[] )
),

-- list other rail crossings dnstr
rail_barriers_dnstr as
(
  select
    a.aggregated_crossings_id,
    array_agg(b.aggregated_crossings_id) as rail_barriers_dnstr,
    array_length(array_agg(b.aggregated_crossings_id), 1) as rail_barriers_dnstr_count
  from xings a
  inner join xings b
  on FWA_Downstream(
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
  group by a.aggregated_crossings_id
),

-- find crossings upstream on potentially accessible streams
-- (this is not currently in the crossings table, should be added)
xings_upstr as
(
  select
    a.aggregated_crossings_id,
    count(b.aggregated_crossings_id) filter (
      where b.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] or b.barriers_st_dnstr = array[]::text[] 
      ) as barriers_anthropogenic_upstr_accessible_count,
    count(b.aggregated_crossings_id) filter (
      where
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
      ) as barriers_anthropogenic_upstr_spawningrearing_count,
    count(b.aggregated_crossings_id) filter (
      where b.crossing_feature_type = 'RAIL' and
        (b.ch_spawning_km > 0 or
        b.ch_rearing_km > 0 or
        b.cm_spawning_km > 0 or
        b.co_spawning_km > 0 or
        b.co_rearing_km > 0 or
        b.pk_spawning_km > 0 or
        b.sk_spawning_km > 0 or
        b.sk_rearing_km > 0 or
        b.st_spawning_km > 0 or
        b.st_rearing_km > 0)
      ) as barriers_anthropogenic_upstr_spawningrearing_rail_count
  from xings a
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
  group by a.aggregated_crossings_id
),

hab_dnstr as
(
  select
    a.aggregated_crossings_id,
    sum(b.ch_cm_co_pk_sk_belowupstrbarriers_network_km) as ch_cm_co_pk_sk_network_km_dnstr,
    sum(b.st_belowupstrbarriers_network_km) as st_network_km_dnstr,
    sum(b.cm_spawning_belowupstrbarriers_km) as cm_spawning_km_dnstr,
    sum(b.ch_spawning_belowupstrbarriers_km) as ch_spawning_km_dnstr,
    sum(b.ch_rearing_belowupstrbarriers_km) as ch_rearing_km_dnstr,
    sum(b.co_spawning_belowupstrbarriers_km) as co_spawning_km_dnstr,
    sum(b.co_rearing_belowupstrbarriers_km) as co_rearing_km_dnstr,
    sum(b.pk_spawning_belowupstrbarriers_km) as pk_spawning_km_dnstr,
    sum(b.sk_spawning_belowupstrbarriers_km) as sk_spawning_km_dnstr,
    sum(b.sk_rearing_belowupstrbarriers_km) as sk_rearing_km_dnstr,
    sum(b.st_spawning_belowupstrbarriers_km) as st_spawning_km_dnstr,
    sum(b.st_rearing_belowupstrbarriers_km) as st_rearing_km_dnstr,
    sum(b.all_spawningrearing_belowupstrbarriers_km) as all_spawningrearing_km_dnstr
  from xings a
  inner join bcfishpass.crossings b
  on FWA_Downstream(
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
  group by a.aggregated_crossings_id
)

select
  a.watershed_group_code,
  a.aggregated_crossings_id,
  a.modelled_crossing_id,
  a.stream_crossing_id,
  a.barrier_status,
  a.pscis_status,
  a.pscis_road_name,
  a.rail_track_name,
  a.rail_operator_english_name,
  a.pscis_stream_name,
  a.gnis_stream_name,
  a.stream_order,
  s.stream_order_parent,
  d.rail_barriers_dnstr,
  d.rail_barriers_dnstr_count,
  a.barriers_anthropogenic_dnstr_count,
  a.barriers_anthropogenic_upstr_count,
  coalesce(b.barriers_anthropogenic_upstr_accessible_count, 0) as barriers_anthropogenic_upstr_accessible_count,
  coalesce(b.barriers_anthropogenic_upstr_spawningrearing_count, 0) as barriers_anthropogenic_upstr_spawningrearing_count,
  coalesce(b.barriers_anthropogenic_upstr_spawningrearing_rail_count, 0) as barriers_anthropogenic_upstr_spawningrearing_rail_count,
  a.barriers_ch_cm_co_pk_sk_dnstr,
  a.ch_cm_co_pk_sk_network_km,
  a.barriers_st_dnstr,
  a.st_network_km,
  a.ch_spawning_km,
  a.ch_rearing_km,
  a.cm_spawning_km,
  a.co_spawning_km,
  a.co_rearing_km,
  a.pk_spawning_km,
  a.sk_spawning_km,
  a.sk_rearing_km,
  a.st_spawning_km,
  a.st_rearing_km,
  a.all_spawningrearing_km,
  a.all_spawningrearing_belowupstrbarriers_km,
  c.ch_cm_co_pk_sk_network_km_dnstr,
  c.st_network_km_dnstr,
  c.ch_spawning_km_dnstr,
  c.ch_rearing_km_dnstr,
  c.cm_spawning_km_dnstr,
  c.co_spawning_km_dnstr,
  c.co_rearing_km_dnstr,
  c.pk_spawning_km_dnstr,
  c.sk_spawning_km_dnstr,
  c.sk_rearing_km_dnstr,
  c.st_spawning_km_dnstr,
  c.st_rearing_km_dnstr,
  c.all_spawningrearing_km_dnstr
from xings a
left outer join xings_upstr b
on a.aggregated_crossings_id = b.aggregated_crossings_id
left outer join hab_dnstr c
on a.aggregated_crossings_id = c.aggregated_crossings_id
left outer join rail_barriers_dnstr d
on a.aggregated_crossings_id = d.aggregated_crossings_id
inner join bcfishpass.streams s
on a.linear_feature_id = s.linear_feature_id
  and a.downstream_route_measure > (s.downstream_route_measure - .001)
  and (a.downstream_route_measure + .001) < s.upstream_route_measure
order by watershed_group_code, aggregated_crossings_id;

