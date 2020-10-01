#nohup Rscript ming-Rimage.R image-segmentation-func.R ../200-original-images/ result/ > record.txt &
$dir=shift;
@line=glob "$dir/RAL*";
for(@line){
	print "$_\n";
	$in=$_;
	#../../2018-06-11-Ab_T_images/lines/RAL-892
	$line=(split/\//)[-1];
	print "$line\n";
	mkdir($line);
	print "nohup Rscript ../code/ming-Rimage.R ../code/image-segmentation-func.R $in $line";
    print ' & echo $! >>error.log;',"\n";	
}
