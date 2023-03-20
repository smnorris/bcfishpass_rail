with overlay1 as
(select 
  b.watershed_group_code,
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom) THEN st_area(a.geom) / 10000
   ELSE st_area(ST_Intersection(a.geom, b.geom)) / 10000
  END As area_ha
from temp.habitat_lateral_studyarea a
inner join temp.rail_studyarea b
on st_intersects(a.geom, b.geom)
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
from temp.habitat_lateral_disconnected_rail_studyarea a
inner join temp.rail_studyarea b
on st_intersects(a.geom, b.geom)
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
  case 
     when s1.watershed_group_code = 'OKAN' then 'COLUMBIA (OKANAGAN)'
     when s1.watershed_group_code in ('BONP','BBAR','LNIC','DEAD','CHWK','COTR','DRIR','FRAN','FRCN','HARR','LCHL','LFRA','LILL','LNTH','LSAL','LTRE','MIDR','MORK','NARC','NECR','QUES','SAJR','SALR','SETN','SHUL','STHM','STUL','TABR','TAKL','THOM','TWAC','UFRA','UNTH','USHU','UTRE','WILL') then 'FRASER'
     when s1.watershed_group_code in ('BULK','KISP','KITR','KLUM','LKEL','LSKE','MORR','SUST') then 'SKEENA'
     when s1.watershed_group_code in ('ALBN','COMX','COWN','PARK','VICT','WORC','SQAM') then 'COASTAL'
 end as watershed_general,
  s1.area_ha as area_ha_total,
  s2.area_ha as area_ha_isolated
from sum_1 s1
left outer join sum_2 s2 on s1.watershed_group_code = s2.watershed_group_code
order by s1.watershed_group_code;
