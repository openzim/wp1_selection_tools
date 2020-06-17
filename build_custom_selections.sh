#!/usr/bin/env bash

# Stop if any problem
set -e
set -o pipefail

# Paths
SCRIPT_PATH=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH | sed -e 's/\/$//')
export PATH=$PATH:$SCRIPT_DIR
DATA=$SCRIPT_DIR/data
TMP=$DATA/tmp
LIST_CATEGORY_SCRIPT_PATH=$SCRIPT_DIR/mediawiki/scripts/listCategoryEntries.pl
LIST_LANG_LINKS_PATH=$SCRIPT_DIR/mediawiki/scripts/listLangLinks.pl
TRANSLATE_LIST_SCRIPT_PATH=$SCRIPT_DIR/build_translated_list.pl
COMPARE_LISTS_SCRIPT_PATH=$SCRIPT_DIR/compare_lists.pl

# Perl and sort(1) have locale issues, which can be avoided by
# disabling locale handling entirely.
PERL=$(whereis perl | cut -f2 -d " ")
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

# Translate custom selections from English
if [ $WIKI_LANG != "en" ]
then
    for FILE in $(find $DATA/en.needed/customs/ -type f)
    do
        $PERL $TRANSLATE_LIST_SCRIPT_PATH "$FILE" $WIKI_LANG "$CUSTOM_DIR/../scores.tsv" > $CUSTOM_DIR/$(basename $FILE)
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
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikivoyage.org --path=w --exploration=8 --namespace=0 --category="Europe" | sort -u > "$CUSTOM_DIR/wikivoyage/europe.tsv"

    # WikiMed
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Women's_health_articles" \
          --category="WikiProject_Microbiology_articles" --category="WikiProject_Physiology_articles" --category="WikiProject_Medicine_articles" \
          --category="WikiProject_Dentistry_articles" --category="WikiProject_Anatomy_articles" --category="WikiProject_Pharmacology_articles" \
          --category="WikiProject_Sanitation_articles" | sed 's/Talk://' | sort -u > "$TMP/medicine_unfiltered.tsv"
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Hospitals_articles" \
          --category="WikiProject_History_of_Science_articles" --category="WikiProject_Academic_Journal_articles" \
          --category="WikiProject_Visual_arts_articles" --category="WikiProject_Biography_articles" \
          --category="WikiProject_Companies_articles" | sed 's/Talk://' | sort -u > "$TMP/medicine_filter.tsv"
    grep -Fxv -f "$TMP/medicine_filter.tsv" "$TMP/medicine_unfiltered.tsv" | sort -u > "$CUSTOM_DIR/medicine.tsv"
    echo "Wikipedia:WikiProject_Medicine/Open_Textbook_of_Medicine" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Cardiology" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Children's health" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Dermatology" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Ears_nose_throat" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Endocrinology" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Eye_diseases" >>  "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Gastroenterology" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:General_surgery" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Infectious_disease" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Medications" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Mental health" >>  "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Neurology" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Ortho" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Orthopedics" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Cancer" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Ophthalmology" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Pediatrics" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Psychiatry" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Rheumatology" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Skin diseases" >> "$CUSTOM_DIR/medicine.tsv"
    echo "Book:Women's_health" >> "$CUSTOM_DIR/medicine.tsv"
    $LIST_LANG_LINKS_PATH --host=en.wikipedia.org --path=w --readFromStdin --language=ja --language=as --language=bn --language=gu --language=hi \
                          --language=kn --language=ml --language=de --language=bpy --language=mr --language=lo --language=or --language=pa \
                          --language=ta --language=te --language=ur --language=fa --language=fr --language=zh --language=pt --language=ar \
                          --language=es --language=it < "$CUSTOM_DIR/medicine.tsv" > "$DATA/en.needed/medicine.langlinks.tsv"

    # Ray Charles
    $PERL $LIST_CATEGORY_SCRIPT_PATH --path=w --host=en.wikipedia.org --category="Ray_Charles" --namespace=0 --explorationDepth=3 | sort -u > "$CUSTOM_DIR/ray_charles.tsv"

    # Movies
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="Actors_and_filmmakers_work_group_articles" \
          --category="WikiProject_Film_articles" | sed 's/Talk://' | sort -u > "$CUSTOM_DIR/movies.tsv"

    # Download list of articles to excludes from selections
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Biography_articles" \
          --category="WikiProject_Companies_articles" | sed 's/Talk://' | sort -u > "$TMP/filter_out.tsv"

    # Physics
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Physics_articles" | \
        sed 's/Talk://' | sort -u > "$TMP/physics_unfiltered.tsv"
    grep -Fxv -f "$TMP/filter_out.tsv" "$TMP/physics_unfiltered.tsv" | sort -u > "$CUSTOM_DIR/physics.tsv"

    # Molecular & Cell Biology
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Molecular_and_Cellular_Biology_articles" | \
        sed 's/Talk://' | sort -u > "$TMP/molcell_unfiltered.tsv"
    grep -Fxv -f "$TMP/filter_out.tsv" "$TMP/molcell_unfiltered.tsv" | sort -u > "$CUSTOM_DIR/molcell.tsv"

    # Maths
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Mathematics_articles" | \
        sed 's/Talk://' | sort -u > "$TMP/maths_unfiltered.tsv"
    grep -Fxv -f "$TMP/filter_out.tsv" "$TMP/maths_unfiltered.tsv" | sort -u > "$CUSTOM_DIR/maths.tsv"

    # Chemistry
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --exploration=5 --namespace=1 --category="WikiProject_Chemistry_articles" | \
        sed 's/Talk://' | sort -u > "$TMP/chemistry_unfiltered.tsv"
    grep -Fxv -f "$TMP/filter_out.tsv" "$TMP/chemistry_unfiltered.tsv" | sort -u > "$CUSTOM_DIR/chemistry.tsv"

# French
elif [ "$WIKI_LANG" == "fr" ]
then

    # Tunisie
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=fr.wikipedia.org --path=w --exploration=5 --namespace=1 --category="Évaluation_des_articles_du_projet_Tunisie" | \
        sed 's/Discussion://' | sort -u > "$CUSTOM_DIR/tunisie.tsv"
    echo "Portail:Tunisie/Index thématique" >> "$CUSTOM_DIR/tunisie.tsv"

    # Medicine
    $PERL $TRANSLATE_LIST_SCRIPT_PATH $DATA/en.needed/customs/medicine.tsv $WIKI_LANG "$CUSTOM_DIR/../scores.tsv" > "$TMP/medicine.tsv"
    $PERL $LIST_CATEGORY_SCRIPT_PATH --host=fr.wikipedia.org --category="Évaluation_des_articles_du_projet_Soins_infirmiers_et_profession_infirmière" \
          --category="Évaluation_des_articles_du_projet_Premiers_secours_et_secourisme" --category="Évaluation_des_articles_du_projet_Médecine" \
          --category="Évaluation_des_articles_du_projet_Anatomie" --category="Évaluation_des_articles_du_projet_Pharmacie" --path=w --exploration=5 --namespace=1 | \
        sed 's/Discussion://' | sort -u > "$TMP/medicine_fr.tsv"
    cat "$TMP/medicine_fr.tsv" "$TMP/medicine.tsv" | sort -u > "$CUSTOM_DIR/medicine.tsv"
fi

# Endless
if [ -f "customs/endless/$WIKI_LANG/base_selection" ]
then
    echo "Building Endless selection..."
    BASELIST_PATH="$CUSTOM_DIR/../"`cat customs/endless/$WIKI_LANG/base_selection`
    if [ -f "$BASELIST_PATH" ]
    then
        WHITELIST_PATH="customs/endless/$WIKI_LANG/whitelist.tsv"
        BLACKLIST_PATH="customs/endless/$WIKI_LANG/blacklist.tsv"

        if [ -f "BLACKLIST_PATH" ]
        then
            cat "$BASELIST_PATH" "$WHITELIST_PATH" | awk '!seen[$0]++' > "$TMP/endless.tsv" 2> /dev/null
            $PERL $COMPARE_LISTS_SCRIPT_PATH --file1="$TMP/endless.tsv" --file2="$LACKLIST_PATH" --mode=only1 > "$CUSTOM_DIR/endless.tsv"
        else
            cat "$BASELIST_PATH" "$WHITELIST_PATH" | awk '!seen[$0]++' > "$CUSTOM_DIR/endless.tsv" 2> /dev/null
        fi
    fi
fi
