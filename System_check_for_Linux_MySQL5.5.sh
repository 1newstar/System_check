#!/bin/bash

#[ $(id -u) gt 0] && echo "Please log in as the root user!" && exit

### 服务器信息 ###
mysql_info(){
	mysql_cmd='-uroot -hlocalhost -p123456'
}

### 连通性测试 ###
connect(){
	mysql $mysql_cmd -e "show global variables like'123';" 2>/dev/null || exit
}
### 服务器型号 ###
server_version(){
	echo "三  系统基本信息巡检"
	echo -e "3.1 服务器型号"
	echo "Server_version:"
	echo "------------------------"
	cat /var/log/dmesg|grep DMI
}

### CPU型号 ###
cpu_version(){
	echo -e "3.2 CPU型号"
	echo "CPU_version:"
	echo "------------------------"
	cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq
}

### CPU核数 ###
cpu_core(){
	echo -e "3.3 CPU核数"
	echo "CPU_core:"
	echo "------------------------"
	cat /proc/cpuinfo| grep "processor"| wc -l
}

### 硬盘空间 ###
disk(){
	echo -e "3.4 硬盘空间"
	echo "Disk:"
	echo "------------------------"
	df -H |awk "{OFS=\"\t\"}{ print \$1,\$2,\$3,\$4,\$5,\$6}"
}

### 系统版本 ###
os_version(){
	echo -e "3.5 系统版本"
	echo "OS_version:"
	echo "------------------------"
	cat /etc/redhat-release &>/dev/null
	if (($?==0))
	then
		cat /etc/redhat-release 
	else
		cat /etc/issue 
	fi
}

### MySQL版本 ###
mysql_version(){
	echo "四  数据库基本信息巡检"
	echo -e "4.1 MySQL版本"
	v_1="select @@version;"
	mysql $mysql_cmd -e "${v_1}"  2>/dev/null
}
### MySQL端口号 ###
mysql_port(){
	echo -e "4.2 MySQL端口号"
        mp_1="show global variables like 'port';"
        mysql $mysql_cmd -e"${mp_1}" 2>/dev/null
}

### MySQL位置 ###
mysql_basedir(){
	echo -e "4.3 MySQL basedir"
	myb_1="show global variables like 'basedir';"
	mysql $mysql_cmd -e"${myb_1}" 2>/dev/null
}

mysql_datadir(){
	echo -e "4.4 MySQL datadir"
	myd_1="show global variables like 'datadir';"
	mysql $mysql_cmd -e"${myd_1}" 2>/dev/null
}

### MySQL进程数 ###
mysql_processnum(){
	echo -e "4.5 MySQL进程数"
	MYSQL_PROCESSNUM=`ps -ef|grep "mysql"|grep -v "grep"|wc -l`
	echo "Process number:"
	echo "------------------------"
	echo "${MYSQL_PROCESSNUM}"
	echo
	echo "分析：MySQL进程数无异常"
}

### MySQL表已用空间 ###
mysql_table_total(){
	echo -e "4.6 MySQL表已用空间"
        mtt_1="select concat(round(sum(DATA_LENGTH/1024/1024),2),'MB') as data_total from information_schema.TABLES;"
        mysql $mysql_cmd -e "${mtt_1}" 2>/dev/null
	echo
	echo "分析：MySQL表已用空间正常，磁盘压力很小"
}

### MySQL每个库已用 ###
mysql_database_total(){
	echo -e "4.7 MySQL各个库的空间使用情况"
	mdt="SELECT   table_schema,SUM(data_length+index_length)/1024/1024 AS total_mb,SUM(data_length)/1024/1024 AS data_mb,SUM(index_length)/1024/1024 AS index_mb,COUNT(*) AS TABLES FROM     information_schema.tables GROUP BY table_schema ORDER BY 2 DESC;"
	mysql $mysql_cmd -e "${mdt}" 2>/dev/null
	echo
	echo "分析：MySQL表空间正常，磁盘压力很小"
}

### MySQL binlog ###
mysql_log_bin(){
	echo -e "4.8 MySQL binlog"
	mysql $mysql_cmd -e "show global variables like 'log_bin_%';" 2>/dev/null
	echo
	echo "分析：Binlog设置正常"
}

### MySQL慢日志 ###
mysql_slow_log(){
	echo -e "4.9 MySQL慢日志"
	mysql $mysql_cmd -e "show global variables like 'slow_query%';show global variables like 'log_queries%';" 2>/dev/null
	echo
	echo "分析：慢日志设置正常"
}

### 日志报警级别 ###
log_warning(){
	echo "4.10 日志报警相关"
        logw_1="show global variables like '%log_warnings%';"
        mysql $mysql_cmd -e"${logw_1}" 2>/dev/null
        echo
	echo "分析：日志报警级别建议设置为2"
}

### binlog日志保留天数 ###
binlog_expire_days(){
	echo "4.11 binlog日志保留天数"
	bed="show global variables like '%expire_logs_days%';"
	mysql $mysql_cmd -e"${bed}" 2>/dev/null
	echo
	echo "分析：日志报警级别建议设置为2"
	echo
}

### QPS ###
qps(){
	qps_1="show global status like 'questions';"
	qps_2="show global status like 'uptime';"
	question=`mysql $mysql_cmd -e"${qps_1}" 2>/dev/null |grep -v Variable_name |cut -f 2 `
	uptime=`mysql $mysql_cmd -e"${qps_2}" 2>/dev/null |grep -v Variable_name |cut -f 2 `
	qps_3=`awk 'BEGIN {print '${question}' / '${uptime}'}'`
	echo "五  MySQL重要监控项巡检"
	echo "5.1 QPS"
	echo "QPS"
	echo "------------------------"
	echo "${qps_3:0:5}"
	echo
	echo "分析：QPS过低可以通过索引优化、SQL优化、分库分表来提升"
}

### TPS ###
tps(){
	tps_1="show global status like 'com_commit';"
	tps_2="show global status like 'com_rollback';"
	tps_3="show global status like 'uptime';"
	com_commit=`mysql $mysql_cmd -e"${tps_1}" 2>/dev/null|grep -v Variable_name |cut -f 2 `
	com_rollback=`mysql $mysql_cmd -e"${tps_2}" 2>/dev/null|grep -v Variable_name |cut -f 2 `
	uptime=`mysql $mysql_cmd -e"${tps_3}" 2>/dev/null|grep -v Variable_name |cut -f 2 `
	tps_sum=`awk 'BEGIN{print '${com_commit}'+'${com_rollback}'}'`
	tps_avg=`awk 'BEGIN{print '${tps_sum}'/'${uptime}'}'`
	echo "5.2 TPS"
	echo "TPS"
	echo "------------------------"
	echo "${tps_avg}"
	echo
	echo "分析：TPS过低可以通过索引优化、SQL优化、分库分表来提升"
}

### 内存命中率 ###

### InnoDB Buffer命中率 ###
# Innodb_buffer_read_hits = (1 - innodb_buffer_pool_reads / innodb_buffer_pool_read_requests) * 100%
innodb_buffer_read(){
	innob_1="show global status like 'Innodb_buffer_pool_reads'; "
	innob_2="show global status like 'Innodb_buffer_pool_read_requests'; "
	uptime=`mysql $mysql_cmd -e"show global status like 'uptime';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	ibp_reads=`mysql $mysql_cmd -e"${innob_1}" 2>/dev/null |grep -v Variable_name |cut -f 2`
	ibp_reads_re=`mysql $mysql_cmd -e"${innob_2}" 2>/dev/null |grep -v Variable_name |cut -f 2`
	echo "5.3 内存命中率"
	echo "Innodb_buffer_hits"
	echo "------------------------"
	if [ "${ibp_reads}" -eq 0  ]
	then
		echo "Innodb_buffer_read_hits:null"
	elif [ "${uptime}" -lt 10800 ]
	then
		echo "Key_buffer_read_hits:null"
	else
		#innob_3=`awk 'BEGIN{print '${ibp_reads}' / '${ibp_reads_re}'}'`
		#innob_4=`awk 'BEGIN{print '1-${innob_3}'}'`
		#innodb_buffer_read_hits=`awk 'BEGIN{print '${innob_4}' * 100}'`
		innodb_buffer_read_hits=`awk 'BEGIN{print (1- ('${ibp_reads}' / '${ibp_reads_re}')) * 100}'`
		echo "Innodb_buffer_read_hits:${innodb_buffer_read_hits:0:5}%"
	fi
	echo
	echo "分析：Innodb buffer命中率较高，性能较好"
}

### Key Buffer命中率 ###
# key_buffer_read_hits = (1-key_reads / key_read_requests) * 100%
key_buffer_read(){
	kbrd_1="show global status like 'Key_reads'; "
	kbrd_2="show global status like 'Key_read_requests'; "
	uptime=`mysql $mysql_cmd -e"show global status like 'uptime';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	key_reads=`mysql $mysql_cmd -e"${kbrd_1}" 2>/dev/null|grep -v Variable_name|cut -f 2`
	key_reads_re=`mysql $mysql_cmd -e"${kbrd_2}" 2>/dev/null|grep -v Variable_name|cut -f 2`
	echo "Key_buffer_hits"
	echo "------------------------"
	if [ "${key_reads}" -lt 10000 ]
	then
		echo "Key_buffer_read_hits:null"
	elif [ "${uptime}" -lt 10800 ]
	then
		echo "Key_buffer_read_hits:null"
	else
		kbrd_3=`awk 'BEGIN{print '${key_reads}' / '${key_reads_re}'}'`
		kbrd_4=`awk 'BEGIN{print '1-${kbrd_3}'}'`
		key_buffer_read_hits=`awk 'BEGIN{print '${kbrd_4}' * 100}'`
		echo "Key_buffer_read_hits:${key_buffer_read_hits:0:5}%"
	fi
	echo
	echo "分析：key buffer命中率较高，性能较好"
}

### table_cache_hits ###
table_cache_hits(){
	uptime=`mysql $mysql_cmd -e"show global status like 'uptime';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	open_t=`mysql $mysql_cmd -e"show global status like 'Open_tables%';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	opened_t=`mysql $mysql_cmd -e"show global status like 'Opened_tables%';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	echo "Table_cache_hits"
	echo "------------------------"
	if [ "${uptime}" -lt 10800 ]
	then
		echo "Table_cache_hits:null"
	elif [ ${opened_t} -eq 0 ]
	then
		echo "Table_cache_hits:null"
	else
		tch1=`awk 'BEGIN{print '${open_t}' / '${opened_t}'}'`
		tch2=`awk 'BEGIN{print '${tch1}' * 100}'`
		echo "Table_cache_hits:${tch2:0:5}%"
	fi
	echo
	echo "分析：Table cache命中率较高，性能较好"
	echo
}

### Query Cache命中率 ###
# Query_cache_hits =((Qcache_hits/(Qcache_hits+Qcache_inserts+Qcache_not_cached))*100)
query_cache(){
	qc_1="show global status like 'Qcache_hits';"
	qc_2="show global status like 'Qcache_inserts';"
	qc_3="show global status like 'Qcache_not_cached';"
	qc_hits=`mysql $mysql_cmd -e"${qc_1}" 2>/dev/null |grep -v Variable_name |cut -f 2`
	qc_inserts=`mysql $mysql_cmd -e"${qc_2}" 2>/dev/null |grep -v Variable_name |cut -f 2`
	qc_n_cached=`mysql $mysql_cmd -e"${qc_3}" 2>/dev/null |grep -v Variable_name |cut -f 2`
	echo "Query_cache_hits"
	echo "------------------------"
	if [ "${qc_hits}" -eq 0  ]
	then
		echo "Query_cache_hits:null"
	else
		qc_4=`awk 'BEGIN{print '${qc_hits}' + '${qc_inserts}' + '${qc_n_cached}' }'` 
		qc_5=`awk 'BEGIN{print  '${qc_hits}'/'${qc_4}'}'` 
		query_cache_hits=`awk 'BEGIN{print '${qc_5}' * 100}'`
		echo "Query_cache_hits:${query_cache_hits:0:5}%"
	fi
	echo
	echo "分析：Query cache命中率较高，性能较好"
}

### 磁盘相关 ###
disk_mem(){
	echo "5.4 磁盘相关"
	mysql $mysql_cmd -e"show global status like 'created_tmp%';" 2>/dev/null
	uptime=`mysql $mysql_cmd -e"show global status like 'uptime';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	ctdt=`mysql $mysql_cmd -e"show global status like 'Created_tmp_disk_tables';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	ctt=`mysql $mysql_cmd -e"show global status like 'Created_tmp_tables';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	echo
	echo "Memory_tmp_tables_pct"
	echo "------------------------"
	if [ "${uptime}" -lt 10800 ]
	then
		echo "Memory_tmp_tables_pct:null"
	elif [ "${ctt}" -eq 0  ]
	then
		echo "Memory_tmp_tables_pct:null"
	else
		mttp=`awk 'BEGIN{print (100 - (( '${ctdt}' / '${ctt}' ) * 100))}'`
		echo "Memory_tmp_tables_pct:${mttp:0:5}%"
	fi
	echo
	echo "分析：所有临时表中创建内存表的比例正常，性能较好"
	mysql $mysql_cmd -e"show global status like 'binlog_cache%';" 2>/dev/null
	bcdu=`mysql $mysql_cmd -e"show global status like 'binlog_cache_disk_use';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	bcu=`mysql $mysql_cmd -e"show global status like 'binlog_cache_use';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	echo
	echo "Binlog_cache_use_pct"
	echo "------------------------"
	if [ "${bcu}" -eq 0 ]
	then
		echo "Binlog_cache_use_pct:null"
	else
		bcup=`awk 'BEGIN{print (100 - ('${bcdu}' / ('${bcu}' + 1) * 100))}'`
		echo "Binlog_cache_use_pct:${bcup:0:5}%"
	fi
	echo
	echo "分析：Binlog日志缓存使用率正常，性能较好"
}

### MyISAM表锁相关 ###
myisam(){
	echo "5.5 MyISAM表锁相关"
	mysql $mysql_cmd -e "show global status like 'table_locks_%';" 2>/dev/null
	tli=`mysql $mysql_cmd -e"show global status like 'table_locks_immediate';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	tlw=`mysql $mysql_cmd -e"show global status like 'table_locks_waited';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	echo
	echo "Table_lock_condition"
	echo "------------------------"
	if [ "${tli}" -eq 0 ]
	then
		echo "table_lock_condition:null" 
	else
		tlc=`awk 'BEGIN{print ('${tlw}' / ('${tli}' + '${tlw}' )) * 100}'`
		echo "table_lock_condition:${tlc:0:5}%"
	fi
	echo
	echo "分析：MyISAM表锁状态无异常"
}

### 行锁相关 ###
row_lock(){
	echo "5.6 行锁相关"
	mysql $mysql_cmd -e "show global status like 'innodb_row_lock%';" 2>/dev/null
	echo
	echo "分析：行锁状态无异常"
}

### Innodb buffer pool相关 ###
innodb_bp(){
	echo "5.7 Innodb buffer pool相关"
	mysql $mysql_cmd -e"show global status like 'innodb_buffer_pool_w%';" 2>/dev/null
	ibpwf=`mysql $mysql_cmd -e"show global status like 'innodb_buffer_pool_wait_free';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	ibpwr=`mysql $mysql_cmd -e"show global status like 'innodb_buffer_pool_write_requests';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	echo
	echo "Innodb_buffer_pool_write_capacity"
	echo "------------------------"
	if [ "${ibpwr}" -eq 0 ]
	then
		echo "Innodb_buffer_pool_write_capacity:null"
	else
		ibpwc=`awk 'BEGIN{print (100 - ( '$ibpwf' / '$ibpwr' )* 100)}'`
		echo "Innodb_buffer_pool_write_capacity:${ibpwc:0:5}%"
	fi
	echo
	echo "分析：InnoDB缓冲池写入能力较好"
}

### redo log相关 ###
redo_log(){
	echo "5.8 redo log相关"
	mysql $mysql_cmd -e "show global status like 'innodb_log%';" 2>/dev/null
	echo
	echo "redo_log_write_stress"
	echo "------------------------"
	ilw1=`mysql $mysql_cmd -e "show global status like 'innodb_log_waits%';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	ilw2=`mysql $mysql_cmd -e "show global status like 'innodb_log_writes%';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	rlws=`awk 'BEGIN{print (100 * ( '$ilw1' / ( '$ilw2' + 1 )))}'`
	echo "redo_log_write_stress:${rlws:0:5}"
	echo
	echo "分析：redolog写压力正常"
}

### 线程、连接相关 ###
thread_connect(){
	echo "5.9 线程、连接相关"
	mysql $mysql_cmd -e "show global status like 'thread%';" 2>/dev/null
	mysql $mysql_cmd -e "show global status like '%connections';" 2>/dev/null
	mysql $mysql_cmd -e "show global variables like 'max_connections';" 2>/dev/null
	mysql $mysql_cmd -e "show global variables like 'thread_cache_size%';" 2>/dev/null
	echo
	echo "threads_cache_hits"
	echo "------------------------"
	tc=`mysql $mysql_cmd -e "show global status like 'Threads_created%';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	conn=`mysql $mysql_cmd -e "show global status like 'connections%';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	max_conn=`mysql $mysql_cmd -e "show global variables like '%max_connections%';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	tch=`awk 'BEGIN{print (100 - (( '${tc}' / '${conn}' ) * 100))}'`
	echo "thread_cache_hits:${tch:0:5}%"
	echo
	echo "分析：线程缓存命中率较高，性能较好"
	echo
	echo "threads_created_pct"
	echo "------------------------"
	tcp=`awk 'BEGIN{print (( '${tc}' / '${max_conn}' ) * 100)}'`
	echo "threads_created_pct:${tcp:0:5}%"
	echo
	echo "分析：创建线程数量正常"
}

### 查询相关 ###
select1(){
	echo "5.10 查询相关"
	mysql $mysql_cmd -e "show global status like 'select%';" 2>/dev/null
	mysql $mysql_cmd -e "show global status like '%Handler_read%';" 2>/dev/null
	echo
	echo "index_not_used_pct"
	echo "------------------------"
	hrrn=`mysql $mysql_cmd -e "show global status like 'Handler_read_rnd_next';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrr=`mysql $mysql_cmd -e "show global status like 'Handler_read_rnd';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrf=`mysql $mysql_cmd -e "show global status like 'Handler_read_first';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrn=`mysql $mysql_cmd -e "show global status like 'Handler_read_next';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrk=`mysql $mysql_cmd -e "show global status like 'Handler_read_key';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrp=`mysql $mysql_cmd -e "show global status like 'Handler_read_prev';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	inup=`awk 'BEGIN{print (100 - (( '${hrrn}' + '${hrr}' ) / ( '${hrrn}' + '${hrr}' + '${hrf}' + '${hrn}' + '${hrk}' + '${hrp}' )) * 100)}'`
	hrr1=`awk 'BEGIN{print ( '${hrrn}' + '${hrr}' + '${hrf}' + '${hrn}' + '${hrk}' + '${hrp}' )}'`
	if [ "${hrr1}" -eq 0 ]
	then
		echo "index_not_used_pct:null"
	else
		echo "index_not_used_pct:${inup:0:5}%"
	fi
	echo
	echo "分析：索引利用率正常"
}

### 排序相关 ###
sort1(){
	echo "5.11 排序相关"
	mysql $mysql_cmd -e "show global status like 'sort%';" 2>/dev/null
	mysql $mysql_cmd -e "show global variables like 'sort%';" 2>/dev/null
	echo
	echo "分析：排序次数正常，sort buffer设置合理"
}

### 行记录 ###
innodb_rows(){
	echo "六  InnoDB健康状况巡检"
	echo "6.1 行记录"
	mysql $mysql_cmd -e "show global status like 'innodb_rows_%';" 2>/dev/null
	echo
	echo "分析：SQL在InnoDB中的执行能力较好"
}

### InnoDB文件IO相关 ###
innodb_io(){
	echo "6.2 InnoDB文件IO"
	mysql $mysql_cmd -e "show global status like 'innodb_data_read%';" 2>/dev/null
	mysql $mysql_cmd -e "show global status like 'innodb_data_writ%';" 2>/dev/null
	mysql $mysql_cmd -e "show global status like 'innodb_pages_%';" 2>/dev/null
	echo
	echo "分析：InnoDB吞吐量正常"
}

### InnoDB磁盘刷新相关 ###
innodb_flush(){
	echo "6.3 InnoDB磁盘刷新相关"
	mysql $mysql_cmd -e "show global status like 'innodb_data_fsyncs%';" 2>/dev/null
	mysql $mysql_cmd -e "show global status like 'innodb_data_pending%';" 2>/dev/null
	echo
	echo "分析：InnoDB磁盘刷新情况正常"
}

### innodb buffer pool使用状态 ###
innodb_use(){
	echo "6.4 innodb buffer pool使用状态"
	mysql $mysql_cmd -e "show global status like 'innodb_buffer_pool_pages%';" 2>/dev/null
	echo
	echo "分析：InnoDB缓冲池使用状态正常"
}

### redo log磁盘刷新相关 ###
redo_flush(){
	echo "6.5 redo log磁盘刷新相关"
	mysql $mysql_cmd -e "show global status like 'innodb_os_log_%';" 2>/dev/null
	echo
	echo "分析：redo log磁盘刷新状况正常"
}

main(){
	> test.txt
	mysql_info
	connect
	server_version
	cpu_version
	cpu_core
	disk
	os_version
	mysql_version
	mysql_port
	mysql_basedir
	mysql_datadir
	mysql_processnum
	mysql_table_total
	mysql_database_total
	mysql_log_bin
	mysql_slow_log
	log_warning
	binlog_expire_days
	qps
	tps
	innodb_buffer_read
	key_buffer_read
	table_cache_hits
	query_cache
	disk_mem
	myisam
	row_lock
	innodb_bp
	redo_log
	thread_connect
	select1
	sort1
	innodb_rows
	innodb_io
	innodb_flush
	innodb_use
	redo_flush
}

echo "Start checking!"
echo "......"
main 2>err.txt
echo "Checking completed!"
echo "=============================="
echo "检查结果记录在test.txt文件中"
echo "错误日志记录在err.txt文件中"
echo "=============================="
echo "以上文档均保存在当前目录下"


