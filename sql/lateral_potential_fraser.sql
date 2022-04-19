-- potential lateral in fraser

-- create fraser def
create table temp.fraser as

  select
    row_number() over() as id,
    st_subdivide(geom) as geom
  from whse_basemapping.fwa_named_watersheds_poly
where gnis_name = 'Fraser River' and wscode_ltree = '100'::ltree;

create index on temp.fraser using gist(geom);

-- remove exclusion area
drop table if exists temp.lateral_fraser_studyarea;
create table temp.lateral_fraser_studyarea as
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
from temp.fraser a
left outer join temp.lateral_exclusion b
on st_intersects(a.geom, b.geom);

drop table if exists temp.lateral_potential_fraser;

create table temp.lateral_potential_fraser as
SELECT
  row_number() over() as id,
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom)
   THEN a.geom
   ELSE
    ST_Multi(
      ST_Intersection(a.geom, b.geom)
      ) END As geom
from bcfishpass.lateral_potential a
inner join temp.lateral_fraser_studyarea b
on st_intersects(a.geom, b.geom);

create index on temp.lateral_potential_fraser using gist (geom);


-- disconnected lateral in fraser
drop table if exists temp.lateral_disconnected_fraser;

create table temp.lateral_disconnected_fraser as
SELECT
  row_number() over() as id,
  CASE
   WHEN ST_CoveredBy(a.geom, b.geom)
   THEN a.geom
   ELSE
    ST_Multi(
      ST_Intersection(a.geom, b.geom)
      ) END As geom
from bcfishpass.lateral_disconnected_rail a
inner join temp.lateral_fraser_studyarea b
on st_intersects(a.geom, b.geom);
create index on temp.lateral_disconnected_fraser using gist (geom);
