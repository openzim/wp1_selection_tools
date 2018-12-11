FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    cron ca-certificates curl xml2 wget mysql-client \
    perl-modules-5.26 libxml-simple-perl \
    libgetargs-long-perl p7zip-full lzma \
    openssh-client libwww-perl

COPY mediawiki/ mediawiki/
COPY add_target_ids_to_pagelinks.pl .
COPY build_all_selections.sh .
COPY build_biggest_wikipedia_list.sh .
COPY build_en_vital_articles_list.sh .
COPY build_projects_lists.pl .
COPY build_scores.pl .
COPY build_selections.sh .
COPY merge_lists.pl .

CMD { \
  echo "#!/bin/sh" ; \
  echo "/build_all_selections.sh" ; \
} > /etc/cron.monthly/wp1_selection_tools && chmod a+x /etc/cron.monthly/wp1_selection_tools && cron -f