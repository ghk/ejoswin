function! s:exec(cmd)
    let old_ei = &ei
    set ei=all
    exec a:cmd
    let &ei = old_ei
endfunction

function! s:getWinNum(name)
    if a:name == "tree" 
        let treename = g:EjosGetTreeName()
        if treename == -1
            return -1
        endif
        return bufwinnr(treename)
    elseif a:name == "tag"
        return bufwinnr('__Tagbar__')
    elseif a:name == "master"
        if s:stacked && s:isWinOpen("tag")
            return s:isWinOpen("tree") ? 3 : 2
        else 
            return s:isWinOpen("tree") ? 2 : 1
        endif
    elseif a:name == "firstslave"
        if s:isWinOpen("tag")
            return s:isWinOpen("tree") ? 4 : 3
        else 
            return s:isWinOpen("tree") ? 3 : 2
        endif
    endif
    return -1
endfunction

function! s:putCursorInWin(name)
    call s:exec(s:getWinNum(a:name) . "wincmd w")
endfunction

function! s:isWinOpen(name)
    return s:getWinNum(a:name) != -1
endfunction

function! s:hasSlave()
    let totalWin = winnr("$")
    if s:getWinNum("tree") != -1
        let totalWin = totalWin - 1
    endif
    if s:getWinNum("tag") != -1
        let totalWin = totalWin - 1
    endif
    return totalWin != 1
endfunction

function! s:setSize(treeSize, masterSize, tagSize, slaveSize)
    if s:isWinOpen("tree") 
        call s:putCursorInWin("tree")
        exec("silent vertical resize ". a:treeSize)
    endif

    call s:putCursorInWin("master")
    exec("silent vertical resize ". a:masterSize)

    if s:isWinOpen("tag") 
        call s:putCursorInWin("tag")
        exec("silent vertical resize ". a:tagSize)
    endif

    if s:hasSlave() 
        call s:exec("wincmd b")
        exec("silent vertical resize ". a:slaveSize)
    endif
    
    if s:isWinOpen("tree") 
        call s:putCursorInWin("tree")
        exec("silent vertical resize ". a:treeSize)
    endif
endfunction

" when stacked:
" tag
" tree
" windows (first is master)
let s:stacked = 0

function! s:stackAll()
    "stack up master win
    call s:putCursorInWin("master")
    call s:exec('wincmd K')

    "stack up tree win
    if s:isWinOpen("tree")
        call s:putCursorInWin("tree")
        call s:exec('wincmd K')
    endif

    if s:isWinOpen("tag")
        "stack up tag win
        call s:putCursorInWin("tag")
        call s:exec('wincmd K')
    endif

    let s:stacked = 1

endfunction

function! s:restoreAll()
    "restore tag
    if s:isWinOpen("tag")
        call s:putCursorInWin("tag")
        call s:exec('wincmd H')
    endif

    "restore master
    call s:putCursorInWin("master")
    call s:exec('wincmd H')

    "restore tree
    if s:isWinOpen("tree")
        call s:putCursorInWin("tree")
        call s:exec('wincmd H')
    endif

    let s:stacked = 0
endfunction

function! s:openMaster(path)
    let winnr = bufwinnr('^' . a:path . '$')
    if winnr != -1
        call s:exec(winnr . "wincmd w")
        call g:EjosSetMaster()
        return
    endif

    if s:isWinOpen("tree")
        call s:putCursorInWin("tree")
        let curLine = line(".")
        let curCol = col(".")
        let topLine = line("w0")
        call s:exec(winnr . "wincmd w")
    endif

    call s:stackAll()

    call s:putCursorInWin("master")
    exec "above new " . a:path

    call s:restoreAll()

    if s:isWinOpen("tree")
        call s:putCursorInWin("tree")
        let old_scrolloff=&scrolloff
        let &scrolloff=0
        call cursor(topLine, 1)
        normal! zt
        call cursor(curLine, curCol)
        let &scrolloff = old_scrolloff
    endif

    call s:putCursorInWin("master")
    call g:EjosResize()
endfunction

function! s:openSlave(path)
    let winnr = bufwinnr('^' . a:path . '$')
    if winnr != -1
        return
    endif

    if s:isWinOpen("tree")
        call s:putCursorInWin("tree")
        let curLine = line(".")
        let curCol = col(".")
        let topLine = line("w0")
        call s:exec(winnr . "wincmd w")
    endif

    call s:stackAll()

    "go to top of the most top slave. i.e tag win or master win
    call s:putCursorInWin("master")
    exec "below new " . a:path

    call s:restoreAll()

    if s:isWinOpen("tree")
        call s:putCursorInWin("tree")
        let old_scrolloff=&scrolloff
        let &scrolloff=0
        call cursor(topLine, 1)
        normal! zt
        call cursor(curLine, curCol)
        let &scrolloff = old_scrolloff
    endif

    call g:EjosResize()
endfunction

function! g:EjosOpenMaster(path)
    return s:openMaster(a:path) 
endfunction

function! g:EjosOpenSlave(path)
    return s:openSlave(a:path) 
endfunction


function! g:EjosSetMaster()
    " check if current is not a slave
    let nr = winnr()
    if nr==s:getWinNum("master") || nr==s:getWinNum("tag") || nr == s:getWinNum("tree")
        return
    endif

    call s:putCursorInWin("master")
    call s:exec('wincmd K')

    call s:exec('wincmd p')
    call s:exec('wincmd K')
    
    if s:isWinOpen("tree")
        call s:putCursorInWin("tree")

        let curLine = line(".")
        let curCol = col(".")
        let topLine = line("w0")

        call s:exec('wincmd K')
        call s:exec("wincmd p")
    endif

    if s:isWinOpen("tag")
        call s:putCursorInWin("tag")
        call s:exec('wincmd K')
        call s:exec('wincmd H')
        call s:exec("wincmd p")
    endif

    call s:exec('wincmd H')

    if s:isWinOpen("tree")
        call s:putCursorInWin("tree")
        call s:exec('wincmd H')

        let old_scrolloff=&scrolloff
        let &scrolloff=0
        call cursor(topLine, 1)
        normal! zt
        call cursor(curLine, curCol)
        let &scrolloff = old_scrolloff

        call s:exec('wincmd p')
    endif

    call g:EjosResize()
endfunction

function! g:EjosToggleTagbar() 
    let master_nr = s:getWinNum("master")
    let nr = winnr()
    let inMaster = nr==#master_nr

    if s:hasSlave()
        call s:putCursorInWin("master")

        call tagbar#ToggleWindow()

        if !inMaster
            if !s:isWinOpen("tree") ||  nr != 1
                if nr > master_nr
                   "must be a slave
                   if  s:isWinOpen("tag")
                       call s:exec((nr+1) . "wincmd w")
                   else
                       call s:exec((nr-1) . "wincmd w")
                   endif
                endif
            else
                "previous in tree
                    call s:exec(1 . "wincmd w")
            endif
        endif

    else
        if !inMaster
            call s:putCursorInWin("master")
        endif
        call tagbar#ToggleWindow()
        if !inMaster
            call s:exec(1 . "wincmd w")
        endif
    endif
    call g:EjosResize()
endfunction


function! g:EjosResize()
    let nr = winnr()
    let remaining = &columns
    let twoColThres = 82
    if s:isWinOpen("tag") 
        let twoColThres = twoColThres + 30
    endif
    if s:isWinOpen("tree") 
        let twoColThres = twoColThres + 30
    endif
    if s:hasSlave()
        let twoColThres = twoColThres + 30
    endif

    if remaining < 82
        "one column windows
        exec("silent vertical resize ". remaining)
    elseif remaining < twoColThres
        "master 82 and another column 30
        call s:setSize(0, 0, 0, 0)

        let treeSize = 0
        let tagSize = 0
        let masterSize = 0
        let slaveSize = 0

        if s:isWinOpen("tag")
            if nr != s:getWinNum("tree")
                let remaining = remaining - 30
                let tagSize = 30
            else
                let tagSize = remaining - 82 - 30
                if tagSize < 0
                    let tagSize = 0
                endif
                let remaining = remaining - tagSize
            endif
        endif
        if s:isWinOpen("tree") 
            if remaining >= 112 || nr == s:getWinNum("tree")
                let treeSize = 30
                let remaining = remaining - 30
            endif
        endif
        if s:hasSlave() 
            let mainSize = remaining
            if remaining > 82
                let mainSize = 82
            endif
            if nr != s:getWinNum("tag") && nr > s:getWinNum("master")
                let masterSize = remaining - mainSize
                let slaveSize = mainSize
            else
                let slaveSize = remaining - mainSize
                let masterSize = mainSize
            endif
        else
            let masterSize = remaining
        endif

        call s:setSize(treeSize, masterSize, tagSize, slaveSize)

    else
        if s:isWinOpen("tree")
            call s:putCursorInWin("tree")
            exec("silent vertical resize ". 30)
            let remaining = remaining - 30
        endif
        if s:isWinOpen("tag")
            call s:putCursorInWin("tag")
            exec("silent vertical resize ". 30)
            let remaining = remaining - 30
        endif
        if s:hasSlave()
            let slaveWidth = 82
            if remaining < 164
                let slaveWidth = remaining - 82
            endif
            call s:exec("wincmd b")
            exec("silent vertical resize ". slaveWidth)
        endif
    endif
    call s:exec(nr . "wincmd w")
endfunction

function! g:EjosSetFirstSlave()
    let nr = winnr()
    if nr==s:getWinNum("tag") || nr == s:getWinNum("tree")
        return
    endif
    if nr==s:getWinNum("master") 
        if s:hasSlave() 
            call s:putCursorInWin("firstslave")
            call g:EjosSetMaster()
            call s:putCursorInWin("firstslave")
        endif
    else
        let fnr = s:getWinNum("firstslave") 
        while nr > fnr 
            call s:exec("wincmd k")
            call s:exec("wincmd x")
            let nr = winnr()
        endwhile
    endif
endfunction


function! s:postMasterLeave()
    call s:putCursorInWin("master")
    augroup ejospostmaster
        autocmd!
    augroup end 
    autocmd! ejospostmaster BufEnter
endfunction

function! g:EjosPrepareMasterLeave()
    let nr = winnr()
    if nr==s:getWinNum("master") && s:hasSlave()
        call g:EjosSetFirstSlave()
        augroup ejospostmaster
            autocmd!
            autocmd BufEnter * call s:postMasterLeave()
        augroup end 
    endif
endfunction

function! g:EjosWinMove(dir)
    call s:exec("wincmd ".a:dir)
    call g:EjosResize()
endfunction

