-- potential lateral habitat for salmon/steelhead within study area, minus exclusion area

-- remove exclusion area from study area
drop table if exists temp.rail_studyarea_lateral;
create table temp.rail_studyarea_lateral as
SELECT
  row_number() over() as id,
  CASE
   WHEN st_intersects(a.geom, b.geom)
   then
    ST_Multi(
      ST_Difference(a.geom, b.geom)
      )
    else a.geom
    END As geom
from temp.rail_studyarea a
left outer join temp.lateral_exclusion b
on st_intersects(a.geom, b.geom);

create index on temp.rail_studyarea_lateral using gist (geom);

-- all lateral in studyarea
drop table if exists temp.habitat_lateral_studyarea;
create table temp.habitat_lateral_studyarea as
SELECT
  row_number() over() as id,
  a.value,
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom)
   THEN a.geom
   ELSE
    ST_Multi(
      ST_Intersection(a.geom, b.geom)
      ) END As geom
from bcfishpass.habitat_lateral a
inner join temp.rail_studyarea_lateral b
on st_intersects(a.geom, b.geom);

create index on temp.habitat_lateral_studyarea using gist (geom);


-- disconnected lateral in studyarea
drop table if exists temp.habitat_lateral_disconnected_rail_studyarea;

create table temp.habitat_lateral_disconnected_rail_studyarea as
SELECT
  row_number() over() as id,
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom)
   THEN a.geom
   ELSE
    ST_Multi(
      ST_Intersection(a.geom, b.geom)
      ) END As geom
from bcfishpass.habitat_lateral_disconnected_rail a
inner join temp.rail_studyarea_lateral b
on st_intersects(a.geom, b.geom);
create index on temp.habitat_lateral_disconnected_rail_studyarea using gist (geom);
