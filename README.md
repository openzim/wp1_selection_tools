The **WP1 Selection tools** gather and compile multiple indicators to
provide [Wikipedia](http://wikipedia.org) article subset
selections. It has been created for the [Wikipedia
1.0](https://en.wikipedia.org/wiki/Wikipedia:1) project and is
complementary of the [WP1 engine](https://github.com/openzim/wp1).

The results are made available at
[https://download.openzim.org/wp1](https://download.openzim.org/wp1).

[![CodeFactor](https://www.codefactor.io/repository/github/openzim/wp1_selection_tools/badge)](https://www.codefactor.io/repository/github/openzim/wp1_selection_tools)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Requirements
------------

To run it, you need:
* MANDATORY: a GNU/Linux system
* MANDATORY: an access to Internet
* MANDATORY: an access to a Wikipedia database
* OPTION: an access to enwp10 rating database for Wikipedia in English

Context
-------

Many Wikipedias, in different languages, have more than 500.000
articles and even if we can provide offline versions with a
reasonnable size, this is still too much for many devices. That's why
we need to build offline versions with only a selections with the TOP
best articles.

Principle
---------

This tool builds lists of key values (pageviews, links, ...) about
Wikipedia articles and put them in a directory. These key values are
everything we have as input to build smart selection algorithms. To
get more detalis about the list, read the README in the language based
directory.

Tools
-----

* build_biggest_wikipedia_list.sh give you the list of all
  wikipedia/languages with more than 500.000 entries.

* build_selections.sh takes a language code ('en' for example) as first
  argument and create the directory with all the key values.

* build_all_selections.sh to build/upload lists for all Wikipedia with
  more than 500.000 pages.

* build_en_vital_articles_list.sh generates a the list Wikipedia in
  English vital articles
  (https://en.wikipedia.org/wiki/Wikipedia:Vital_articles)

* build_custom_selections.sh generates selections which need custom
  (non-standard) handling.

* build_projects_lists.pl generates the lists for projects with
  articles sorted (reverse order) by scores. Works only for Wikipedia
  in English.

* build_translated_list.pl translates a list in the given language
  based on Wikipedia in English language links and local language
  scores.

Download
--------

You can download the output of that scripts
directly from https://wp1.download.openzim.org/.

There are redirections to the latest version or each file/folder:
just remove the `_YY-DD` suffix from the path.

VPS
---

To run it on VPS via Docker:

```bash
docker run -d --name wp1_selection_tools
  -v /srv/wp1_selection_tools/data:/data \
  -v /srv/wp1_selection_tools/.ssh/:/root/.ssh \
  -v /srv/wp1_selection_tools/replica.my.cnf:/root/replica.my.cnf \
  ghcr.io/openzim/wp1_selection_tools
```

License
-------

[GPLv3](https://www.gnu.org/licenses/gpl-3.0) or later, see
[LICENSE](LICENSE) for more details.
