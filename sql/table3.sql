select 
  'avg' as metric,
  round((avg(non_rail_barriers_dnstr))::numeric, 2) as non_rail_barriers_dnstr,
  round((avg(non_rail_barriers_upstr))::numeric, 2) as non_rail_barriers_upstr,
  round((avg(all_spawningrearing_km))::numeric, 2) as all_spawningrearing_km,
  round((avg(spawningrearing_upstr_tonextbarrier))::numeric, 2) as spawningrearing_upstr_tonextbarrier
from temp.table3_crossings
union all
select
  'max' as metric,
  max(non_rail_barriers_dnstr) as non_rail_barriers_dnstr,
  max(non_rail_barriers_upstr) as non_rail_barriers_upstr,
  max(all_spawningrearing_km) as all_spawningrearing_km,
  max(spawningrearing_upstr_tonextbarrier) as spawningrearing_upstr_tonextbarrier
from temp.table3_crossings
union all
select
  'min' as metric,
  min(non_rail_barriers_dnstr) as non_rail_barriers_dnstr,
  min(non_rail_barriers_upstr) as non_rail_barriers_upstr,
  min(all_spawningrearing_km) as all_spawningrearing_km,
  min(spawningrearing_upstr_tonextbarrier) as spawningrearing_upstr_tonextbarrier
from temp.table3_crossings
union all
select
  'median' as metric,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY non_rail_barriers_dnstr) as non_rail_barriers_dnstr,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY non_rail_barriers_upstr) as non_rail_barriers_upstr,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY all_spawningrearing_km) as all_spawningrearing_km,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY spawningrearing_upstr_tonextbarrier) as spawningrearing_upstr_tonextbarrier
from temp.table3_crossings
union all
select
  'total' as metric,
  sum(non_rail_barriers_dnstr) as non_rail_barriers_dnstr,
  sum(non_rail_barriers_upstr) as non_rail_barriers_upstr,
  sum(all_spawningrearing_km) as all_spawningrearing_km,
  sum(spawningrearing_upstr_tonextbarrier) as spawningrearing_upstr_tonextbarrier
from temp.table3_crossings