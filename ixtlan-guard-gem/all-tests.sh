#!/bin/bash

echo "install gem"
echo "-----------"
echo
rmvn clean gem:exec install -Dmaven.test.skip -Dargs="target/rubygems/bin/rspec spec" || exit -1
rmvn gem:gem -Dargs="install --no-user-install -l `ls -1 target/ixtlan-guard*gem`" || exit -1
ruby -S gem install `ls -1 target/ixtlan-guard*gem` || exit -1
jruby -S gem install `ls -1 target/ixtlan-guard*gem` || exit -1

echo
echo "ruby cucumber"
echo "-------------"
echo
rm -rf target/simple
rm -rf target/user_management
ruby -S cucumber || exit -1

echo
echo "jruby cucumber"
echo "--------------"
echo
rm -rf target/simple
rm -rf target/user_management
jruby -S cucumber || exit -1

echo
echo "rmvn cucumber"
echo "-------------"
echo
rm -rf target/simple
rm -rf target/user_management
rmvn gem:initialize -f Gemfile || exit -1
rmvn cucumber:test || exit -1



