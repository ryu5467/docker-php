FROM php:7.0.30-fpm

# 拷贝需要用到的资源
COPY resource /home/resource
COPY start.sh /home/start.sh
# 默认不改变 apt-get 源
ARG CHANGE_SOURCE=false

# 修改时区
ARG TIME_ZONE=UTC
ENV TIME_ZONE ${TIME_ZONE}
RUN ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone

# 安装 PHP Composer
RUN mv /home/resource/composer.phar /usr/local/bin/composer && \
    chmod 755 /usr/local/bin/composer

# 替换源
RUN rm -rf /etc/apt/sources.list.d/buster.list
RUN mv /etc/apt/sources.list /etc/apt/source.list.bak && \
    mv /home/resource/sources.list /etc/apt/sources.list

# 更新、安装基础组件
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    apt-utils procps libpq-dev libfreetype6-dev \
    libjpeg62-turbo-dev libpng-dev  ntpdate \
    cron vim unzip git wget libzip-dev zlib1g-dev

####################################################################################
# 安装 PHP 扩展
####################################################################################

RUN docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/freetype2 \
    --with-jpeg-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --enable-gd-native-ttf


RUN docker-php-ext-install gd pdo_mysql mysqli pgsql pdo_pgsql pcntl bcmath

# Zip
RUN pecl install /home/resource/zip-1.18.2.tgz && \ 
    echo "extension=zip.so" > /usr/local/etc/php/conf.d/zip.ini

# # XDebug
RUN pecl install /home/resource/xdebug-2.5.5.tgz


# Redis
RUN pecl install /home/resource/redis-5.2.1.tgz && \ 
    echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini

# composer 阿里镜像
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/


ENV LC_ALL C.UTF-8


ENTRYPOINT ["/bin/bash", "/home/start.sh"]
