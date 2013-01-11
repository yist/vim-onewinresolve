" Uses marks y, t, o, z
" 
" >>>> ORIGINAL //path/to/original#1  --> mark 'o'
" ...
" ==== THEIRS //path/to/theirs#2      --> mark 't'
" ...
" ==== YOURS //path/to/yours          --> mark 'y'
" ...
" <<<<                                --> mark 'z'
"
function! ResolveFile()
  " Find next merge, if any
  let s:found = search("^==== YOURS ", "w")
  if (s:found == 0)
    return 0
  endif
  execute "mark y"

  if (search("^==== THEIRS", "bW") == 0)
    echo "Failed to find <<<< THEIRS line."
    return 0
  endif
  execute "mark t"

  if (search("^>>>> ORIGINAL ", "bW") == 0)
    echo "Failed to find >>>> ORINGINAL line."
    return 0
  endif
  execute "mark o"

  if (search("^<<<<$", "W") == 0)
    echo "Failed to find <<<< line."
    return 0
  endif
  execute "mark z"


  " Go to >>>> line
  execute "normal g'o"
  " Center vertically
  execute "normal zz"

  redraw
  echo "Accept y)ours, t)heirs, b)oth; e)dit, u)ndo, q)uit: "
  let s:c = nr2char(getchar())
  if s:c == "y"
    " Delete theirs and original, show what's left for a bit
    execute "'o,'t-1d"
    execute "'t,'y-1d"
    redraw
    echo "Yours"
    execute "sleep 500m"

    execute "'yd"
    execute "'zd"
    redraw
    return 1
  elseif s:c == "t"
    " Delete yours and original, show what's left for a bit
    execute "'o,'t-1d"
    execute "'y,'z-1d"
    redraw
    echo "Theirs"
    execute "sleep 500m"

    execute "'td"
    execute "'zd"
    redraw
    return 2
  elseif s:c == "b"
    execute "'o,'td"
    execute "'yd"
    execute "'zd"
    redraw
    echo "Both"
    return 3
  elseif s:c == "n"
    echo "Next"
    execute "sleep 500m"
    return 4
  elseif s:c == "u"
    execute "normal u"
    echo "Undo"
    execute "sleep 500m"
    return 5
  elseif s:c == "e"
    echo "Edit, :ResolveAll to continue"
    execute "sleep 500m"
    return -1
  elseif s:c == "q"
    redraw
    echo "Quit"
    return -2
  else
    redraw
    echo "Unknown command"
    execute "sleep 500m"
    return 1000
  endif
endfunction

" Make it easier/safer to do a diff3 merge on files.
function! ResolveAll()
  let s:continue = 1
  while s:continue == 1
    " Remove normal syntax highlighting our our highlighting won't work.
    execute "syntax clear"

    " Highlight colors
    execute "highlight DiffYours ctermbg=Green guibg=#77ff77"
    execute "highlight DiffTheirs ctermbg=Red guibg=#ff7777"
    execute "highlight DiffOriginal ctermbg=Blue guibg=#7777ff"

    execute "syntax region DiffRegion start=/^>>>> ORIGINAL .*/ end=/^<<<<$/ contains=DiffOriginal,DiffTheirs,DiffYours keepend"
    execute "syntax region DiffOriginal start=/^>>>> ORIGINAL .*/hs=e+1 end=/^==== THEIRS .*$/he=s-1,me=s-1 contained"
    execute "syntax region DiffYours start=/^==== YOURS .*/hs=e+1 end=/^<<<<$/he=s-1,me=s-1 contained"
    execute "syntax region DiffTheirs start=/^==== THEIRS .*/hs=e+1,ms=e+1 end=/^==== YOURS .*/he=s-1,me=s-1 contained"

    let s:ok = 1
    let s:count = 0

    while s:ok > 0
      let s:ok = ResolveFile()
      let s:count = s:count + 1
    endwhile

    let s:continue = 0

    " If we we reached the end of a file
    " And user didn't hit quit...
    if (s:ok == 0 && s:count > 0)
      echo "Last one in this file w) :wq, q)uit merging: "
      let s:c = nr2char(getchar())
      if s:c == "w"
        " Write quit, maybe next buffer has more
        execute "wq"
        let s:continue = 1
      endif
    endif
  endwhile
  if s:ok != -1
    " Leave the syntax if they said 'E)dit'
    syntax clear
    syntax on
  endif
endfunction

command! ResolveAll call ResolveAll()

