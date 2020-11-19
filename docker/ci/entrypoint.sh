#!/bin/bash
set -e

export PGBIN="$(pg_config --bindir)"

su - postgres -c "$PGBIN/initdb -E UTF8 -D /tmp/nulldb"
su - postgres -c "$PGBIN/pg_ctl -D /tmp/nulldb -l /dev/null -w start"
echo "create database app; create user app with superuser encrypted password 'p4ssw0rd'; grant all privileges on database app to app;" | su - postgres -c psql

mkdir -p /usr/local/bundle
mkdir -p /home/$USER/openproject/frontend/node_modules
# mkdir -p /home/$USER/openproject/public/assets/frontend
mkdir -p /home/$USER/openproject/tmp

chown $USER:$USER /usr/local/bundle
chown $USER:$USER /home/$USER/openproject/frontend/node_modules
# chown $USER:$USER /home/$USER/openproject/public/assets/frontend
chown $USER:$USER /home/$USER/openproject/tmp
# chown -R $USER:$USER /home/$USER/openproject

cp docker/ci/database.yml config/

# for parallel rspec
export PARALLEL_TEST_PROCESSORS=$JOBS

if [ "$1" == "setup" ]; then
	echo "Preparing environment for running tests..."
	shift

	su $USER -c "time bundle install -j$JOBS"
	su $USER -c "TEST_ENV_NUMBER=0 time bash ./script/ci/cache_prepare.sh"
	su $USER -c "time bundle exec rake parallel:setup"
fi

if [ "$1" == "run-units" ]; then
	shift
	exec su $USER -c "time bundle exec rake parallel:units"
fi

if [ "$1" == "run-features" ]; then
	shift
	exec su $USER -c "time bundle exec rake parallel:features"
fi

exec "$@"
