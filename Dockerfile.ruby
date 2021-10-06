FROM openaustralia/buildstep:early_release

RUN apt update -y

RUN gem install scraperwiki \
    && gem install open-uri \
    && gem install nokogiri

RUN gem install rake ruby-debug-ide --pre

RUN useradd morph

USER morph