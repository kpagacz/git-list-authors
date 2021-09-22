#!/bin/bash
# Logging
log () {
  echo "LOG: ${1}"
}

TALLY_WITH_FRACTIONS="date_until;author_email;insertions;total_insertions_at_the_time;fractional_insertions\n"
FIRST_COMMIT_DATE=$(git log --reverse --pretty="%cI" | head -1)
FIRST_COMMIT_DATE=$(date --date="${FIRST_COMMIT_DATE}" +%Y-%m)
DATE_ITERATOR=$(date --date="${FIRST_COMMIT_DATE}-01 + 1 month")
DATE_ITERATOR_SECONDS=$(date --date="${DATE_ITERATOR}" +%s)
CURRENT_TIME_SECONDS=$(date +%s)

while [[ $DATE_ITERATOR_SECONDS -le $CURRENT_TIME_SECONDS ]]
do
  AUTHORS=$(git log --pretty="%ae" --until="${DATE_ITERATOR}" | sort | uniq)
  INSERTIONS_TOTAL=0
  TALLY=""
  # Counting each author's insertions
  log "Counting authors' insertions until ${DATE_ITERATOR}"
  while read -r author; do
    TALLY="${TALLY}`date --date="${DATE_ITERATOR}" +%Y-%m-%d`;${author}"
    AUTHOR_INSERTIONS=$(git log --author="${author}" --oneline --shortstat --until="${DATE_ITERATOR}" | grep insertions | cut -d' ' -f 5 | paste -sd+ | bc)
    INSERTIONS_TOTAL=$((INSERTIONS_TOTAL + AUTHOR_INSERTIONS))
    TALLY="${TALLY};${AUTHOR_INSERTIONS}\n"
  done <<< "$AUTHORS"
  log "Total insertions from all authors: ${INSERTIONS_TOTAL}"

  # Counting each author's fraction of total insertions
  log "Counting authors' fractional contribution"
  while read -r line; do
    INSERTIONS=$(echo -e "${line}" | cut -d';' -f3)
    INSERTIONS="${INSERTIONS:=0}"
    INSERTIONS_FRACTION=$(echo "scale=4; $INSERTIONS/$INSERTIONS_TOTAL" | bc)
    TALLY_WITH_FRACTIONS="${TALLY_WITH_FRACTIONS}${line};${INSERTIONS_TOTAL};${INSERTIONS_FRACTION}\n"
  done <<< $(echo -e "$TALLY")

  DATE_ITERATOR=$(date --date="${DATE_ITERATOR} + 1 month")
  DATE_ITERATOR_SECONDS=$(date --date="${DATE_ITERATOR}" +%s)
done

echo -e "${TALLY_WITH_FRACTIONS}"
