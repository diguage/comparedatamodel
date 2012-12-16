# **  �˽ű��Ƚ�config.txt�У����õ������û�������ģ�͵���ͬ��
#
# **  ������Ա�������Nickname��D�ϸ磻Website��http://www.diguage.com/��
# **  �������ڣ�2012-3-19
#
# **  �޸���Ա��
# **  �޸����ڣ�

#!/bin/sh
# compar.tcl \
exec tclsh "$0" ${1+"$@"}
encoding system identity

package require Oratcl

# ��õ�ǰ·��
set currentPath [file dirname [info script]]
cd $currentPath
#��õ�ǰ����·��
set absoluteCurrentPath [pwd]
cd ..
# ��ø�Ŀ¼����·��
set absoluteParentPath [pwd]
# ��õ�ǰ�ű���
set fileName [file tail [info script]]

# �����ֵ��ļ���ȡԴ�ļ�
source "$absoluteParentPath//src//read_config.tcl"

#��ѯĳ���û�ӵ�еı�
proc query_table {qry_tab_handler} {
	
	set qry_tab_sql " select trim(upper(table_name)) from user_tables order by trim(upper(table_name)) "
	
	puts $qry_tab_sql
	
	if [catch {orasql $qry_tab_handler $qry_tab_sql} errmsg] {
		  error $errmsg
	} elseif {$errmsg != 0 && $errmsg != 100 && $errmsg != 1403} {
		error $errmsg
	}
	
	set tab_list [list]
	while {[oramsg $qry_tab_handler] == 0} {
		orafetch $qry_tab_handler  -datavariable result -command {
			puts "[lindex  $result 0]"
			lappend tab_list [lindex  $result 0]
		}
	}
	return $tab_list
}

#�Ƚ�����ģ���еı��Ƿ�һ�¡�
proc compare_tab {old_tab_list new_tab_list} {
	global cfg
	
	set old_tab_file [open "$cfg(result_output_directory)//old_tab.txt" w+]
	set new_tab_file [open "$cfg(result_output_directory)//new_tab.txt" w+]
	set common_tab_file [open "$cfg(result_output_directory)//common_tab.txt" w+]
	
	seek $old_tab_file 0 start
	seek $new_tab_file 0 start
	seek $common_tab_file 0 start
	
	puts $old_tab_file "There are the common table list.\n\
						**************************************\n\n"
	puts $new_tab_file "The tables are unique to The New Model.\n\
						***************************************\n\n"
	puts $common_tab_file "The tables are unique to The Old Model.\n\
						   ***************************************\n\n"
	
	set common_tab_list [list]
	
	for {set i 0} {$i < [llength $old_tab_list]} {incr i} {
		set a [lindex $old_tab_list $i]
		set isBreak false
		for {set j 0} {$j < [llength $new_tab_list]} {incr j} {
    		set b [lindex $new_tab_list $j]
			if {$a == $b} {
				puts $common_tab_file $a
				lappend common_tab_list $a
				set isBreak true
				set new_tab_list [lreplace $new_tab_list $j $j]
				break
			}
		}
		if {!$isBreak} {
			puts $old_tab_file $a
		}
	}
	
	foreach b $new_tab_list {
		puts $new_tab_file $b
	}
	
	close $old_tab_file
	close $new_tab_file
	close $common_tab_file
	
	return $common_tab_list
}

#��ѯ��������ӵ�е��ֶΡ��ֶε����������Լ����ݳ��ȡ�ע�⣬number���͵���ʱû�в�
proc query_fields_of_table {qry_fields_handler table_name} {
	set qry_fields_sql " select trim(upper(column_name)), trim(upper(data_type)) "
	append qry_fields_sql " ,case when trim(upper(data_type)) = trim(upper('varchar2')) or "
	append qry_fields_sql " trim(upper(data_type)) = trim(upper('varchar')) or "
	append qry_fields_sql " trim(upper(data_type)) = trim(upper('char')) then "
	append qry_fields_sql " data_length when trim(upper(data_type)) = trim(upper('number')) then "
	append qry_fields_sql " data_precision else 0 end as data_precision "
	append qry_fields_sql " ,nvl(data_scale, 0) as data_scale "
	append qry_fields_sql " from user_tab_columns "
	append qry_fields_sql " where table_name = upper('$table_name') order by trim(upper(column_name)) "

#	puts $qry_fields_sql
	
	if [catch {orasql $qry_fields_handler $qry_fields_sql} errmsg] {
		  error $errmsg
	} elseif {$errmsg != 0 && $errmsg != 100 && $errmsg != 1403} {
		error $errmsg
	}
	
	set fields [list]
	
	while {[oramsg $qry_fields_handler] == 0} {
		orafetch $qry_fields_handler  -datavariable result -command {
			lappend fields "[lindex  $result 0] [lindex  $result 1] [lindex  $result 2] [lindex  $result 3]"
#			puts "[lindex  $result 0] [lindex  $result 1] [lindex  $result 2] [lindex  $result 3]"
		}
	}
	
	return $fields	
}

#�Ƚ��������и����ֶ��Ƿ���ͬ��
#ÿ���ֶαȽ��ĸ����ԣ��ֶ����ơ��������͡������Լ����ȡ�ע�⣺���û�ж��徫�ȣ�����varchar2���ͣ��򾫶�����Ϊ0.
proc compare_fields {old_fields_list new_fields_list table_name} {
	global cfg
	
	set width 20

	set fields_same_table_file [open "$cfg(result_output_directory)//$cfg(fields_same_table_file)" a]
	set fields_diff_table_file [open "$cfg(result_output_directory)//$cfg(fields_diff_table_file)" a]
	
	if {$old_fields_list == $new_fields_list} {
		puts $fields_same_table_file $table_name
		puts $fields_same_table_file "\n"
	} else {
		puts $fields_diff_table_file "\n\n*********** Table Name :  $table_name  *******"
		puts $fields_diff_table_file [format "\t  %-*s\t\t%-*s" $width "--Old--" $width "--New--"]
		
		for {set i 0} {$i < [llength $old_fields_list]} {incr i} {
			set o [lindex $old_fields_list $i]
			set isBreak false
			for {set j 0} {$j < [llength $new_fields_list]} {incr j} {
				set n [lindex $new_fields_list $j]
				if {$o == $n} {
					set isBreak true
					set old_fields_list [lreplace $old_fields_list $i $i]
					set new_fields_list [lreplace $new_fields_list $j $j]
					
					incr i -1
					incr j -1
					break
				} elseif { [lindex $o 0] == [lindex $n 0] } {
					puts $fields_diff_table_file "\n----------Diff Fields------------" 
					for {set k 0} {$k < 4} {incr k} {
						set oe [lindex $o $k]
						set ne [lindex $n $k]
						if {$k == 0} {
							puts $fields_diff_table_file [format "  *Name*  %-*s\t\t%-*s" $width $oe $width $ne] 
						}
						if {$oe != $ne && $k == 1} {
							puts $fields_diff_table_file [format "  *Type*  %-*s\t\t%-*s" $width $oe $width $ne] 
						}
						if {$oe != $ne && $k == 2} {
							puts $fields_diff_table_file [format "  *Lgth*  %-*s\t\t%-*s" $width $oe $width $ne] 
						}
						if {$oe != $ne && $k == 3} {
							puts $fields_diff_table_file [format "  *Scal*  %-*s\t\t%-*s" $width $oe $width $ne] 
						}
					}
					
					set isBreak true
					
					set old_fields_list [lreplace $old_fields_list $i $i]
					set new_fields_list [lreplace $new_fields_list $j $j]
					
					incr i -1
					incr j -1
					
					break

				} 
			}
		}
		
		#��Old���е����������
		foreach uof $old_fields_list {
			puts $fields_diff_table_file "\n----------Old Filds---------------"
			for {set ok 0} {$ok < 4} {incr ok} {
				set oe [lindex $uof $ok]
				if {$ok == 0} {
					puts $fields_diff_table_file [format "  *Name*  %-*s\t\t%-*s" $width $oe $width ""] 
				}
				if {$ok == 1} {
					puts $fields_diff_table_file [format "  *Type*  %-*s\t\t%-*s" $width $oe $width ""] 
				}
				if {$ok == 2} {
					puts $fields_diff_table_file [format "  *Lgth*  %-*s\t\t%-*s" $width $oe $width ""] 
				}
				if {$ok == 3} {
					puts $fields_diff_table_file [format "  *Scal*  %-*s\t\t%-*s" $width $oe $width ""] 
				}
			}
		}
		
		#��New���е��������
		foreach unf $new_fields_list {
			puts $fields_diff_table_file "\n----------New Filds---------------"
			for {set nk 0} {$nk < 4} {incr nk} {
				set ne [lindex $unf $nk]
				if {$nk == 0} {
					puts $fields_diff_table_file [format "  *Name*  %-*s\t\t%-*s" $width "" $width $ne] 
				}
				if {$nk == 1} {
					puts $fields_diff_table_file [format "  *Type*  %-*s\t\t%-*s" $width "" $width $ne] 
				}
				if {$nk == 2} {
					puts $fields_diff_table_file [format "  *Lgth*  %-*s\t\t%-*s" $width "" $width $ne] 
				}
				if {$nk == 3} {
					puts $fields_diff_table_file [format "  *Scal*  %-*s\t\t%-*s" $width "" $width $ne]
				}
			}
		}
	}
}

#�������
proc run {} {
	global cfg
	
	global old_dbhandle
	global new_dbhandle

	if [catch {set old_dbhandle [oralogon  $cfg(old_db_user)/$cfg(old_db_password)@$cfg(old_db_sid) ]} log_errmsg] {
		error $log_errmsg
	}
	
	if [catch {set new_dbhandle [oralogon  $cfg(new_db_user)/$cfg(new_db_password)@$cfg(new_db_sid)]} log_errmsg] {
		error $log_errmsg
	}
	
	if [catch {set old_qry_tab_handle [oraopen $old_dbhandle] } open_errmsg]   {
		  error $open_errmsg
	}
	
	if [catch {set new_qry_tab_handle [oraopen $new_dbhandle] } open_errmsg]   {
		  error $open_errmsg
	}
	
	#��ѯ����ģ�������еı�
	if {[catch {set old_tab_list [ query_table $old_qry_tab_handle ]} procError]} {
		if {[info exists old_qry_tab_handle]} { 
			oraclose $old_qry_tab_handle
		}
		puts "***Query Old Tables List Failure***"
		puts $procError
	} else {
		oraclose $old_qry_tab_handle
		puts "***Query Old Tables List OK***"
	}
	
	#��ѯ����ģ�������еı�
	if {[catch {set new_tab_list [ query_table $new_qry_tab_handle ]} procError]} {
		if {[info exists new_qry_tab_handle]} { 
			oraclose $new_qry_tab_handle
		}
		puts "***Query New Tables List Failure***"
		puts $procError
	} else {
		oraclose $new_qry_tab_handle
		puts "***Query New Tables List OK***"
	}
	
	#�Ƚ��¾�ģ����ӵ�еı�ͬʱ��������ģ�͹�ͬӵ�еı�
	if {[catch {set common_tab_list [ compare_tab $old_tab_list $new_tab_list ]} procError]} {
		puts "***Compare Tables Failure***"
		puts $procError
	} else {
		puts "***Compare Tables OK***"
	}
	
	#����Ƚ�ÿ����Ĳ��졣
	foreach common_table $common_tab_list {
    	if [catch {set old_qry_fields_handle [oraopen $old_dbhandle] } open_errmsg]   {
    		  error $open_errmsg
    	}
    	
    	if {[catch {set old_fields [query_fields_of_table $old_qry_fields_handle $common_table]} procError]} {
    		if {[info exists old_qry_fields_handle]} { 
    			oraclose $old_qry_fields_handle
    		}
    		puts "***Query Fields Failure***"
    		puts $procError
    	} else {
    		oraclose $old_qry_fields_handle
    		puts "***Query Fields OK***"
    	}
		
		if [catch {set new_qry_fields_handle [oraopen $new_dbhandle] } open_errmsg]   {
			  error $open_errmsg
		}
		
    	if {[catch {set new_fields [query_fields_of_table $new_qry_fields_handle $common_table]} procError]} {
    		if {[info exists new_qry_fields_handle]} { 
    			oraclose $new_qry_fields_handle
    		}
    		puts "***Query Fields Failure***"
    		puts $procError
    	} else {
    		oraclose $new_qry_fields_handle
    		puts "***Query Fields OK***"
    	}
		
		compare_fields $old_fields $new_fields $common_table
		
	}
	
	#��ʾ���Ƚ���ɡ���鿴�ԱȽ����
	puts "\n\nOK! Please see the result in the output files.\
			\nThe files is at $cfg(result_output_directory)\n\n"
	
}

run
