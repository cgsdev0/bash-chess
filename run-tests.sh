#!/usr/bin/env bash

for testcase in tests/*.input; do
  expected=${testcase//.input/.output}
  if [[ -f "$expected" ]]; then
    diff <(BASH_CHESS_TESTING=1 ./chess.sh < <(tr ' ' '\n' < "$testcase") | tail -n9) "$expected"
    if (( $? == 0 )); then
      printf '\033[32m'
      echo "PASSED ${testcase%.input}"
      printf '\033[0m'
      ((passed++))
    else
      printf '\033[31m'
      echo "'FAILED ${testcase%.input}"
      printf '\033[0m'
    fi
    ((total++))
  else
    BASH_CHESS_TESTING=1 ./chess.sh < <(tr ' ' '\n' < "$testcase") | tail -n9 | tee "$expected"

    printf '\033[33m'
    echo "WRITTEN ${testcase%.input}"
    printf '\033[0m'
    ((written++))
  fi
done

if (( total > 0 )); then
  echo
  echo "${passed:-0} / ${total:-0} test(s) passed."
fi
if (( written > 0 )); then
  echo
  echo "$written new test(s) written."
fi
