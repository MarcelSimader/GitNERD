<!-- Author: Marcel Simader (marcel0simader@gmail.com) -->
<!-- Date: 21.11.2022 -->
<!-- (c) Marcel Simader 2022 -->

# GitNERD

GitNERD is a Vim [NERDTree](https://github.com/preservim/nerdtree) extension which shows a
Git status indicator next to each file/directory node in the NERDTree, if a Git repository
is found to contain the current working directory.

This project was made as submission for Exercise 01 of the [Missing
Semester](http://teaching.pages.sai.jku.at/missing-semester/) course at Johannes Kepler
University Linz.

## Usage

There is really no interactivity in this extension, but you can reload the tree using 'R'
when the cursor is placed in the NERDTree window.

## Installation

Simply use your preferred plugin manager for Vim. Here, we show how to install the plugin
using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
call plug#begin()

Plug 'preservim/nerdtree'
Plug 'TODO'

call plug#end()
```

This installs both NERDTree and GitNERD.

## License

Distributed under the Vim license. See `LICENSE`.

