-- rail summary, within study area:

-- linear:
-- length rail
-- n rail crossings, total
-- n rail CBS crossings
-- n rail CBS crossings on potentially accessible stream
-- n rail CBS crossings on modelled habitat


-- Total rail network length in our target area (km)
select
  'Total length of railway (km)' as desc,
  round((sum(st_length(geom)) / 1000)::numeric) as val
from (SELECT
 CASE
   WHEN ST_CoveredBy(p.geom, n.geom)  THEN p.geom
   ELSE
    ST_Multi(
      ST_Intersection(p.geom,n.geom)
      ) END AS geom
 FROM whse_basemapping.gba_railway_tracks_sp AS p
   INNER JOIN temp.rail_studyarea AS n
    ON ST_Intersects(p.geom, n.geom)
) as r

union all

-- Number of rail stream crossings within study area
select 
  'Count rail-stream crossings, total' as desc,
  count(c.*) as val
from bcfishpass.crossings c
inner join temp.rail_studyarea s on st_within(c.geom, s.geom)
 where crossing_feature_type = 'RAIL'

union all

-- Number of rail stream crossings within target area modelled as barriers/potential barriers

select 
  'Count rail-stream crossings, potential barrier' as desc,
  count(c.*) as val 
from bcfishpass.crossings c
inner join temp.rail_studyarea s on st_within(c.geom, s.geom)
 where crossing_feature_type = 'RAIL'
and barrier_status in ('BARRIER', 'POTENTIAL')

union all


-- Number of rail stream crossings within target area modelled as barriers/potential barriers
-- and on potentially accessible stream
select 
  'Count rail-stream crossings, potential barrier, potentially accessible' as desc,
  count(c.*) as val 
from bcfishpass.crossings c
inner join temp.rail_studyarea s on st_within(c.geom, s.geom)
 where crossing_feature_type = 'RAIL'
and barrier_status in ('BARRIER', 'POTENTIAL')
and (barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] or barriers_st_dnstr = array[]::text[])

union all

-- Number of rail stream crossings within target area modelled as barriers/potential barriers
-- and on modelled habitat
select 
  'Count rail-stream crossings, potential barrier, potential spawn/rear habitat' as desc,
  count(c.*) as val
  from bcfishpass.crossings c
inner join temp.rail_studyarea s on st_within(c.geom, s.geom)
 where crossing_feature_type = 'RAIL'
and barrier_status in ('BARRIER', 'POTENTIAL')
and 
(ch_spawning_km > 0 or
ch_rearing_km > 0 or
cm_spawning_km > 0 or
co_spawning_km > 0 or
co_rearing_km > 0 or
pk_spawning_km > 0 or
sk_spawning_km > 0 or
sk_rearing_km > 0 or
st_spawning_km > 0 or
st_rearing_km > 0 ) 

union all

-- lateral habitat reporting
-- total, isolated, count isolated, avg size isolated
  select 
  'Total area modelled lateral habitat (ha)' as desc,
  round(sum(area_ha)::numeric) as val
  from (
    select 
      CASE
       WHEN ST_CoveredBy(a.geom, b.geom) THEN st_area(a.geom) / 10000
       ELSE st_area(ST_Intersection(a.geom, b.geom)) / 10000
      END As area_ha
    from temp.habitat_lateral_studyarea a
    inner join temp.rail_studyarea b
    on st_intersects(a.geom, b.geom)
) as l

union all

select 
  'Total area of modelled potential lateral habitat blocked by rail (ha)' as desc,
   round(sum(area_ha)::numeric) as val
from (
select 
  b.watershed_group_code,
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom) THEN st_area(a.geom) / 10000
   ELSE st_area(ST_Intersection(a.geom, b.geom)) / 10000
  END As area_ha
from temp.habitat_lateral_disconnected_rail_studyarea a
inner join temp.rail_studyarea b
on st_intersects(a.geom, b.geom)
) as l

union all

select 
  'Count of polygons with potential lateral habitat blocked by rail' as desc,
  count(*) as val
from (
select 
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom) THEN a.geom
   ELSE ST_Intersection(a.geom, b.geom) 
  END As geom
from temp.habitat_lateral_disconnected_rail_studyarea a
inner join temp.rail_studyarea_lateral_merged b
on st_intersects(a.geom, b.geom)
) as l

union all

select 
  'Average polygon size of potential lateral habitat blocked by rail' as desc,
  round((avg(st_area(geom) / 10000)::numeric)) as val
from (
select 
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom) THEN a.geom
   ELSE ST_Intersection(a.geom, b.geom) 
  END As geom
from temp.habitat_lateral_disconnected_rail_studyarea a
inner join temp.rail_studyarea_lateral_merged b
on st_intersects(a.geom, b.geom)
) as l;
