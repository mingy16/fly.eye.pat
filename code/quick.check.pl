$dir=shift;
@f=glob "$dir/*";
for(@f){
	@a=glob "$_/*jpg";
	print "$_ ",scalar(@a),"\n";
}

