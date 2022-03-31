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
    and (access_model_ch_co_sk is not null or access_model_st is not null)
),

-- find crossings upstream on potentially accessible streams
-- (this is not currently in the crossings table, should be added)
xings_upstr as
(
  select
    a.aggregated_crossings_id,
    count(b.aggregated_crossings_id) filter (
      where b.access_model_ch_co_sk is not null or b.access_model_st is not null
      ) as barriers_anthropogenic_upstr_accessible_count,
    count(b.aggregated_crossings_id) filter (
      where
        b.ch_spawning_km > 0 or
        b.ch_rearing_km > 0 or
        b.co_spawning_km > 0 or
        b.co_rearing_km > 0 or
        b.sk_spawning_km > 0 or
        b.sk_rearing_km > 0 or
        b.st_spawning_km > 0 or
        b.st_rearing_km > 0
      ) as barriers_anthropogenic_upstr_spawningrearing_count
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
)

select
  a.watershed_group_code,
  a.aggregated_crossings_id,
  a.modelled_crossing_id,
  a.stream_crossing_id,
  a.barrier_status,
  a.pscis_status,
  a.rail_track_name,
  a.rail_operator_english_name,
  a.pscis_stream_name,
  a.gnis_stream_name,
  a.stream_order,
  po.stream_order_parent,
  a.barriers_anthropogenic_dnstr_count,
  a.barriers_anthropogenic_upstr_count,
  coalesce(b.barriers_anthropogenic_upstr_accessible_count, 0) as barriers_anthropogenic_upstr_accessible_count,
  coalesce(b.barriers_anthropogenic_upstr_spawningrearing_count, 0) as barriers_anthropogenic_upstr_spawningrearing_count,
  a.access_model_ch_co_sk,
  a.ch_co_sk_network_km,
  a.access_model_st,
  a.st_network_km,
  a.ch_spawning_km,
  a.ch_rearing_km,
  a.co_spawning_km,
  a.co_rearing_km,
  a.sk_spawning_km,
  a.sk_rearing_km,
  a.st_spawning_km,
  a.st_rearing_km,
  a.all_spawningrearing_km,
  a.all_spawningrearing_belowupstrbarriers_km
from xings a
left outer join xings_upstr b
on a.aggregated_crossings_id = b.aggregated_crossings_id
left outer join whse_basemapping.fwa_stream_order_parent po
on a.blue_line_key = po.blue_line_key
inner join bcfishpass.streams s
on a.linear_feature_id = s.linear_feature_id
  and a.downstream_route_measure > (s.downstream_route_measure - .001)
  and (a.downstream_route_measure + .001) < s.upstream_route_measure
order by watershed_group_code, aggregated_crossings_id;

