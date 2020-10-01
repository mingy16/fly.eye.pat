sub print_dir{
 #print $_[0],"\n";
 my $x=$_[0];
 if($x=~/.jpg$/ && ($x=~/day28/ || $x=~/Day28/)){
	push @files,$x;
 }
 if($x=~/.jpg$/){
 	push @files2,$x
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

$dir=shift; 
dir_walk($dir,\&print_dir);	

for(@files){print "$_\n"}
$total=scalar(@files);
print "#total day28 jpg: $total\n";

for(@files2){print "$_\n"}
$total=scalar(@files2);
print "#total jpg: $total\n";
