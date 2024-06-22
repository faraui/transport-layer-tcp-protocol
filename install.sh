if ! command -v cpanm &> /dev/null
then echo -n "Installing 'App::cpanminus' ..."
     ( cpan App::cpanminus > /dev/null 2> install.log && \
       rm -rf install.log && \
       echo ' OK'
     ) || \
     ( echo ' FAIL'
       echo "See 'install.log' for details"
     )
fi

cpanm -q warnings && \
cpanm -q strict && \
cpanm -q Digest::MD5 && \
cpanm -q MIME::Base64 && \
cpanm -q File::Basename && \
cpanm -q FindBin && \
cpanm -q Data::Dumper && \
cpanm -q Exporter && \
cpanm -q IO::Socket
