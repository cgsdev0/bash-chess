#!/usr/bin/env bash

ILLEGAL=1
LEGAL=0
EN_PASSANT=5
CASTLE_LONG=6
CASTLE_SHORT=8

KING=1
QUEEN=2
ROOK=3
BISHOP=4
KNIGHT=5
PAWN=6

WHITE=1
BLACK=-1

turn=$WHITE
declare -a board
en_passant=-1
next_en_passant=-1
declare -a has_moved

render_piece_text() {
  local piece='.'
  case "$1" in
    -$KING)   piece=k ;;
    -$QUEEN)  piece=q ;;
    -$ROOK)   piece=r ;;
    -$BISHOP) piece=b ;;
    -$KNIGHT) piece=n ;;
    -$PAWN)   piece=p ;;
    $KING)    piece=K ;;
    $QUEEN)   piece=Q ;;
    $ROOK)    piece=R ;;
    $BISHOP)  piece=B ;;
    $KNIGHT)  piece=N ;;
    $PAWN)    piece=P ;;
  esac
  printf "%s" "$piece"
}

render_piece() {
  local piece=' '
  case "$1" in
    -$KING)   piece=♚ ;;
    -$QUEEN)  piece=♛ ;;
    -$ROOK)   piece=♜ ;;
    -$BISHOP) piece=♝ ;;
    -$KNIGHT) piece=♞ ;;
    -$PAWN)   piece=♟ ;;
    $KING)    piece=♔ ;;
    $QUEEN)   piece=♕ ;;
    $ROOK)    piece=♖ ;;
    $BISHOP)  piece=♗ ;;
    $KNIGHT)  piece=♘ ;;
    $PAWN)    piece=♙ ;;
  esac
  printf "%s " "$piece"
}

render() {
  local r c
  echo "     A   B   C   D   E   F   G   H  "
  echo "   ┌───┬───┬───┬───┬───┬───┬───┬───┐"
  for ((r=0; r<8; ++r)); do
    printf " %d " $((8-r))
    for ((c=0; c<8; ++c)); do
      printf "│ "
      render_piece ${board[r*8+c]}
    done
    printf "│ \n"
    if (( r < 7 )); then
      echo "   ├───┼───┼───┼───┼───┼───┼───┼───┤"
    fi
  done
  echo "   └───┴───┴───┴───┴───┴───┴───┴───┘"
  if (( turn == WHITE )); then
    printf "White's Turn\n\n"
  else
    printf "Black's Turn\n\n"
  fi
}

init_board() {
  for ((i=0; i<64; ++i)); do
    board[i]=0
    has_moved[i]=0
  done
  board[0]=-$ROOK
  board[1]=-$KNIGHT
  board[2]=-$BISHOP
  board[3]=-$QUEEN
  board[4]=-$KING
  board[5]=-$BISHOP
  board[6]=-$KNIGHT
  board[7]=-$ROOK
  for ((i=8; i<16; ++i)); do
    board[i]=-$PAWN
  done
  board[56+0]=$ROOK
  board[56+1]=$KNIGHT
  board[56+2]=$BISHOP
  board[56+3]=$QUEEN
  board[56+4]=$KING
  board[56+5]=$BISHOP
  board[56+6]=$KNIGHT
  board[56+7]=$ROOK
  for ((i=56-8; i<56; ++i)); do
    board[i]=$PAWN
  done
}

is_path_clear() {
  local src=$1
  local dest=$2
  local sr=$((src/8))
  local sc=$((src%8))
  local dr=$((dest/8))
  local dc=$((dest%8))
  local dx=$((dc-sc));
  local dy=$((dr-sr));
  local adx=${dx//-}
  local ady=${dy//-}
  if ((dx != 0)); then ((dx/=adx)); fi
  if ((dy != 0)); then ((dy/=ady)); fi
  local c_row=sr;
  local c_col=sc;
  while ((c_row != dr - dy || c_col != dc - dx)); do
    ((c_row+=dy,c_col+=dx))
    if (( board[c_row*8+c_col] != 0 )); then
      return 1
    fi
  done
  return 0
}

is_in_check() {
  local player=$1
  local king_row king_col r c
  for ((r=0; r<8; ++r)); do
    for ((c=0; c<8; ++c)); do
      if ((board[r*8+c] * player == KING)); then
        king_row=$r
        king_col=$c
      fi
    done
  done
  for ((r=0; r<8; ++r)); do
    for ((c=0; c<8; ++c)); do
      if ((board[r*8+c] * player < 0)); then
        if can_do_move $((r * 8 + c)) $((king_row * 8 + king_col)) $((-p)) 0; then
          return 0
        fi
      fi
    done
  done
  return 1
}

no_legal_moves() {
  local player=$1
  local sr sc dr dc temp
  for ((sr=0; sr<8; ++sr)); do
    for ((sc=0; sc<8; ++sc)); do
      if ((board[sr*8+sc] * player > 0)); then
        for ((dr=0; dr<8; ++dr)); do
          for ((dc=0; dc<8; ++dc)); do
            ((dr == sr && dc == sc)) && continue
            if can_do_move $((sr*8+sc)) $((dr*8+dc)) $p 0; then
              temp=${board[dr*8+dc]}
              board[dr*8+dc]=${board[sr*8+sc]}
              board[sr*8+sc]=0

              is_in_check $turn
              check=$?
              board[sr*8+sc]=${board[dr*8+dc]}
              board[dr*8+dc]=$temp
              if [[ $check -ne 0 ]]; then
                return 1
              fi
            fi
          done
        done
      fi
    done
  done
  return 0
}

can_do_move() {
  local src=$1
  local dest=$2
  local turn=$3
  local castle=$4
  local sr=$((src/8))
  local sc=$((src%8))
  local dr=$((dest/8))
  local dc=$((dest%8))
  if (( board[dr*8+dc] * turn > 0 )); then
    err="You can't capture your own piece"
    return $ILLEGAL
  fi
  if (( src == dest )); then
    err="You can't not move"
    return $ILLEGAL
  fi
  local ap=${board[sr*8+sc]//-}
  local dx=$((sc-dc))
  local dy=$((sr-dr))
  local adx=${dx//-}
  local ady=${dy//-}
  case $ap in
    $KNIGHT)
      if (( (adx == 1 && ady == 2) || (adx == 2 && ady == 1) )); then
        return $LEGAL
      else
        err="Horse dont move like that"
        return $ILLEGAL
      fi
      ;;
    $PAWN)
      local to=${board[dr*8+dc]}
      local start=$((turn == BLACK ? 1 : 6))
      if ((adx == 0 && to == 0 && dy == turn)); then
        return $LEGAL
      elif (( adx == 0 && to == 0 && dy == turn * 2 && start == sr)); then
        if (( board[(dr+sr) * 4 + dc] != 0 )); then
          err="noclip is not enabled"
          return $ILLEGAL
        fi
        next_en_passant=$(( (dr+sr)*4+dc ))
        return $LEGAL
      elif (( adx == 1 && to == 0 && dy == turn && en_passant != -1 )); then
        if ((dest != en_passant)); then
          err="bad en passant idk"
          return $ILLEGAL
        fi
        return $EN_PASSANT
      elif (( adx == 1 && dy == turn && to != 0)); then
        return $LEGAL
      else
          err="illegal pawn move"
          return $ILLEGAL
      fi
      ;;
    $QUEEN)
      if ((adx == ady || adx == 0 || ady == 0)); then
        if is_path_clear $src $dest; then
          return $LEGAL
        fi
        err="you can't move through pieces"
        return $ILLEGAL
      fi
      err="queen don't move like that"
      return $ILLEGAL
      ;;
    $ROOK)
      if ((adx == 0 || ady == 0)); then
        if is_path_clear $src $dest; then
          return $LEGAL
        fi
        err="you can't move through pieces"
        return $ILLEGAL
      fi
      err="rook don't move like that"
      return $ILLEGAL
      ;;
    $BISHOP)
      if ((adx == ady)); then
        if is_path_clear $src $dest; then
          return $LEGAL
        fi
        err="you can't move through pieces"
        return $ILLEGAL
      fi
      err="bishop don't move like that"
      return $ILLEGAL
      ;;
    $KING)
      local kstart=$((turn == BLACK ? 4 : 60))
      local rook_row=$((turn == BLACK ? 0 : 7*8))

      if (( adx <= 1 && ady <= 1 )); then
        return $LEGAL
      fi

      if (( castle == 1 && has_moved[king_start] == 0 )); then
        if is_in_check $turn; then
          err="You're in check"
          return $ILLEGAL
        fi
      fi

      if (( dc == 1 )); then
        if (( has_moved[rook_row] )); then
          err="you moved your rook already"
          return $ILLEGAL
        fi
        if (( board[rook_row + 1] )); then
          err="somebody in the way"
          return $ILLEGAL
        fi
        if (( board[rook_row + 2] )); then
          err="somebody in the way"
          return $ILLEGAL
        fi
        if (( board[rook_row + 3] )); then
          err="somebody in the way"
          return $ILLEGAL
        fi
        local result=$CASTLE_LONG
        err="couldn't castle sorry"
        # copy pasta time
        board[rook_row + 4]=0
        board[rook_row + 3]=$((KING * turn))
        if is_in_check $turn; then
          result=$ILLEGAL
        fi
        board[rook_row + 3]=0
        board[rook_row + 2]=$((KING * turn))
        if is_in_check $turn; then
          result=$ILLEGAL
        fi
        board[rook_row + 2]=0
        board[rook_row + 1]=$((KING * turn))
        if is_in_check $turn; then
          result=$ILLEGAL
        fi
        board[rook_row + 1]=0
        board[rook_row + 4]=$((KING * turn))
        return $result
      elif (( dc == 6 )); then
        if (( has_moved[rook_row + 7] )); then
          err="you moved your rook already"
          return $ILLEGAL
        fi
        if (( board[rook_row + 5] )); then
          err="somebody in the way"
          return $ILLEGAL
        fi
        if (( board[rook_row + 6] )); then
          err="somebody in the way"
          return $ILLEGAL
        fi
        local result=$CASTLE_SHORT
        err="couldn't castle sorry"
        board[rook_row + 4]=0
        board[rook_row + 5]=$((KING * turn))
        if is_in_check $turn; then
          result=$ILLEGAL
        fi
        board[rook_row + 5]=0
        board[rook_row + 6]=$((KING * turn))
        if is_in_check $turn; then
          result=$ILLEGAL
        fi
        board[rook_row + 6]=0
        board[rook_row + 4]=$((KING * turn))
        return $result
      fi

      return $ILLEGAL
      ;;
  esac
  return $LEGAL
}

clear() {
  printf '\033[H\033[2J'
}

get_coord() {
  local prompt=$1
  REPLY=""
  while read -p "$prompt"; do
    REPLY=${REPLY,,}
    if [[ "$REPLY" =~ ^[a-h][1-8]$ ]]; then
      local r=${REPLY:1:1}
      local c=${REPLY:0:1}
      printf -vc '%d' "'$c"
      ((r=8-r))
      ((c-=97))
      REPLY=$((r*8+c))
      break
    fi
  done
}


init_board
clear
render

while :; do
  next_en_passant=-1
  get_coord "Which piece? "
  [[ -n "$REPLY" ]] || break
  src=$REPLY

  if ((board[src] == 0)); then
    echo "There's no piece there"
    continue
  fi

  if ((board[src] * turn <= 0)); then
    echo "that is not your piece"
    continue
  fi

  get_coord "Where to? "
  [[ -n "$REPLY" ]] || break
  dest=$REPLY

  can_do_move $src $dest $turn 1
  result=$?

  if ((result == ILLEGAL)); then
    last_err=$err
    echo "$err"
    continue
  else
    last_err=""
  fi

  temp=${board[dest]}
  board[dest]=${board[src]}
  board[src]=0

  if ((result == EN_PASSANT)); then
    board[en_passant + turn * 8]=0
  fi

  rook_row=$(( turn == BLACK ? 0 : 7*8))
  if ((result == CASTLE_LONG)); then
    board[rook_row]=0
    board[rook_row+2]=$((ROOK * turn))
  fi

  if ((result == CASTLE_SHORT)); then
    board[rook_row+7]=0
    board[rook_row+5]=$((ROOK * turn))
  fi

  if is_in_check $turn; then
    # unwind
    board[src]=${board[dest]}
    board[dest]=$temp
    if ((result == EN_PASSANT)); then
      board[en_passant + turn * 8]=$((PAWN * turn * -1))
    fi
    echo "that would leave you in check"
    continue
  fi

  promo_rank=$(( turn == BLACK ? 7 : 0))
  dr=$((dest/8))
  ap=${board[dest]//-}
  if (( ap == PAWN && dr == promo_rank )); then
    board[dest]=$((QUEEN * turn))
  fi

  has_moved[src]=1
  en_passant=$next_en_passant
  ((turn*=-1))
  clear
  render
  if no_legal_moves $turn; then
    if is_in_check $turn; then
      echo "Checkmate!"
    else
      echo "Stalemate!"
    fi
    break
  fi
done

if [[ -n "$BASH_CHESS_TESTING" ]]; then
  echo "$last_err"
  for (( r = 0; r < 8; ++r )); do
    for (( c = 0; c < 8; ++c )); do
      render_piece_text "${board[r*8+c]}"
    done
    echo
  done
fi
