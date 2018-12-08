FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y curl xml2 wget mysql-client \
    perl-modules-5.26 libxml-simple-perl \
    libgetargs-long-perl

COPY mediawiki/ mediawiki/
COPY add_target_ids_to_pagelinks.pl .
COPY build_all_selections.sh .
COPY build_biggest_wikipedia_list.sh .
COPY build_en_vital_articles_list.sh .
COPY build_projects_lists.pl .
COPY build_scores.pl .
COPY build_selections.sh .
COPY merge_lists.pl .

CMD [ "/bin/bash" ]