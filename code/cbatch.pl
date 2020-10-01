
$sh=shift;

$one=2;
for(1..28){
        $i=$_;
        $head=$i*$one;
        $a=`head -$head $sh | tail -$one`;
	$a=~s/\s+$//;
	$a=substr($a,0,-1);
	print "$a\n";
	print "wait\n";
}




