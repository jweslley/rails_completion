# Rails completion

Bash completion support for Ruby on Rails.

The completion routines provide support for completing:

* rails commands (e.g.: new, server, console, generate, runner, ...)
* rails generators (e.g.: scaffold, controller, mailer, observer, ...)
* rails environments
* rails field's types on generators (e.g.: scaffold, model, migration, ...)
* common --long-options

## Requirements

  * Rails 3
  * Bash 4
  * bash_completion 1.1+.

Current version of `bash_completion` supports all command-line options available in Rails 3.2.x, if you want to use it with Rails 3.0.y or 3.1.z you should check this version:

    https://github.com/jweslley/rails_completion/tree/v0.1.9

### Brew install of Bash 4 (Mac OSX)
Mac OSX still uses the old version 3.2 of bash, which is not compatible to `rails_completion`.
Install the current version 4 of bash like this:
```bash
brew install bash
sudo bash -c "echo '/usr/local/bin/bash' >> /etc/shells"
chsh -s /usr/local/bin/bash
```

## Installation

### Brew install (OSX)
```bash
brew tap homebrew/completions
brew install rails-completion
```

then add something like this to your ~/.bashrc

```bash
if [ -f `brew --prefix`/etc/bash_completion.d/rails.bash ]; then
    source `brew --prefix`/etc/bash_completion.d/rails.bash
fi
```

### Non-OSX

  1. Copy the `rails.bash` file to somewhere (e.g. ~/.rails.bash).
  2. Add the following line to your `.bashrc`:

        source ~/.rails.bash

Alternatively, on Debian systems, you can just copy the `rails.bash` file to `/etc/bash_completion.d/` directory.

## Basic Usage

Typical usage is to change into a rails application and get some work.

For example, using rails console is something like:

    $ cd rails_app
    $ rails c<Tab><Tab>
    c console
    $ rails c <Tab><Tab>
    --debugger   development  production   -s           --sandbox    test
    $ rails c p<Tab>
    $ rails c production

Choosing the server's environment:

    $ rails server -e<Tab><Tab>
    -edevelopment  -eproduction   -etest
    $ rails server -ep<Tab><Tab>
    $ rails server -eproduction


### Playing with generators

The generators available for completion are not hard-coded. The `rails.bash` script lookup for generators in your Rails application. In this way, generators provided by thrid-party plugins declared in your `Gemfile` also will be available for completion. Moreover, for the sake of performance, the `rails.bash` script saves the list of generators available in a cache file, named `.rails_generators~`. But, if the `Gemfile` file is modified the cache file will be updated on next completion event.

In the following example, I use the 'devise' plugin on `Gemfile`:

    $ rails g <Tab><Tab>
    active_record:devise  generator             model                 resource
    controller            helper                mongoid:devise        scaffold
    devise                integration_test      observer              scaffold_controller
    devise:install        mailer                performance_test      session_migration
    devise:views          migration             plugin                stylesheets

In some generators (scaffold, model, resource and migration), you can declare fields to be generated using the syntax `field:type`. The `rails.bash` script also provides support for field's type completion. For this, just type the field name followed by a colon (`:`) and hit `<Tab><Tab>`:

    $ rails g model Blog title:<Tab><Tab>
    title:binary     title:datetime   title:integer    title:time
    title:boolean    title:decimal    title:string     title:timestamp
    title:date       title:float      title:text
    $ rails g model Blog title:s<Tab>
    $ rails g model Blog title:string
    ...

For more details, use it and have fun!


## Bugs and Feedback

If you discover any bugs or have some idea, feel free to create an issue on GitHub:

<https://github.com/jweslley/rails_completion/issues>


## License

Copyright (c) 2011 [Jonhnny Weslley](<http://www.jonhnnyweslley.net>)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License, version 3, as published by the Free Software Foundation.
