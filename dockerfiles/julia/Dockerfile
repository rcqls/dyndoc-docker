FROM rcqls/dyndocker:latest

MAINTAINER "Cqls Team"



RUN mkdir -p /tmp/julia

WORKDIR /tmp/julia

RUN wget https://julialang.s3.amazonaws.com/bin/linux/x64/0.3/julia-0.3.11-linux-x86_64.tar.gz

RUN tar xzvf julia-0.3.11-linux-x86_64.tar.gz \
    && rm julia-0.3.11-linux-x86_64.tar.gz \
    && mv "$(ls -d julia-*)" julia-0.3.11 \
    && mv julia-0.3.11 / \
    && rm -fr /tmp/julia



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


