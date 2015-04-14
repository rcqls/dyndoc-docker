FROM debian:jessie

MAINTAINER "Cqls Team"

## R Stuff (inspired from rocker/r-base)

## Set a default user. Available via runtime flag `--user docker` 
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory (for rstudio or linked volumes to work properly). (could use adduser to create this automatically instead)
RUN useradd docker \
&& mkdir /home/docker \
&& chown docker:docker /home/docker \
&& addgroup docker staff

RUN apt-get update && apt-get install -y --no-install-recommends \
    ed \
    less \
    locales \
    vim-tiny \
    wget \
    && rm -rf /var/lib/apt/lists/*

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
&& locale-gen en_US.utf-8 \
&& /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

## Use Debian unstable via pinning -- new style via APT::Default-Release
RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
    && echo 'APT::Default-Release "jessie";' > /etc/apt/apt.conf.d/default


ENV R_BASE_VERSION 3.1.3

## Now install R and littler, and create a link for littler in /usr/local/bin
## Also set a default CRAN repo, and make sure littler knows about it too
RUN apt-get update \
    && apt-get install -t unstable -y --no-install-recommends \
        littler/unstable \
        r-base=${R_BASE_VERSION}* \
        r-base-dev=${R_BASE_VERSION}* \
        r-recommended=${R_BASE_VERSION}* \
        && echo 'options(repos = list(CRAN = "http://cran.rstudio.com/"))' >> /etc/R/Rprofile.site \
        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
    && ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
    && ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
    && ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
    && ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
    && install.r docopt \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

## Ruby Stuff

RUN apt-get update && apt-get install -y curl procps && rm -rf /var/lib/apt/lists/*

ENV RUBY_MAJOR 2.1
ENV RUBY_VERSION 2.1.5

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get update \
	&& apt-get install -y bison ruby ruby-dev

# skip installing gem documentation
RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc"

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
RUN gem install bundler \
	&& bundle config --global path "$GEM_HOME" \
	&& bundle config --global bin "$GEM_HOME/bin"

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

## Latex texlive full without doc

RUN mkdir /texlive2014nodoc

WORKDIR /texlive2014nodoc

COPY full2014nodoc.profile /texlive2014nodoc/

RUN  apt-get update && apt-get install -y wget tar perl fontconfig \
     && wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
     && tar -xvf *.tar.gz 
RUN cd install-tl-* \
    && ./install-tl --profile /texlive2014nodoc/full2014nodoc.profile

RUN rm -fr /texlive2014nodoc

ENV PATH $PATH:/usr/local/texlive/2014/bin/x86_64-linux

## Pandoc

RUN apt-get update -y && apt-get install -y pandoc

## Ttm 

RUN mkdir -p /tmp/ttm

WORKDIR /tmp/ttm

RUN wget http://hutchinson.belmont.ma.us/tth/mml/ttmL.tar.gz

RUN tar xzvf ttmL.tar.gz

WORKDIR /tmp/ttm/ttmL

RUN mkdir -p $HOME/bin

ENV PATH $HOME/bin:$PATH

RUN ./ttminstall

RUN rm -fr /tmp/ttm

## Dyndoc

RUN apt-get update -y && apt-get install -y git

RUN gem install rake configliere ultraviolet

RUN mkdir -p /tmp/dyndoc

WORKDIR /tmp/dyndoc

RUN git clone https://github.com/rcqls/R4rb.git 

WORKDIR R4rb

RUN rake docker

WORKDIR /tmp/dyndoc

RUN git clone https://github.com/rcqls/dyndoc-ruby-core.git 

WORKDIR dyndoc-ruby-core

RUN rake docker

WORKDIR /tmp/dyndoc

RUN git clone https://github.com/rcqls/dyndoc-ruby-doc.git 

WORKDIR dyndoc-ruby-doc

RUN rake docker

WORKDIR /tmp/dyndoc

RUN git clone https://github.com/rcqls/rb4R.git && R CMD INSTALL rb4R


## Init dyndoc home
RUN mkdir -p /dyndoc && echo "/dyndoc" > $HOME/.dyndoc_home

WORKDIR /tmp/dyndoc

RUN git clone https://github.com/rcqls/dyndoc-ruby-install.git && cp -r ./dyndoc-ruby-install/dyndoc_basic_root_structure/* /dyndoc

RUN rm -fr /tmp/dyndoc

RUN ln -s /dyndoc/bin/dyndoc-compile.rb /usr/local/bin/dyn \
	&& ln -s /dyndoc/bin/dyndoc-package.rb /usr/local/bin/dpm \
	&& ln -s /dyndoc/bin/dyndoc-server-simple.rb /usr/local/bin/dyn-srv

## mountpoints are for
RUN mkdir /dyndoc-library
VOLUME /dyndoc-library

## dyndoc: 	/dyndoc-library/dyndoc
RUN echo "/dyndoc-library/dyndoc" > /dyndoc/etc/dyndoc_library_path
ENV DYNDOC_LIBRARY /dyndoc-library/dyndoc

## R:		/dyndoc-library/R
ENV R_LIBS_USER /dyndoc-library/R

## ruby:	/dyndoc-library/ruby
ENV GEM_PATH /dyndoc-library/ruby:$GEM_HOME
## Last change for .gemrc to make "gem (un)install <package>" persistant  
RUN echo "gem: --no-rdoc --no-ri -i /dyndoc-library/ruby" > ~/.gemrc



# cleanup package manager

RUN apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## the dyndoc projects folder

RUN mkdir /dyndoc-proj

VOLUME /dyndoc-proj

WORKDIR /dyndoc-proj

## Port exposed by dyn-srv

EXPOSE 7777

## the server to expose

CMD ["/usr/local/bin/dyn-srv"]

## END


