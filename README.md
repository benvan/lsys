interactive l-system generator written in coffeescript

see it running: http://benvan.co.uk/lsys

INSTALLING / RUNNING

./run - this script requires npm

If you'd rather do things manually, you'll need to compile coffee/* into js/generated/*.js

Currently, the classes are not namespaced - so ./run uses the -b flag when invoking coffee-script / jitter.
