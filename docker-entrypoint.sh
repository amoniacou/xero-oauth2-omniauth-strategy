#!/bin/bash
set -e

if ! whoami &> /dev/null; then
    if [ -w /etc/passwd ]; then
        echo "${USER_NAME:-appuser}:x:$(id -u):0:${USER_NAME:-appuser} user:${APP_ROOT}:/sbin/nologin" >> /etc/passwd
    fi
fi

if [[ "$1" == "bundle" ]] || [[ "$1" == "yarn" ]] || [[ "$1" == "rails" ]]; then
  exec "$@"
fi


if [ -f /tmp/puma.pid ]; then
    echo "Cleaning server PID file"
    rm /tmp/puma.pid
fi

if [ -f /app/vendor/bundle/ruby/2.7.0/bin/rails ]; then
  echo "postdeploy"
  export RAILS_ENV=production
  env
  cd /app && bundle exec rake db:create db:migrate
fi

exec "$@"
