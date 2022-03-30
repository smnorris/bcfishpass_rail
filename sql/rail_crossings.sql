-- per crossing report
select
  watershed_group_code,
  aggregated_crossings_id,
  modelled_crossing_id,
  stream_crossing_id,
  barrier_status,
  pscis_status,
  rail_track_name,
  rail_operator_english_name,
  pscis_stream_name,
  gnis_stream_name,
  barriers_anthropogenic_dnstr_count,
  barriers_anthropogenic_upstr_count,
  access_model_ch_co_sk,
  ch_co_sk_network_km,
  access_model_st,
  st_network_km,
  ch_spawning_km,
  ch_rearing_km,
  co_spawning_km,
  co_rearing_km,
  sk_spawning_km,
  sk_rearing_km,
  st_spawning_km,
  st_rearing_km,
  all_spawningrearing_km,
  all_spawningrearing_belowupstrbarriers_km
from bcfishpass.crossings
where watershed_group_code in (select distinct watershed_group_code from temp.rail_studyarea)
and crossing_feature_type = 'RAIL'
and barrier_status in ('BARRIER', 'POTENTIAL')
and (
  (
    ch_spawning_km  > 0 or
    ch_rearing_km  > 0 or
    co_spawning_km  > 0 or
    co_rearing_km  > 0 or
    sk_spawning_km  > 0 or
    sk_rearing_km  > 0 or
    st_spawning_km  > 0 or
    st_rearing_km > 0
  ) or
  (access_model_ch_co_sk is not null or access_model_st is not null)
)
order by watershed_group_code, aggregated_crossings_id;

