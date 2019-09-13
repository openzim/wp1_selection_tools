#!/usr/bin/env bash

# Stop if any problem
set -e
set -o pipefail

# Paths
SCRIPT_PATH=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_PATH | sed -e 's/\/$//'`
export PATH=$PATH:$SCRIPT_DIR
TMP=$SCRIPT_DIR/data
LIST_CATEGORY_SCRIPT_PATH=$SCRIPT_DIR/mediawiki/scripts/listCategoryEntries.pl
TRANSLATE_LIST_SCRIPT_PATH=$SCRIPT_DIR/build_translated_list.pl
COMPARE_LISTS_SCRIPT_PATH=$SCRIPT_DIR/compare_lists.pl

# Perl and sort(1) have locale issues, which can be avoided by
# disabling locale handling entirely.
PERL=`whereis perl | cut -f2 -d " "`
LANG=C
export LANG

# Parse command line
WIKI_LANG=$1
CUSTOM_DIR=$2
if [ -z "$WIKI_LANG" ]
then
    echo "You have to specify a language code (like 'en' for example)"
    exit 1
fi
if [ ! -d "$CUSTOM_DIR" ]
then
    echo "You have to specify a directory where the 'custom' selections can be written."
    exit 1
fi

# Prepare langlinks.tmp
if [ $WIKI_LANG != 'en' ]
then
   grep -P "\t$WIKI_LANG\t" $TMP/en.needed/langlinks > $TMP/en.needed/langlinks.tmp
fi

# Translate custom selections in English
if [ $WIKI_LANG != "en" ]
then
    for FILE in `find tmp/en.customs/ -type f`
    do
        $PERL $TRANSLATE_LIST_SCRIPT_PATH "$FILE" $WIKI_LANG > $CUSTOM_DIR/`basename $FILE`
    done
fi

# Copy hardcoded selections
if [ -d customs/$WIKI_LANG/ ]
then
    cp customs/$WIKI_LANG/* "$CUSTOM_DIR"
fi

# English
if [ $WIKI_LANG == "en" ]
then

    # Wikivoyage Europe
    if [ ! -d "$CUSTOM_DIR/wikivoyage" ]; then mkdir "$CUSTOM_DIR/wikivoyage" &> /dev/null; fi
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikivoyage.org --path=w --exploration=8 --namespace=0 --category="Europe" | sort -u > "$CUSTOM_DIR/wikivoyage/europe"

    # WikiMed
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Women's_health_articles" \
          --category="WikiProject_Microbiology_articles" --category="WikiProject_Physiology_articles" --category="WikiProject_Medicine_articles" \
          --category="WikiProject_Dentistry_articles" --category="WikiProject_Anatomy_articles" --category="WikiProject_Pharmacology_articles" \
          --category="WikiProject_Sanitation_articles" | sed 's/Talk://' | sort -u > "/tmp/medicine_unfiltered"
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Hospitals_articles" \
          --category="WikiProject_History_of_Science_articles" --category="WikiProject_Academic_Journal_articles" \
          --category="WikiProject_Visual_arts_articles" --category="WikiProject_Biography_articles" \
          --category="WikiProject_Companies_articles" | sed 's/Talk://' | sort -u > "/tmp/medicine_filter"
    grep -Fxv -f "/tmp/medicine_filter" "/tmp/medicine_unfiltered" | sort -u > "$CUSTOM_DIR/medicine"
    echo "Wikipedia:WikiProject_Medicine/Open_Textbook_of_Medicine" >> "$CUSTOM_DIR/medicine"
    echo "Book:Cardiology" >> "$CUSTOM_DIR/medicine"
    echo "Book:Children's health" >> "$CUSTOM_DIR/medicine"
    echo "Book:Dermatology" >> "$CUSTOM_DIR/medicine"
    echo "Book:Ears_nose_throat" >> "$CUSTOM_DIR/medicine"
    echo "Book:Endocrinology" >> "$CUSTOM_DIR/medicine"
    echo "Book:Eye_diseases" >>  "$CUSTOM_DIR/medicine"
    echo "Book:Gastroenterology" >> "$CUSTOM_DIR/medicine"
    echo "Book:General_surgery" >> "$CUSTOM_DIR/medicine"
    echo "Book:Infectious_disease" >> "$CUSTOM_DIR/medicine"
    echo "Book:Medications" >> "$CUSTOM_DIR/medicine"
    echo "Book:Mental health" >>  "$CUSTOM_DIR/medicine"
    echo "Book:Neurology" >> "$CUSTOM_DIR/medicine"
    echo "Book:Ortho" >> "$CUSTOM_DIR/medicine"
    echo "Book:Orthopedics" >> "$CUSTOM_DIR/medicine"
    echo "Book:Cancer" >> "$CUSTOM_DIR/medicine"
    echo "Book:Ophthalmology" >> "$CUSTOM_DIR/medicine"
    echo "Book:Pediatrics" >> "$CUSTOM_DIR/medicine"
    echo "Book:Psychiatry" >> "$CUSTOM_DIR/medicine"
    echo "Book:Rheumatology" >> "$CUSTOM_DIR/medicine"
    echo "Book:Skin diseases" >> "$CUSTOM_DIR/medicine"
    echo "Book:Women's_health" >> "$CUSTOM_DIR/medicine"

    # Ray Charles
    $PERL $LIST_CATEGORY_SCRIPT_PATH --path=w --host=en.wikipedia.org --category="Ray_Charles" --namespace=0 --explorationDepth=3 | sort -u > "$CUSTOM_DIR/ray_charles"

    # Movies
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="Actors_and_filmmakers_work_group_articles" \
          --category="WikiProject_Film_articles" | sed 's/Talk://' | sort -u > "$CUSTOM_DIR/movies"

    # Download list of articles to excludes from selections
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Biography_articles" \
          --category="WikiProject_Companies_articles" | sed 's/Talk://' | sort -u > "/tmp/filter_out"

    # Physics
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Physics_articles" | \
        sed 's/Talk://' | sort -u > "/tmp/physics_unfiltered"
    grep -Fxv -f "/tmp/filter_out" "/tmp/physics_unfiltered" | sort -u > "$CUSTOM_DIR/physics"

    # Molecular & Cell Biology
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Molecular_and_Cellular_Biology_articles" | \
        sed 's/Talk://' | sort -u > "/tmp/molcell_unfiltered"
    grep -Fxv -f "/tmp/filter_out" "/tmp/molcell_unfiltered" | sort -u > "$CUSTOM_DIR/molcell"

    # Maths
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Mathematics_articles" | \
        sed 's/Talk://' | sort -u > "/tmp/maths_unfiltered"
    grep -Fxv -f "/tmp/filter_out" "/tmp/maths_unfiltered" | sort -u > "$CUSTOM_DIR/maths"

    # Chemistry
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Chemistry_articles" | \
        sed 's/Talk://' | sort -u > "/tmp/chemistry_unfiltered"
    grep -Fxv -f "/tmp/filter_out" "/tmp/chemistry_unfiltered" | sort -u > "$CUSTOM_DIR/chemistry"

# French
elif [ "$WIKI_LANG" == "fr" ]
then

    # Tunisie
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=fr.wikipedia.org --path=w --exploration=5 --namespace=1 --category="Évaluation_des_articles_du_projet_Tunisie" | \
        sed 's/Discussion://' | sort -u > "$CUSTOM_DIR/tunisie"
    echo "Portail:Tunisie/Index thématique" >> "$CUSTOM_DIR/tunisie"

    # Medicine
    $PERL $TRANSLATE_LIST_SCRIPT_PATH $TMP/en.customs/medicine $WIKI_LANG > "/tmp/medicine"
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=fr.wikipedia.org --category="Évaluation_des_articles_du_projet_Soins_infirmiers_et_profession_infirmière" \
          --category="Évaluation_des_articles_du_projet_Premiers_secours_et_secourisme" --category="Évaluation_des_articles_du_projet_Médecine" \
          --category="Évaluation_des_articles_du_projet_Anatomie" --category="Évaluation_des_articles_du_projet_Pharmacie" --path=w --exploration=5 --namespace=1 | \
        sed 's/Discussion://' | sort -u > "/tmp/medicine_fr"
    cat "/tmp/medicine_fr" "tmp/medicine" | sort -u > "$CUSTOM_DIR/medicine"
fi

# Clean
rm -f $TMP/en.needed/langlinks.tmp
