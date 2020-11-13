ARG PHP_VERSION
FROM docker.pkg.github.com/nxtlvlsoftware/pmmp-php-build/php-dev:${PHP_VERSION}

USER root

RUN apt-get update && apt-get install --no-install-recommends -y build-essential

WORKDIR /build
ADD build /build/build
ADD composer.json /build/composer.json
ADD composer.lock /build/composer.lock
ADD src /build/src
ADD resources /build/resources
RUN composer install --classmap-authoritative --no-dev --prefer-source
RUN php build/preprocessor/PreProcessor.php --path=/build/src
RUN php resources/vanilla/.minify_json.php

RUN php -dphar.readonly=0 build/server-phar.php --out=PocketMine-MP.phar --git=$(git rev-parse HEAD)

# Just to make sure DevTools didn't false-positive-exit
RUN test -f /build/PocketMine-MP.phar

FROM docker.pkg.github.com/nxtlvlsoftware/pmmp-php-build/php:${PHP_VERSION}
MAINTAINER NxtLvl Software <contact@nxtlvlsoftware.net>

USER root

WORKDIR /pocketmine
COPY --from=0 /build/PocketMine-MP.phar PocketMine-MP.phar
RUN chown 1000:1000 . -R

USER php

EXPOSE 19132/udp

ENTRYPOINT ["php", "PocketMine-MP.phar"]

CMD ["--no-wizard", "--disable-ansi"]