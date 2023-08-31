-- potential lateral habitat for salmon/steelhead within study area, minus exclusion area

-- remove exclusion area from study area
drop table if exists temp.rail_studyarea_lateral;
create table temp.rail_studyarea_lateral (
  id serial primary key,
  geom geometry(multipolygon, 3005)
);

insert into temp.rail_studyarea_lateral
  (geom)
SELECT
  CASE
   WHEN st_intersects(a.geom, b.geom)
   then
    ST_Multi(
      ST_Difference(a.geom, b.geom)
      )
    else st_multi(a.geom)
    END As geom
from temp.rail_studyarea a
left outer join temp.lateral_exclusion b
on st_intersects(a.geom, b.geom);

create index on temp.rail_studyarea_lateral using gist (geom);

-- all lateral in studyarea
drop table if exists temp.habitat_lateral_studyarea;
create table temp.habitat_lateral_studyarea (
  id serial primary key,
  value integer,
  geom geometry(multipolygon, 3005)
);

insert into temp.habitat_lateral_studyarea (value, geom)
SELECT
  a.value,
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom)
   THEN st_multi(a.geom)
   ELSE
    ST_Multi(
      ST_Intersection(a.geom, b.geom)
      ) END As geom
from bcfishpass.habitat_lateral_clean a
inner join temp.rail_studyarea_lateral b
on st_intersects(a.geom, b.geom);

create index on temp.habitat_lateral_studyarea using gist (geom);


-- disconnected lateral in studyarea
drop table if exists temp.habitat_lateral_disconnected_rail_studyarea;

create table temp.habitat_lateral_disconnected_rail_studyarea
  (id serial primary key,
    geom geometry(multipolygon, 3005)
  );
insert into temp.habitat_lateral_disconnected_rail_studyarea (geom)
SELECT
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom)
   THEN st_multi(a.geom)
   ELSE
    ST_Multi(
      ST_Intersection(a.geom, b.geom)
      ) END As geom
from bcfishpass.habitat_lateral_disconnected_rail a
inner join temp.rail_studyarea_lateral b
on st_intersects(a.geom, b.geom);

create index on temp.habitat_lateral_disconnected_rail_studyarea using gist (geom);
