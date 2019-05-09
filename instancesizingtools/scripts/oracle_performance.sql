with view_sysstat as
(select ss.dbid, ss.snap_id, ss.instance_number,
sum(case metric_name when 'Physical Read Total IO Requests Per Sec' then maxval end) rdiopsmax,
sum(case metric_name when 'Physical Read Total IO Requests Per Sec' then average end) rdiopsavg,
sum(case metric_name when 'Physical Write Total IO Requests Per Sec' then maxval end) wtiopsmax,
sum(case metric_name when 'Physical Write Total IO Requests Per Sec' then average end) wtiopsavg,
sum(case metric_name when 'Physical Read Total Bytes Per Sec' then maxval end) rdbtpsmax,
sum(case metric_name when 'Physical Read Total Bytes Per Sec' then average end) rdbtpsavg,
sum(case metric_name when 'Physical Write Total Bytes Per Sec' then maxval end) wtbtpsmax,
sum(case metric_name when 'Physical Write Total Bytes Per Sec' then average end) wtbtpsavg,
sum(case metric_name when 'Redo Generated Per Sec' then maxval end) redobtpsmax,
sum(case metric_name when 'Redo Generated Per Sec' then average end) redobtpsavg,
sum(case metric_name when 'Host CPU Utilization (%)' then maxval end) hostcpumax,
sum(case metric_name when 'Host CPU Utilization (%)' then average end) hostcpuavg
from dba_hist_sysmetric_summary ss, v$database d
where ss.metric_name in
('Physical Read Total IO Requests Per Sec','Physical Write Total IO Requests Per Sec',
'Physical Read Total Bytes Per Sec', 'Physical Write Total Bytes Per Sec',
'Redo Generated Per Sec', 'Host CPU Utilization (%)')
and ss.dbid=d.dbid
group by ss.dbid, ss.snap_id, ss.instance_number),
view_osstat as (
select d.dbid, snap_id, instance_number,
sum(case stat_name when 'NUM_CPU_SOCKETS' then value end) cpusocket,
sum(case stat_name when 'NUM_CPU_CORES' then value end) cpucore,
sum(case stat_name when 'NUM_CPUS' then value end) cpunumber,
sum(case stat_name when 'PHYSICAL_MEMORY_BYTES' then round(value/1024/1024,0) end) rammb
from dba_hist_osstat os, v$database d
where os.stat_name in
('NUM_CPUS','NUM_CPU_CORES','NUM_CPU_SOCKETS',
'PHYSICAL_MEMORY_BYTES','FREE_MEMORY_BYTES','SWAP_FREE_BYTES')
and os.dbid=d.dbid
group by d.dbid, snap_id, instance_number)
select /*+ opt_param('_optimizer_cartesian_enabled','FALSE') */
d.name database_name, i.host_name, vs.instance_number,
to_char(vs.end_interval_time,'DD-MON-YYYY HH24:MI:SS') snaptime,
round(vss2.rdiopsmax,0) rdiopsmax_hourly,
round(vss2.rdiopsavg,0) rdiopsavg_hourly,
round(vss2.wtiopsmax,0) wtiopsmax_hourly,
round(vss2.wtiopsavg,0) wtiopsavg_hourly,
round(vss2.rdbtpsmax,0) rdbtpsmax_hourly,
round(vss2.rdbtpsavg,0) rdbtpsavg_hourly,
round(vss2.wtbtpsmax,0) wtbtpsmax_hourly,
round(vss2.wtbtpsavg,0) wtbtpsavg_hourly,
round(vss2.hostcpumax,0) hostcpupctmax_hourly,
round(vss2.hostcpuavg,0) hostcpupctavg_hourly,
round(vss2.redobtpsmax,0) redobtpsmax_hourly,
round(vss2.redobtpsavg,0) redobtpsavg_hourly,
vos2.cpusocket,
vos2.cpucore,
vos2.cpunumber,
vos2.rammb,
round(vsga.value/1024/1024,0) sgamb,
round(vpga.value/1024/1024,0) pgamb,
dbsize.tbsizeusedmb
from dba_hist_snapshot vs, v$database d,
view_sysstat vss2,
view_osstat vos2,
(select snap_id, dbid, instance_number, sum(bytes) value from dba_hist_sgastat
group by snap_id, dbid, instance_number) vsga,
(select snap_id, dbid, instance_number, value from dba_hist_pgastat
where name='total PGA allocated') vpga,
(select round(sum(bytes)/1024/1024) tbsizeusedmb from dba_segments) dbsize,
gv$instance i
where vs.dbid=d.dbid
and i.instance_number=vs.instance_number
and vs.dbid=vss2.dbid(+) and vs.snap_id=vss2.snap_id(+) and vs.instance_number=vss2.instance_number(+)
and vs.dbid=vos2.dbid(+) and vs.snap_id=vos2.snap_id(+) and vs.instance_number=vos2.instance_number(+)
and vs.dbid=vsga.dbid(+) and vs.snap_id=vsga.snap_id(+) and vs.instance_number=vsga.instance_number(+)
and vs.dbid=vpga.dbid(+) and vs.snap_id=vpga.snap_id(+) and vs.instance_number=vpga.instance_number(+)
order by vs.snap_id desc
