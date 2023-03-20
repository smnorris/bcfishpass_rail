-- aggregate output1.sql into table2 output
-- Amount and proportion of potential linear spawning and rearing habitat that may blocked by rail lines within study area

with studyarea as (
  select 
    distinct watershed_group_code
  from temp.rail_studyarea
  order by watershed_group_code
),

totals as (
  select
    s.watershed_group_code,
    round((sum(st_length(geom)) filter (where model_spawning_ch is true) / 1000 )::numeric, 2)  ch_spawning_km_total,
    round((sum(st_length(geom)) filter (where model_rearing_ch is true) / 1000 )::numeric, 2) ch_rearing_km_total,
    round((sum(st_length(geom)) filter (where model_spawning_cm is true) / 1000)::numeric, 2)  cm_spawning_km_total,
    round((sum(st_length(geom)) filter (where model_spawning_co is true) / 1000)::numeric, 2)  co_spawning_km_total,
    round((sum(st_length(geom)) filter (where model_rearing_co is true) / 1000)::numeric, 2) co_rearing_km_total,
    round((sum(st_length(geom)) filter (where model_spawning_pk is true) / 1000)::numeric, 2)  pk_spawning_km_total,
    round((sum(st_length(geom)) filter (where model_spawning_sk is true) / 1000)::numeric, 2)  sk_spawning_km_total,
    round((sum(st_length(geom)) filter (where model_rearing_sk is true) / 1000)::numeric, 2) sk_rearing_km_total,
    round((sum(st_length(geom)) filter (where model_spawning_st is true) / 1000)::numeric, 2)  st_spawning_km_total,
    round((sum(st_length(geom)) filter (where model_rearing_st is true) / 1000)::numeric, 2) st_rearing_km_total, 
    round((sum(st_length(geom)) filter (where model_spawning_ch is true or
       model_rearing_ch is true or
       model_spawning_cm is true or
       model_spawning_co is true or
       model_rearing_co is true or
       model_spawning_pk is true or
       model_spawning_sk is true or
       model_rearing_sk is true or
       model_spawning_st is true or
       model_rearing_st is true 
    ) / 1000)::numeric, 2) all_spawningrearing_km_total
  from bcfishpass.streams s
  inner join studyarea sa
  on s.watershed_group_code = sa.watershed_group_code
  group by s.watershed_group_code),

rail_barriers as
(
  select
    barriers_anthropogenic_id,
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
    st_rearing_km,
    all_spawningrearing_km
  from bcfishpass.barriers_anthropogenic
  where watershed_group_code in (select watershed_group_code from studyarea)
  and barrier_type = 'RAIL'
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
a.cm_spawning_km  > 0 or
a.co_spawning_km  > 0 or
a.co_rearing_km  > 0 or
a.pk_spawning_km  > 0 or
a.sk_spawning_km  > 0 or
a.sk_rearing_km  > 0 or
a.st_spawning_km  > 0 or
a.st_rearing_km > 0)
and b.barriers_anthropogenic_id is null
group by
  a.watershed_group_code
order by watershed_group_code),

output1 as 
(
  select
 a.watershed_group_code,
   case
     when r.watershed_group_code = 'OKAN' then 'COLUMBIA (OKANAGAN)'
     when r.watershed_group_code in ('BONP','BBAR','LNIC','DEAD','CHWK','COTR','DRIR','FRAN','FRCN','HARR','LCHL','LFRA','LILL','LNTH','LSAL','LTRE','MIDR','MORK','NARC','NECR','QUES','SAJR','SALR','SETN','SHUL','STHM','STUL','TABR','TAKL','THOM','TWAC','UFRA','UNTH','USHU','UTRE','WILL') then 'FRASER'
     when r.watershed_group_code in ('BULK','KISP','KITR','KLUM','LKEL','LSKE','MORR','SUST') then 'SKEENA'
     when r.watershed_group_code in ('ALBN','COMX','COWN','PARK','VICT','WORC','SQAM') then 'COASTAL'
 end as watershed_general,
 case 
   when r.watershed_group_code is not null then true
 end as rail_present,
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
 round(((b.st_rearing_km / a.st_rearing_km_total) * 100)::numeric, 2) as st_rearing_aboverailxing_pct,

 a.all_spawningrearing_km_total,
 b.all_spawningrearing_km as all_spawningrearing_km_aboverail,
 round(((b.all_spawningrearing_km / a.all_spawningrearing_km_total) * 100)::numeric, 2) as all_spawningrearing_aboverailxing_pct

from totals a
left outer join potentially_blocked b
on a.watershed_group_code = b.watershed_group_code
left outer join studyarea r
on a.watershed_group_code = r.watershed_group_code
order by a.watershed_group_code
)

select 
'Spawning - Chinook' as species,
  sum(ch_spawning_km_total) as habitat_total,
  sum(ch_spawning_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(ch_spawning_km_aboverail) / sum(ch_spawning_km_total)) * 100)::numeric, 2) as blocked_proportion
from output1
union all
select
  'Spawning - Chum' as species,
  sum(cm_spawning_km_total) as habitat_total,
  sum(cm_spawning_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(cm_spawning_km_aboverail) / sum(cm_spawning_km_total)) * 100)::numeric, 2) as blocked_proportion
from output1
union all
select
  'Spawning - Coho' as species,
  sum(co_spawning_km_total) as habitat_total,
  sum(co_spawning_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(co_spawning_km_aboverail) / sum(co_spawning_km_total)) * 100)::numeric, 2) as blocked_proportion
from output1
union all
select
  'Spawning - Pink' as species,
  sum(pk_spawning_km_total) as habitat_total,
  sum(pk_spawning_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(pk_spawning_km_aboverail) / sum(pk_spawning_km_total)) * 100)::numeric, 2) as blocked_proportion
from output1
union all
select
  'Spawning - Sockeye' as species,
  sum(sk_spawning_km_total) as habitat_total,
  sum(sk_spawning_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(sk_spawning_km_aboverail) / sum(sk_spawning_km_total)) * 100)::numeric, 2) as blocked_proportion  
from output1
union all
select
  'Spawning - Steelhead' as species,
  sum(st_spawning_km_total) as habitat_total,
  sum(st_spawning_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(st_spawning_km_aboverail) / sum(st_spawning_km_total)) * 100)::numeric, 2) as blocked_proportion  
from output1

union all

select 
'Rearing - Chinook' as species,
  sum(ch_rearing_km_total) as habitat_total,
  sum(ch_rearing_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(ch_rearing_km_aboverail) / sum(ch_rearing_km_total)) * 100)::numeric, 2) as blocked_proportion
from output1
union all
select
  'Rearing - Coho' as species,
  sum(co_rearing_km_total) as habitat_total,
  sum(co_rearing_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(co_rearing_km_aboverail) / sum(co_rearing_km_total)) * 100)::numeric, 2) as blocked_proportion
from output1
union all
select
  'Rearing - Sockeye' as species,
  sum(sk_rearing_km_total) as habitat_total,
  sum(sk_rearing_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(sk_rearing_km_aboverail) / sum(sk_rearing_km_total)) * 100)::numeric, 2) as blocked_proportion  
from output1
union all
select
  'Rearing - Steelhead' as species,
  sum(st_rearing_km_total) as habitat_total,
  sum(st_rearing_km_aboverail) as habitat_potentially_blocked_by_rail,
  round(((sum(st_rearing_km_aboverail) / sum(st_rearing_km_total)) * 100)::numeric, 2) as blocked_proportion  
from output1;

