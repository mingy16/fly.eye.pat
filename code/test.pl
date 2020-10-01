sub print_dir{
 #print $_[0],"\n";
 my $x=$_[0];
 if($x=~/.jpg$/ && ($x=~/day28/ || $x=~/Day28/)){
	push @files,$x;
 }
}
sub dir_walk{
  my ($top,$code)=@_;
  my $DIR;
  $code->($top);

  if(-d $top){
    my $file;
    opendir $DIR, $top;

    while($file=readdir $DIR){
  	next if $file eq '.' || $file eq '..';
       dir_walk("$top/$file",$code);
   } 
  }	
}

$dir=shift; $dir2=shift; #target
dir_walk($dir,\&print_dir);	
#for(@files){print "$_\n"}
#$total=scalar(@files);
#print "#total day28 jpg: $total\n";

for(@files){
	$filename=$_;
	@tmp=split('/',$filename);
	$human=$tmp[-2];
	$human=(split/\_/,$human)[-1];
	print "human $human\n";

	$hu{$filename}=$human;

	if($filename=~/R32c/i){
		$name='R32c';
		print "here1 $name,$filename\n";
	}elsif($filename=~/R32\_\d+\_/){
		    #Group27.day28.R32_280_5.jpg
			$filename=~m/R32\_(\d+)\_/;
			$name=$1;
			print "here2 $1,$filename\n";
	}else{
		@a=($filename=~m/(Ral_\d+)/i); #RAL_322
		$name=$a[0];
		
		if($name ne ''){
			print "here3 $name, $filename\n";
		}else{      #RAL322
			@a=($_=~m/(Ral\d+)/i);
			$name=$a[0]; 
			print "here4 $name, $filename\n";
		}
	}

	if($name eq ''){push @no,$filename}
	else{
		@a=($name=~m/(\d+)/);
		$index=$a[0]; #line number
		#print "check $_, $name, $index\n";
		#$name=uc($name);
		push @{$h->{$index}},$_;
	}
}

if(@no!=0){
	print "#some images don't have Ral line number!\n";
	for(@no){ print "\t$_\n"}
}
else{ print "#all images have Ral line number!\n"}
