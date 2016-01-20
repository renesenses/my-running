RESULT=Step;
if (Step==0) {
	prefix="40";
	postfix="@1"; 
	if (SUUNTO_PACE > 6.00) { Suunto.alarmBeep();postfix="+545";}
	if (SUUNTO_PACE < 5.30) { Suunto.alarmBeep();postfix="-545";}
	if (SUUNTO_DURATION - TmpDuration >= 2400) {
		Suunto.alarmBeep();
		Step=Step+1;
		TmpDuration=SUUNTO_DURATION;
	}
}
else if (Step==1 || Step==3 || Step==5) {
	prefix ="10";
	postfix = "@3";  
	if (SUUNTO_PACE > 4.50) { Suunto.alarmBeep();postfix="+435";}
	if (SUUNTO_PACE < 4.20) { Suunto.alarmBeep();postfix="-435";}
	if (SUUNTO_DURATION - TmpDuration >= 600) {
		Suunto.alarmBeep();
		Step=Step+1;
		TmpDuration=SUUNTO_DURATION;
	}
}
else if (Step==2 || Step==4) {
	prefix ="1m30";
	postfix = "@T"; 
	if (SUUNTO_PACE < 7.00) { Suunto.alarmBeep();postfix="-T";}
	if (SUUNTO_DURATION - TmpDuration >= 90) {
		Suunto.alarmBeep();
		Step=Step+1;
		TmpDuration=SUUNTO_DURATION;
	}
}
else if (Step==6) {
	prefix="40";
	postfix="@1"; 
	if (SUUNTO_PACE > 6.00) { Suunto.alarmBeep();postfix="+545";}
	if (SUUNTO_PACE < 5.30) { Suunto.alarmBeep();postfix="-545";}
	if (SUUNTO_DURATION - TmpDuration >= 3000) {
		Suunto.alarmBeep();
		Step=Step+1;
		TmpDuration=SUUNTO_DURATION;
	}
}