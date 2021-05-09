# nginx + PHP5-FPM + MariaDB + supervisord on Docker
#
# VERSION               0.0.2
FROM        ubuntu:14.04.5
MAINTAINER  Michael Dodwell "michael@dodwell.us"

ENV LANG C.UTF-8

# install curl, wget, git
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q curl wget git

# Configure repos
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q python-software-properties software-properties-common apt-transport-https ca-certificates
# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.3``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
# Add passenger repo
RUN echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger $(lsb_release --codename --short) main" > /etc/apt/sources.list.d/passenger.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
# Add nginx repo
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q pgdg-keyring

# Install ruby 1.9.1a and setup
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q ruby ruby1.9.1 ruby1.9.1-dev ri1.9.1 build-essential libssl-dev zlib1g-dev
RUN /usr/bin/update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 400 --slave /usr/share/man/man1/ruby.1.gz ruby.1.gz /usr/share/man/man1/ruby1.9.1.1.gz --slave /usr/bin/ri ri /usr/bin/ri1.9.1 --slave /usr/bin/irb irb /usr/bin/irb1.9.1 --slave /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.1

# Install PostgreSQL and setup
RUN apt-get -y -q install postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3

# Run commands as postgres
USER postgres

# Create a PostgreSQL role named ``puppetdb`` with ``puppetdb`` as the password and
# then create a database `puppetdb` owned by the ``puppetdb`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER puppetdb WITH SUPERUSER PASSWORD 'puppetdb';" &&\
    createdb -O puppetdb puppetdb

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible. 
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Run commands as root
USER root

# Install nginx
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q nginx-extras ruby-passenger

# expose port 80
EXPOSE 80

# Install/Configure PuppetDB
RUN apt-get install -y -q puppetdb
RUN puppetdb ssl-setup -f
ADD puppetdb_database.ini /etc/puppetdb/conf.d/database.ini

# Configure nginx for Puppet
ADD nginx_default.conf /etc/nginx/conf.d/default.conf
ADD nginx_puppetmaster.conf /etc/nginx/conf.d/puppetmaster.conf
ADD nginx.conf /etc/nginx/nginx.conf
VOLUME  ["/etc/nginx", "/var/log/nginx"]

# Configure puppet
RUN apt-get install -y -q puppet
RUN rm -rf /etc/puppet
RUN /usr/bin/git clone http://github.com/dodwmd/puppet-generic /etc/puppet
RUN gem install librarian-puppet
RUN cd /etc/puppet && librarian-puppet install
RUN chown -R puppet:puppet /etc/puppet
VOLUME  ["/etc/puppet"]

# expose puppetmaster port
EXPOSE 8140

# Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q supervisor
ADD supervisord.conf /etc/supervisord.conf

CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
