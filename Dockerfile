FROM docker.io/julia:1.10-bullseye AS docker

RUN echo "deb http://deb.debian.org/debian/ bullseye contrib non-free" >> /etc/apt/sources.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3-pip \ 
    cmake \
    git

RUN pip3 install cython==0.29.36
RUN pip3 install git+https://github.com/sisl/Python-RVO2.git

RUN git clone https://github.com/sisl/ConstructionBots.jl.git /ConstructionBots

WORKDIR /ConstructionBots

# Install package
RUN julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"
#    julia -e 'import Pkg; Pkg.add("PackageCompiler")'

#COPY build.jl .
#RUN ls && sed '$e cat build.jl' ./src/ConstructionBots.jl

#RUN julia --project=. -e '\
#    using Pkg; Pkg.instantiate(); \
#    using PackageCompiler; create_app(".", "dist", include_lazy_artifacts=true)'

RUN mkdir -p /usr/share/ldraw/
RUN mkdir -p ~/Documents/ && ln -s /usr/share/ldraw/ ~/Documents/
RUN mkdir -p output/

#CMD ["julia", "--project=."]
ADD entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

FROM debian:11 AS debian

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ruby \
    squashfs-tools \
    binutils

RUN gem install fpm && fpm --version

WORKDIR /dist
ADD construction-bots.sh /construction-bots.sh
ADD afterinstall.sh /afterinstall.sh

RUN nightly=$(date +"%Y.%m.%d") && \
    fpm \
    -s dir -t deb \
    -p construction-bots-nightly-$nightly-amd64.deb \
    --name construction-bots-nightly \
    --license agpl3 \
    --version $nightly \
    --architecture amd64 \
    --depends bash --depends podman --depends ldraw-parts \
    --description "An open-source multi-robot manufacturing simulator designed to test algorithms for multi-robot assembly planning." \
    --url "" \
    --maintainer "debilin <croninlucio@gmail.com>" \
    --after-install /afterinstall.sh \
      /construction-bots.sh=/usr/local/bin/construction-bots
