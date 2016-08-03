# Rbdux

A simple library to enable one-way data flow from a single source of truth... in Ruby.

### Terminal 1

    git clone git@github.com:jtompkins/rbdux.git
    ruby rbdux/examples/todo/todo.rb

### Terminal 2

    vi rbdux/examples/todos.rb

#### Notice the available functions in todos.rb:

    add
    toggle
    visible
    exit

If you do not choose an above option and you type something in, it will default to add.
Alternatively add explicitly like this (no parentheses, no quotes needed, example follows):

    add my todo

### Contribute in this way
#### Fork the repo (in browser at github repo page) and set an additional remote

    cd rbdux
    git remote add og git@github.com:jtompkins/rbdux.git
    git config --list

#### You should now see the new remote

    remote.og.url=git@github.com:jtompkins/rbdux.git

#### Create a new feature branch

    git checkout -b new_feature_branch_name_of_choice

#### Add something of value (change code, add documentation, etc.)
    
    git add .

#### Compare your repo changes

    git status
    git diff

#### Once satisfied commit and push your branch locally

    git commit -am "proposed feature, improvement, or suggestion description here"
    git push 

#### Then checkout master & merge the branch into master

    git checkout master
    git merge new_feature_branch_name_of_choice

#### Pull down most recient changes

    git pull og master
