# **  �˽ű�������ȡconfig.txt�����ļ���������Ӧ��Ϣ���浽cfgȫ��������
#
# **  ������Ա������
# **  �������ڣ�2010-8-16
# 
# **  �޸���Ա�������Nickname��D�ϸ磻Website��http://www.diguage.com/��
# **  �޸����ڣ�2012-3-19
#
# **  Copyright (c) 2012-2012 D�ϸ磬http://www.diguage.com/
# **  Licensed under the Apache License, Version 2.0 (the "License");
# 

global cfg
set fid [open "$absoluteParentPath//config//config.txt" r]
while {[eof  $fid] != 1} {
	set curLine [gets $fid]
	# �������л�����#��ͷ���У�����
	if {[regexp {(^(\s)*#)|(^(\s)*$)} $curLine]} {
		continue
	}
	set curLineList [split $curLine "|"]
	# ��������
	set index [lindex $curLineList 0]
	# ��Ӧֵ
	set value [lindex $curLineList 1]
	set cfg($index) $value
}
close $fid
