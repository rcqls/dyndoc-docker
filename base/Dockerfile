FROM debian:testing

MAINTAINER "Cqls Team"

RUN apt-get update

## R Stuff (inspired from rocker/r-base)

## Set a default user. Available via runtime flag `--user docker` 
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory (for rstudio or linked volumes to work properly). (could use adduser to create this automatically instead)
RUN useradd docker \
&& mkdir /home/docker \
&& chown docker:docker /home/docker \
&& addgroup docker staff

RUN apt-get install -y --no-install-recommends \
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
    && echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default


ENV R_BASE_VERSION 3.2.1

## Now install R and littler, and create a link for littler in /usr/local/bin
## Also set a default CRAN repo, and make sure littler knows about it too
RUN apt-get install -t unstable -y --no-install-recommends \
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

RUN apt-get install -y curl procps && rm -rf /var/lib/apt/lists/*

ENV RUBY_MAJOR 2.1
ENV RUBY_VERSION 2.1.5

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get update \
	&& apt-get install -y bison ruby ruby-dev

# skip installing gem documentation
RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc"

## Latex texlive full without doc

RUN mkdir /texlive2014nodoc

WORKDIR /texlive2014nodoc

COPY full2014nodoc.profile /texlive2014nodoc/

RUN apt-get install -y wget tar perl fontconfig \
     && wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
     && tar -xvf *.tar.gz 
RUN cd install-tl-* \
    && ./install-tl --profile /texlive2014nodoc/full2014nodoc.profile

RUN rm -fr /texlive2014nodoc

ENV PATH $PATH:/usr/local/texlive/2014/bin/x86_64-linux

## Pandoc

RUN apt-get install -y pandoc

## Ttm 

RUN mkdir -p /tmp/ttm

WORKDIR /tmp/ttm

RUN wget http://hutchinson.belmont.ma.us/tth/mml/ttmL.tar.gz

RUN tar xzvf ttmL.tar.gz

WORKDIR /tmp/ttm/ttmL

RUN mkdir -p /root/bin

ENV PATH /root/bin:$PATH

RUN ./ttminstall

RUN rm -fr /tmp/ttm

## R:		/dyndoc-library/R
ENV R_LIBS_USER /dyndoc-library/R

## Install devtools R package and its dependencies
RUN apt-get install -y libxml2-dev  libcurl4-openssl-dev libssl-dev && install.r devtools



# cleanup package manager

RUN apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## the dyndoc projects folder

RUN mkdir -p /dyndoc-proj

VOLUME /dyndoc-proj

WORKDIR /dyndoc-proj

## Port exposed by dyn-srv

EXPOSE 7777

## the server to expose

CMD ["/usr/local/bin/dyn-srv"]

## END


