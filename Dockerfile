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
    wget

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
&& locale-gen en_US.utf-8 \
&& /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8

## Use Debian repo at CRAN, and use RStudio CDN as mirror
## This gets us updated r-base, r-base-dev, r-recommended and littler
RUN apt-key adv --keyserver keys.gnupg.net --recv-key 381BA480 \
&& echo "deb http://cran.rstudio.com/bin/linux/debian wheezy-cran3/" > /etc/apt/sources.list.d/r-cran.list

ENV R_BASE_VERSION 3.1.2

## Now install R and littler, and create a link for littler in /usr/local/bin
RUN apt-get update -qq \
&&  apt-get install -y --no-install-recommends \
    littler \
    r-base=${R_BASE_VERSION}* \
    r-base-dev=${R_BASE_VERSION}* \
    r-recommended=${R_BASE_VERSION}* \
&&  ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
&&  ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
&&  ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
&&  ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
&&  install.r docopt \
&&  rm -rf /tmp/downloaded_packages/ /tmp/*.rds

## Set a default CRAN Repo
RUN echo 'options(repos = list(CRAN = "http://cran.rstudio.com/"))' >> /etc/R/Rprofile.site

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

## Pandoc

RUN apt-get update -y && apt-get install -y pandoc

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

RUN git clone https://github.com/rcqls/dyndoc-ruby-install.git && cp -r dyndoc-ruby-install/dyndoc_basic_root_structure/* /dyndoc

WORKDIR /dyndoc

RUN rm -fr /tmp/dyndoc

RUN ln -s /dyndoc/bin/dyndoc-compile.rb /usr/local/bin/dyn \
	&& ln -s /dyndoc/bin/dyndoc-package.rb /usr/local/bin/dpm



