# **  �˽ű�������ȡconfig.txt�����ļ���������Ӧ��Ϣ���浽cfgȫ��������
# **  �������ڣ�2010-8-16
# **  ������Ա������
# **  �޸����ڣ������D�ϸ磬http://www.diguage.com/��
# **  �޸���Ա��2012-3-19
global cfg
set fid [open "$absoluteParentPath//src//config.txt" r]
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
