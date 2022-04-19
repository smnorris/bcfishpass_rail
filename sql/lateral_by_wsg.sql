with overlay1 as
(select 
  b.watershed_group_code,
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom) THEN st_area(a.geom) / 10000
   ELSE st_area(ST_Intersection(a.geom, b.geom)) / 10000
  END As area_ha
from temp.lateral_potential_fraser a
inner join whse_basemapping.fwa_watershed_groups_poly b
on st_intersects(a.geom, b.geom)
where b.wscode_ltree <@ '100'::ltree
),

sum_1 as
(select
   watershed_group_code,
   round((sum(area_ha))::numeric, 2) as area_ha
  from overlay1
  group by watershed_group_code
),

overlay2 as
(select 
  b.watershed_group_code,
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom) THEN st_area(a.geom) / 10000
   ELSE st_area(ST_Intersection(a.geom, b.geom)) / 10000
  END As area_ha
from temp.lateral_disconnected_fraser a
inner join whse_basemapping.fwa_watershed_groups_poly b
on st_intersects(a.geom, b.geom)
where b.wscode_ltree <@ '100'::ltree
),

sum_2 as
(select
   watershed_group_code,
   round((sum(area_ha))::numeric, 2) as area_ha
  from overlay2
  group by watershed_group_code
)

select 
  s1.watershed_group_code,
  s1.area_ha as area_ha_total,
  s2.area_ha as area_ha_isolated
from sum_1 s1
left outer join sum_2 s2 on s1.watershed_group_code = s2.watershed_group_code
order by s1.watershed_group_code;
