# **  此脚本用来读取data_dic.txt字典文件，并将相应信息保存到cfg全局数组里
# **  创建日期：2010-8-16
# **  创建人员：付骋
# **  修改日期：李君（D瓜哥，http://www.diguage.com/）
# **  修改人员：2012-3-19
global cfg
set fid [open "$absoluteParentPath//compare//config.txt" r]
while {[eof  $fid] != 1} {
	set curLine [gets $fid]
	# 遇到空行或者以#开头的行，忽略
	if {[regexp {(^(\s)*#)|(^(\s)*$)} $curLine]} {
		continue
	}
	set curLineList [split $curLine "|"]
	# 数组索引
	set index [lindex $curLineList 0]
	# 对应值
	set value [lindex $curLineList 1]
	set cfg($index) $value
}
close $fid
