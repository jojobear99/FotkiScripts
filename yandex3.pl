#!/usr/bin/perl

=head1 DESCRIPTION

Download an entire album of photos from fotki.yandex.ru album using screen scraping (works for
albums over 100 photos, which cannot be fetched completely from the RSS feed since the next url
is broken).
Usage:
    perl yandex3.pl http://fotki.yandex.ru/users/user_name/album/12345678/ 8 "My Photo Album"
    arg1: album url
    arg2: number of photos in album (get from the album's webpage)
    arg3: subfolder to create/use to store pictures (optional)
    
This script created by Jessica Brown

=cut

use warnings;
use strict;

use HTML::TreeBuilder;
use POSIX; 


BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    eval "use LWP::Simple";
}

# --------------------------------------------------------------------
sub main {
	use constant NUM_PICTURES_PER_ALBUM_PAGE => 20;
    my $album_url = $ARGV[0] || die "use: $0 album_url\n";
    my $numimages = $ARGV[1] || 1;
    my $numpages = POSIX::ceil($numimages / NUM_PICTURES_PER_ALBUM_PAGE);
    my $dirname = $ARGV[2] || "";
    my $set_title = $ARGV[2] || "images";
    
    if ($dirname ne "") { 
    	# if directory doesn't exist and can't be created, user intervention needed
    	unless(-e $dirname or mkdir $dirname) {
    	    die "Unable to create $dirname\n";
    	}
    	$dirname = "./" . $dirname . "/";
    }
    
    
    
   	for (my $page = 0; $page <= $numpages -1; $page++) {
   		my $pageurl = $album_url . "?&p=" . $page;
   		print "\n------------------\n";
   		my $onebasedpagenum = $page +1;
   		print "Downloading <<$set_title>> page $onebasedpagenum of $numpages\n URL: $pageurl \n\n";
   		
   		my $html = get($pageurl);	
   		
   		my $tree = HTML::TreeBuilder->new_from_content($html);
   		
		foreach my $img ($tree->look_down('_tag', 'img')) {
		
			use constant RECENT_PHOTOS_WIDTH => 75;
			
			# Skip images without an alt tag because the album photos all have the original
			# upload filename as the alt tag, and photos without an alt tag are all ones we
			# don't want anyway like ads and userpics. 
			# we also need to filter out the three "most recent" images the user has uploaded.
			# It's not elegant, but checking the photo dimensions seems to be adequate for
			# albums I've tested.
			if ($img->attr('alt') && $img->attr('width') != RECENT_PHOTOS_WIDTH) {
			
		        my $photourl = $img->attr('src');
		        
		        # This is where the most important magic happens!
		        # The thumbnails end in _M _L _XL etc.
		        # we want to download original resolution, so change that to _orig
		        # Thank you to https://gist.github.com/msoap/4398036 for this technique
		        $photourl =~ s/_[a-z]+$/_orig/i; 
		          
		        my $photofilename = $img->attr('alt'); # use alt tag as filename
		        
		    	print "saving $photourl as $photofilename \n";
		        mirror($photourl, $dirname . $photofilename);
		    }
        }

        $tree->delete;
   		
   	}
}


main();
