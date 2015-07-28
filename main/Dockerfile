FROM rocker/r-base:latest

MAINTAINER "Cqls Team"

RUN apt-get update

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

## Dyndoc

RUN apt-get install -y git

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

## R packages

RUN Rscript -e 'install.packages("base64")'

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


