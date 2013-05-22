#!/bin/bash
#

PurgedPackage="$1"
PurgedPackageLocation="$2"
CpaMiddleFileLocation=".cpa/$PurgedPackage"

mkdir -p "$CpaMiddleFileLocation"
rm -rf "$CpaMiddleFileLocation/*"

PURGED_SELF_CLASSES_FILE="$CpaMiddleFileLocation/inner.classes"
PURGED_SELF_SORTED_CLASS_NAME_FILE="$CpaMiddleFileLocation/inner.classes.name.sorted"
VALID_FILES_FILE="$CpaMiddleFileLocation/valid.files"
REFERERS_FILE="$CpaMiddleFileLocation/referers"
REFEREES_FILE="$CpaMiddleFileLocation/referees"

find "$PurgedPackageLocation" -type f -name "*.java" 2>&1 | tee $PURGED_SELF_CLASSES_FILE

grep -o -P '\w+(?=\.java)' $PURGED_SELF_CLASSES_FILE | sort -u 2>&1 | tee $PURGED_SELF_SORTED_CLASS_NAME_FILE

find -L -type f -regextype posix-extended -iregex '.*\.(java|jsp)' 2>&1 | tee $VALID_FILES_FILE

cat $VALID_FILES_FILE | xargs -I {} grep -H "import $PurgedPackage\." "{}" 2>&1 | tee $REFERERS_FILE

gawk -F: '{print $2}' $REFERERS_FILE | grep -o -P '(?<=\.)\w+(?=;)' | sort -u 2>&1 | tee $REFEREES_FILE
