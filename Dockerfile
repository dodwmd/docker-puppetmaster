# nginx + PHP5-FPM + MariaDB + supervisord on Docker
#
# VERSION               0.0.2
FROM        ubuntu:14.04
MAINTAINER  Michael Dodwell "michael@dodwell.us"

ENV LANG C.UTF-8

# install curl, wget, git
RUN apt-get install -y curl wget git

# Configure repos
RUN apt-get install -y python-software-properties software-properties-common apt-transport-https ca-certificates
# Add postgres repo
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release --codename --short)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN /usr/bin/wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
# Add passenger repo
RUN echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger $(lsb_release --codename --short) main" > /etc/apt/sources.list.d/passenger.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
# Add nginx repo
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
RUN apt-get install pgdg-keyring

# Install PostgreSQL
RUN apt-get -y install postgresql-9.3 postgresql-contrib-9.3

# Install nginx
RUN apt-get -y install nginx-extras passenger

# Configure nginx for Puppet
ADD nginx_default.conf /etc/nginx/conf.d/default.conf
ADD nginx_puppetmaster.conf /etc/nginx/conf.d/puppetmaster.conf
ADD nginx.conf /etc/nginx/nginx.conf
ADD start_postgres /usr/sbin/start_postgres
RUN rm -rf /etc/puppet
RUN /usr/bin/git clone http://github.com/dodwmd/puppet-generic /etc/puppet
RUN gem install librarian-puppet
RUN librarian-puppet install
RUN chown -R puppet:puppet /etc/puppet

# Supervisord
RUN apt-get -y install python-setuptools
RUN easy_install supervisor
ADD supervisord.conf /etc/supervisord.conf

EXPOSE 80

CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
