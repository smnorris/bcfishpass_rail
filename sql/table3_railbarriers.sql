
-- Table 3 prep

-- extract all rail barriers with spawning/rearing upstream
-- n=428

drop table if exists temp.table3_railbarriers;

create table temp.table3_railbarriers as
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
    and blue_line_key = watershed_key
    and (ch_spawning_km > 0 or
        ch_rearing_km > 0 or
        cm_spawning_km > 0 or
        co_spawning_km > 0 or
        co_rearing_km > 0 or
        pk_spawning_km > 0 or
        sk_spawning_km > 0 or
        sk_rearing_km > 0 or
        st_spawning_km > 0 or
        st_rearing_km > 0)
),

-- find other rail barriers dnstr of above xings
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

-- generate list of rail barriers with no other rail barriers upstream (and downstream of habitat)
-- (n=377)
for_report as
(
select
  a.aggregated_crossings_id
from xings a
left outer join rail_barriers_dnstr b
on a.aggregated_crossings_id = b.aggregated_crossings_id
where b.rail_barriers_dnstr is null
),

-- get count of non-rail barriers downstream
non_rail_barriers_dnstr as
(
  select
    r.aggregated_crossings_id,
    count(b.aggregated_crossings_id) as non_rail_barriers_dnstr
  from for_report r
  inner join bcfishpass.crossings c on r.aggregated_crossings_id = c.aggregated_crossings_id
  left outer join bcfishpass.crossings b
  on fwa_downstream(
    c.blue_line_key,
    c.downstream_route_measure,
    c.wscode_ltree,
    c.localcode_ltree,
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
  group by r.aggregated_crossings_id
),


-- get count of non-rail barriers upstream (and downstream of habitat)
non_rail_barriers_upstr as
(
  select
    r.aggregated_crossings_id,
    count(b.aggregated_crossings_id) as non_rail_barriers_upstr
  from for_report r
  inner join bcfishpass.crossings c on r.aggregated_crossings_id = c.aggregated_crossings_id
  left outer join bcfishpass.crossings b
  on fwa_upstream(
    c.blue_line_key,
    c.downstream_route_measure,
    c.wscode_ltree,
    c.localcode_ltree,
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
  group by r.aggregated_crossings_id
)

select
  c.aggregated_crossings_id,
    case
     when c.watershed_group_code = 'OKAN' then 'COLUMBIA (OKANAGAN)'
     when c.watershed_group_code in ('BONP','BBAR','LNIC','DEAD','CHWK','COTR','DRIR','FRAN','FRCN','HARR','LCHL','LFRA','LILL','LNTH','LSAL','LTRE','MIDR','MORK','NARC','NECR','QUES','SAJR','SALR','SETN','SHUL','STHM','STUL','TABR','TAKL','THOM','TWAC','UFRA','UNTH','USHU','UTRE','WILL') then 'FRASER'
     when c.watershed_group_code in ('BULK','KISP','KITR','KLUM','LKEL','LSKE','MORR','SUST') then 'SKEENA'
     when c.watershed_group_code in ('ALBN','COMX','COWN','PARK','VICT','WORC','SQAM') then 'COASTAL'
  end as basin,
  c.watershed_group_code,
  w.watershed_group_name,
  c.gnis_stream_name,
  coalesce(d.non_rail_barriers_dnstr,0) as non_rail_barriers_dnstr,
  coalesce(u.non_rail_barriers_upstr,0) as non_rail_barriers_upstr,
  round(c.all_spawningrearing_km::numeric, 2) as all_spawningrearing_km
from bcfishpass.crossings c
inner join for_report r on c.aggregated_crossings_id = r.aggregated_crossings_id
left outer join non_rail_barriers_dnstr d on c.aggregated_crossings_id = d.aggregated_crossings_id
left outer join non_rail_barriers_upstr u on c.aggregated_crossings_id = u.aggregated_crossings_id
inner join whse_basemapping.fwa_watershed_groups_poly w
on c.watershed_group_code = w.watershed_group_code;

