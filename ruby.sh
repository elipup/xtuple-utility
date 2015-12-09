#!/bin/bash

install_ruby() {
    sudo apt-get -q -y install rubygems-integration && \
    sudo gem install compass -v 0.12.7 && \
    sudo gem install bootstrap-sass -v 3.2.0.1
}