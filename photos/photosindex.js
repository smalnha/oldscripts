var thumbtext_size=16;
var thumbtext_color="#FFFF00";

var numpics = vThumb.length;

var counter = -1;

if (subdir==null){
	var subdir="../"; // dir holding images/ and html/, used by control.html and thumbs.html
}

document.title=title;

document.open();
document.write("<frameset border=1 bordercolor=#000000 cols=\"175, *\">");
document.write("	<frameset border=0 bordercolor=#000000 rows=\"100,*\">");
document.write("		<frame src=\""+commondir+"control.html\" marginwidth=0 marginheight=0 name=control>");
document.write("		<frame src=\""+commondir+"thumbs.html\" marginwidth=0 marginheight=0 name=thumbnails>");
document.write("	</frameset>");
document.write("	<frame src=\""+commondir+"instructs.html\" name=photo>");
document.write("</frameset>");
document.close();
