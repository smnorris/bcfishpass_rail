-- report on length and count of crossings in study area, per watershed group

with rail_overlay as
(
  select
    n.watershed_group_code,
    case
      when st_coveredby(p.geom, n.geom) then p.geom
      else st_multi(st_intersection(p.geom,n.geom))
    end as geom
  from whse_basemapping.gba_railway_tracks_sp as p
  inner join temp.rail_studyarea as n
  on st_intersects(p.geom, n.geom)
),

-- Total rail network length in study area
length_rail as
(
select
  watershed_group_code,
  round((sum(st_length(geom)) / 1000)::numeric, 2) as length_rail_km
from rail_overlay
group by watershed_group_code
),

-- count of crossings by type
count_xings as
(
  select
    sa.watershed_group_code,
    count(c.*) filter (where c.crossing_feature_type = 'RAIL' ) as n_rail_crossings,
    count(c.*) filter (where c.crossing_feature_type = 'RAIL' and (c.access_model_ch_co_sk is not null or c.access_model_st is not null)) as n_rail_crossings_potentially_accessible,
    count(c.*) filter (where
             c.crossing_feature_type = 'RAIL' and
             (c.access_model_ch_co_sk is not null or c.access_model_st is not null) and
             barrier_status in ('BARRIER', 'POTENTIAL')
             ) as n_rail_crossings_potentially_accessible_potential_barriers,

    count(c.*) filter (where c.crossing_feature_type like 'ROAD%' ) as n_road_crossings,
    count(c.*) filter (where c.crossing_feature_type like 'ROAD%' and (c.access_model_ch_co_sk is not null or c.access_model_st is not null)) as n_road_crossings_potentially_accessible,
    count(c.*) filter (where
             c.crossing_feature_type like 'ROAD%' and
             (c.access_model_ch_co_sk is not null or c.access_model_st is not null) and
             barrier_status in ('BARRIER', 'POTENTIAL')
             ) as n_road_crossings_potentially_accessible_potential_barriers,

    count(c.*) filter (where c.crossing_feature_type = 'TRAIL' ) as n_trail_crossings,
    count(c.*) filter (where c.crossing_feature_type = 'TRAIL' and (c.access_model_ch_co_sk is not null or c.access_model_st is not null)) as n_trail_crossings_potentially_accessible,
    count(c.*) filter (where
             c.crossing_feature_type = 'TRAIL' and
             (c.access_model_ch_co_sk is not null or c.access_model_st is not null) and
             barrier_status in ('BARRIER', 'POTENTIAL')
             ) as n_trail_crossings_potentially_accessible_potential_barriers,

    count(c.*) filter (where c.crossing_feature_type IN ('DAM','WEIR') ) as n_dams,
    count(c.*) filter (where c.crossing_feature_type IN ('DAM','WEIR') and (c.access_model_ch_co_sk is not null or c.access_model_st is not null)) as n_dams_potentially_accessible,
    count(c.*) filter (where
             c.crossing_feature_type IN ('DAM','WEIR') and
             (c.access_model_ch_co_sk is not null or c.access_model_st is not null) and
             barrier_status in ('BARRIER', 'POTENTIAL')
             ) as n_dams_potentially_accessible_potential_barriers
  from temp.rail_studyarea sa
  inner join bcfishpass.crossings c on st_within(c.geom, sa.geom)
  group by sa.watershed_group_code
),

-- length of stream
stream_length as
(
  select
    watershed_group_code,
    coalesce(round((sum(st_length(s.geom)))::numeric, 2))  as stream_km,
    coalesce(round(((sum(st_length(s.geom)) filter (where access_model_ch_co_sk is not null or access_model_st is not null)) / 1000)::numeric, 2), 0) as stream_potentially_accessible_km,
    round((sum(st_length(s.geom)) filter (where s.spawning_model_ch is true) / 1000 )::numeric, 2)  stream_ch_spawning_km,
    round((sum(st_length(s.geom)) filter (where s.rearing_model_ch is true) / 1000 )::numeric, 2) stream_ch_rearing_km,
    round((sum(st_length(s.geom)) filter (where s.spawning_model_co is true) / 1000)::numeric, 2)  stream_co_spawning_km,
    round((sum(st_length(s.geom)) filter (where s.rearing_model_co is true) / 1000)::numeric, 2) stream_co_rearing_km,
    round((sum(st_length(s.geom)) filter (where s.spawning_model_sk is true) / 1000)::numeric, 2)  stream_sk_spawning_km,
    round((sum(st_length(s.geom)) filter (where s.rearing_model_sk is true) / 1000)::numeric, 2) stream_sk_rearing_km,
    round((sum(st_length(s.geom)) filter (where s.spawning_model_st is true) / 1000)::numeric, 2)  stream_st_spawning_km,
    round((sum(st_length(s.geom)) filter (where s.rearing_model_st is true) / 1000)::numeric, 2) stream_st_rearing_km,
    coalesce(round(((sum(st_length(s.geom)) filter (where s.spawning_model_ch is true or
                                                        s.spawning_model_co is true or
                                                        s.spawning_model_sk is true or
                                                        s.spawning_model_st is true or
                                                        s.rearing_model_ch is true or
                                                        s.rearing_model_co is true or
                                                        s.rearing_model_sk is true or
                                                        s.rearing_model_st is true
                                                  )) / 1000)::numeric, 2), 0) as stream_all_spawningrearing_km
    from bcfishpass.streams s
    left outer join whse_basemapping.fwa_waterbodies wb on s.waterbody_key = wb.waterbody_key
    where s.watershed_group_code in (select distinct watershed_group_code from temp.rail_studyarea)
    and s.stream_order < 8
    group by s.watershed_group_code
),

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
    co_spawning_km ,
    co_rearing_km ,
    sk_spawning_km ,
    sk_rearing_km ,
    st_spawning_km ,
    st_rearing_km,
    all_spawningrearing_km
  from bcfishpass.crossings
  where watershed_group_code in (select distinct watershed_group_code from temp.rail_studyarea)
  and crossing_feature_type = 'RAIL'
  and barrier_status in ('BARRIER', 'POTENTIAL')
),

potentially_blocked as (
  select
    a.watershed_group_code,
    round((sum(a.ch_spawning_km))::numeric, 2) as ch_spawning_km,
    round((sum(a.ch_rearing_km))::numeric, 2) as ch_rearing_km,
    round((sum(a.co_spawning_km))::numeric, 2) as co_spawning_km,
    round((sum(a.co_rearing_km))::numeric, 2) as co_rearing_km,
    round((sum(a.sk_spawning_km))::numeric, 2) as sk_spawning_km,
    round((sum(a.sk_rearing_km))::numeric, 2) as sk_rearing_km,
    round((sum(a.st_spawning_km))::numeric, 2) as st_spawning_km,
    round((sum(a.st_rearing_km))::numeric, 2) as st_rearing_km,
    round((sum(a.all_spawningrearing_km))::numeric, 2) as all_spawningrearing_km
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
    a.co_spawning_km  > 0 or
    a.co_rearing_km  > 0 or
    a.sk_spawning_km  > 0 or
    a.sk_rearing_km  > 0 or
    a.st_spawning_km  > 0 or
    a.st_rearing_km > 0
  )
  and b.aggregated_crossings_id is null
  group by a.watershed_group_code
  order by a.watershed_group_code
)

-- combine all the columns
select distinct -- distinct because the study area polys are subdivided
  sa.watershed_group_code,
  coalesce(lr.length_rail_km, 0) as length_rail_km,
  x.n_rail_crossings,
  x.n_rail_crossings_potentially_accessible,
  x.n_rail_crossings_potentially_accessible_potential_barriers,
  x.n_road_crossings,
  x.n_road_crossings_potentially_accessible,
  x.n_road_crossings_potentially_accessible_potential_barriers,
  x.n_trail_crossings,
  x.n_trail_crossings_potentially_accessible,
  x.n_trail_crossings_potentially_accessible_potential_barriers,
  x.n_dams,
  x.n_dams_potentially_accessible,
  x.n_dams_potentially_accessible_potential_barriers,
  sl.stream_km,
  sl.stream_potentially_accessible_km,
  sl.stream_ch_spawning_km,
  sl.stream_ch_rearing_km,
  sl.stream_co_spawning_km,
  sl.stream_co_rearing_km,
  sl.stream_sk_spawning_km,
  sl.stream_sk_rearing_km,
  sl.stream_st_spawning_km,
  sl.stream_st_rearing_km,
  sl.stream_all_spawningrearing_km,
  pb.ch_spawning_km as stream_ch_spawning_aboverail_km,
  pb.ch_rearing_km as stream_ch_rearing_aboverail_km,
  pb.co_spawning_km as stream_co_spawning_aboverail_km,
  pb.co_rearing_km as stream_co_rearing_aboverail_km,
  pb.sk_spawning_km as stream_sk_spawning_aboverail_km,
  pb.sk_rearing_km as stream_sk_rearing_aboverail_km,
  pb.st_spawning_km as stream_st_spawning_aboverail_km,
  pb.st_rearing_km as stream_st_rearing_aboverail_km,
  pb.all_spawningrearing_km as stream_all_spawningrearing_aboverail_km
from temp.rail_studyarea sa
left outer join length_rail lr on sa.watershed_group_code = lr.watershed_group_code
left outer join count_xings x on sa.watershed_group_code = x.watershed_group_code
left outer join stream_length sl on sa.watershed_group_code = sl.watershed_group_code
left outer join potentially_blocked pb on sa.watershed_group_code = pb.watershed_group_code
order by sa.watershed_group_code;