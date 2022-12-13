

# How to github

Open C:/Works/md folder in vs code
git push


# Table of *.md file not rendering within md.htm

* 2022-12-06
* Not sure why markdown table is not rendering in this `md.htm`.
* I think elements should be inside `<zero-md/>` not `<zero-md-clone/>` to render table.

* `Expand` button is best-effort approach. When clicked, there could be all elements visible already. In other words, when all elements are showing, you still see `Expand` button.
* The other way, showing `Expand` button when any hidden `li` exists, was hard, because `li`'s parent `h1/h2` may not be visible, and showing `Expand` button there is not a good solution either.
    
# This project started from:
- https://github.com/zhlicen/md.htm
- https://github.com/zerodevx/zero-md
- https://github.com/markedjs/marked


# Backgournd

- I love documentation with markdown file (light-size, fast, stylish).
- Markdown file `*.md` can be embedded inside `*.html` file
- `zero-md` is one of them. 
- The html file, `md.htm` embeds `xxx.md` file passed by `?src=xxx.md` query string.
- [ref1] https://github.com/zhlicen/md.htm
- [ref2] https://zerodevx.github.io/zero-md/attributes-and-helpers/


# Implementation md.htm
- c:\works\md.htm
- Other files:
- Folder `c:\works\md` has css file.
- md.htm has cdn url `zero-md` library parsing md file into html.
- I added bootstrap etc to make style
- Everything should be inside `window.load` because md file should be loaded into html first to play with jQuery.
- As showdow root doms could not be accessed by jQuery, I do clone the dom elements of shadow root and put it into `<zero-md-clone>`
- Every elements inside `<zero-md-clone>` can now be played with jQuery.

# How to run
- Open `md.htm` in `vs`
- Go live
- ![](./imgs/md-htm/golive.png "go live")
- http://127.0.0.1:5500/md.htm
- ![](./imgs/md-htm/md1.png)
- ![](./imgs/md-htm/md2.png)
