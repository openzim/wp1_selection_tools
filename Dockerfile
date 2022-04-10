FROM ubuntu:focal

RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
    cron ca-certificates curl xml2 wget mysql-client \
    libperl5.30 libxml-simple-perl \
    libgetargs-long-perl p7zip-full lzma \
    openssh-client liblist-compare-perl libwww-perl \
    parallel unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY mediawiki/ mediawiki/
COPY build_all_selections.sh .
COPY build_biggest_wikipedia_list.sh .
COPY build_en_vital_articles_list.sh .
COPY build_custom_selections.sh .
COPY build_projects_lists.pl .
COPY build_translated_list.pl .
COPY build_scores.pl .
COPY build_selections.sh .
COPY merge_lists.pl .
COPY compare_lists.pl .
COPY customs/ customs/

CMD { \
  echo "#!/bin/sh" ; \
  echo "/usr/bin/flock -w 0 /dev/shm/cron.lock /build_all_selections.sh" ; \
} > /etc/cron.monthly/wp1_selection_tools && chmod a+x /etc/cron.monthly/wp1_selection_tools && cron -f
