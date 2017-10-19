
use Mail::Cap;

my $mc = new Mail::Cap;
my $mt = 'image/svg';
 $desc = $mc->description($mt);
 $bmp = $mc->x11_bitmap($mt);
 $nt = $mc->nametemplate($mt);
 $nl = $mc->textualnewlines($mt);

 $vcmd = $mc->viewCmd($mt);
 $ccmd = $mc->composeCmd($mt);
 $ecmd = $mc->editCmd($mt);
 $pcmd = $mc->printCmd($mt);

 print "$mt:  bmp=$bmp; desc=$desc; $nt; $nl; view=$vcmd; compose=$ccmd; edit=$ecmd; print=$pcmd;\n";
 $cmd = $mc->viewCmd('text/plain; charset=iso-8859-1', 'file.txt');
