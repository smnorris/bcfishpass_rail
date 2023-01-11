with studyarea as 
( select distinct
  watershed_group_code
  from bcfishpass.crossings 
  where 
    crossing_feature_type = 'RAIL' and 
    (wscode_ltree <@ '100'::ltree or watershed_group_code = 'LFRA') and
    (barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] or barriers_st_dnstr array[]::text[])  
),

totals as
(select
 watershed_group_code,
 round((sum(st_length(geom)) filter (where model_spawning_ch is true) / 1000 )::numeric, 2)  ch_spawning_km_total,
 round((sum(st_length(geom)) filter (where model_rearing_ch is true) / 1000 )::numeric, 2) ch_rearing_km_total,
 round((sum(st_length(geom)) filter (where model_spawning_co is true) / 1000)::numeric, 2)  co_spawning_km_total,
 round((sum(st_length(geom)) filter (where model_rearing_co is true) / 1000)::numeric, 2) co_rearing_km_total,

 round((sum(st_length(geom)) filter (where model_spawning_sk is true) / 1000)::numeric, 2)  sk_spawning_km_total,
 round((sum(st_length(geom)) filter (where model_rearing_sk is true) / 1000)::numeric, 2) sk_rearing_km_total,

 round((sum(st_length(geom)) filter (where model_spawning_st is true) / 1000)::numeric, 2)  st_spawning_km_total,
 round((sum(st_length(geom)) filter (where model_rearing_st is true) / 1000)::numeric, 2) st_rearing_km_total
from bcfishpass.streams
where watershed_group_code in (select watershed_group_code from studyarea)
and stream_order < 8
group by watershed_group_code),

rail_barriers as
(
  select
    aggregated_crossings_id,
    watershed_group_code,
    blue_line_key,
    downstream_route_measure,
    wscode_ltree,
    localcode_ltree,
    ch_spawning_km ,
    ch_rearing_km ,
    cm_spawning_km ,
    co_spawning_km ,
    co_rearing_km ,
    pk_spawning_km ,
    sk_spawning_km ,
    sk_rearing_km ,
    st_spawning_km ,
    st_rearing_km
  from bcfishpass.crossings
  where watershed_group_code in (select watershed_group_code from studyarea)
  and crossing_feature_type = 'RAIL'
  and barrier_status in ('BARRIER', 'POTENTIAL')
),

potentially_blocked as (
  select
  a.watershed_group_code,
  round((sum(a.ch_spawning_km))::numeric, 2) as ch_spawning_km,
  round((sum(a.ch_rearing_km))::numeric, 2) as ch_rearing_km,
  round((sum(a.cm_spawning_km))::numeric, 2) as cm_spawning_km,
  round((sum(a.co_spawning_km))::numeric, 2) as co_spawning_km,
  round((sum(a.co_rearing_km))::numeric, 2) as co_rearing_km,
  round((sum(a.pk_spawning_km))::numeric, 2) as pk_spawning_km,
  round((sum(a.sk_spawning_km))::numeric, 2) as sk_spawning_km,
  round((sum(a.sk_rearing_km))::numeric, 2) as sk_rearing_km,
  round((sum(a.st_spawning_km))::numeric, 2) as st_spawning_km,
  round((sum(a.st_rearing_km))::numeric, 2) as st_rearing_km
from rail_barriers a
left outer join rail_barriers b
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

where (
a.ch_spawning_km  > 0 or
a.ch_rearing_km  > 0 or
a.cm_spawning_km  > 0 or
a.co_spawning_km  > 0 or
a.co_rearing_km  > 0 or
a.pk_spawning_km  > 0 or
a.sk_spawning_km  > 0 or
a.sk_rearing_km  > 0 or
a.st_spawning_km  > 0 or
a.st_rearing_km > 0)
and b.aggregated_crossings_id is null
group by
  a.watershed_group_code
order by watershed_group_code)

select
 a.watershed_group_code,
 a.ch_spawning_km_total,
 b.ch_spawning_km as ch_spawning_km_aboverail,
 round(((b.ch_spawning_km / a.ch_spawning_km_total) * 100)::numeric, 2) as ch_spawning_aboverailxing_pct,
 a.ch_rearing_km_total,
 b.ch_rearing_km as ch_rearing_km_aboverail,
 round(((b.ch_rearing_km / a.ch_rearing_km_total) * 100)::numeric, 2) as ch_rearing_aboverailxing_pct,

 a.cm_spawning_km_total,
 b.cm_spawning_km as cm_spawning_km_aboverail,
 round(((b.cm_spawning_km / a.cm_spawning_km_total) * 100)::numeric, 2) as cm_spawning_aboverailxing_pct,

 a.co_spawning_km_total,
 b.co_spawning_km as co_spawning_km_aboverail,
 round(((b.co_spawning_km / a.co_spawning_km_total) * 100)::numeric, 2) as co_spawning_aboverailxing_pct,
 a.co_rearing_km_total,
 b.co_rearing_km as co_rearing_km_aboverail,
 round(((b.co_rearing_km / a.co_rearing_km_total) * 100)::numeric, 2) as co_rearing_aboverailxing_pct,

 a.pk_spawning_km_total,
 b.pk_spawning_km as pk_spawning_km_aboverail,
 round(((b.pk_spawning_km / a.pk_spawning_km_total) * 100)::numeric, 2) as pk_spawning_aboverailxing_pct,

 a.sk_spawning_km_total,
 b.sk_spawning_km as sk_spawning_km_aboverail,
 round(((b.sk_spawning_km / a.sk_spawning_km_total) * 100)::numeric, 2) as sk_spawning_aboverailxing_pct,
 a.sk_rearing_km_total,
 b.sk_rearing_km as sk_rearing_km_aboverail,
 round(((b.sk_rearing_km / a.sk_rearing_km_total) * 100)::numeric, 2) as sk_rearing_aboverailxing_pct,

 a.st_spawning_km_total,
 b.st_spawning_km as st_spawning_km_aboverail,
 round(((b.st_spawning_km / a.st_spawning_km_total) * 100)::numeric, 2) as st_spawning_aboverailxing_pct,
 a.st_rearing_km_total,
 b.st_rearing_km as st_rearing_km_aboverail,
 round(((b.st_rearing_km / a.st_rearing_km_total) * 100)::numeric, 2) as st_rearing_aboverailxing_pct
from totals a
left outer join potentially_blocked b
on a.watershed_group_code = b.watershed_group_code
order by a.watershed_group_code;