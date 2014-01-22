# Bash completion support for Ruby on Rails.
#
#  Copyright (C) 2011 Jonhnny Weslley <http://www.jonhnnyweslley.net>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  The latest version of this software can be obtained here:
#
#  http://github.com/jweslley/rails_completion
#
#  VERSION: 0.4 - Supports Rails 4.0.x command line completions.


RAILSCOMP_FILE=".rails_generators~"

__ltrim_equal_completions()
{
  if [[ "$1" == *=* && "$COMP_WORDBREAKS" == *=* ]]; then
      # Remove equal-word prefix from COMPREPLY items
      local colon_word=${1%${1##*=}}
      local i=${#COMPREPLY[*]}
      while [[ $((--i)) -ge 0 ]]; do
          COMPREPLY[$i]=${COMPREPLY[$i]#"$colon_word"}
      done
  fi
} # __ltrim_equal_completions() - Copy of standard __ltrim_colon_completions()


# helper functions -------------------------------------------------------------

__railscomp(){
  # Default word breaks includes = and :. Hence use get_by_ref
  local cur
  _get_comp_words_by_ref -n =: cur
  COMPREPLY=( $( compgen -W "$1" -- "$cur" ) )
  # remove colon and equal containing prefix from COMPREPLY items
  __ltrim_colon_completions "$cur"
  __ltrim_equal_completions "$cur"
}

#
# @param $1 Name of variable to return result to
# @param $2 Command list
__railscmd(){
  any_command=$(echo $2 | sed -e 's/[[:space:]]/|/g')
  for (( i=0; i < ${#COMP_WORDS[@]}-1; i++ )); do
    if [[ ${COMP_WORDS[i]} == @($any_command) ]]; then
      eval $1="${COMP_WORDS[i]}"
    fi
  done
}

__rails_env(){
  __railscomp "{-e\ ,--environment=}{development,test,production}"
}

__rails_database(){
  __railscomp "{-d\ ,--database=}{mysql,oracle,postgresql,sqlite3,frontbase,ibm_db,jdbcmysql,jdbcsqlite3,jdbcpostgresql,jdbc}"
}

#
# @param $1 Field's name
# Bug here
__rails_types(){
  __railscomp "${1%:*}:{string,text,integer,float,decimal,datetime,timestamp,date,time,binary,boolean,references,index,uniq,primary_key}"
}

__rails_new(){
  local cur prev
  # Ignore breaks at "=" & ":" while fetching current words
  _get_comp_words_by_ref -n =: cur prev

  case "$cur" in
    -d*|--database=*)
      __rails_database
      return
      ;;
    --ruby=*|--template=*)
      _filedir
      return
      ;;
    -*) __railscomp "$1" ;;
  esac

  case "$prev" in
    -d) __railscomp "mysql oracle postgresql sqlite3 frontbase ibm_db jdbcmysql jdbcsqlite3 jdbcpostgresql jdbc"
    return ;;
  esac
  _filedir
}

# end of helper functions ------------------------------------------------------


# generators -------------------------------------------------------------------

__rails_generators_create_cache(){
  echo "
    require ::File.expand_path('../config/application',  __FILE__)
    require 'rails/generators'

    Rails::Generators.lookup!

    hidden_namespaces = Rails::Generators.hidden_namespaces + ['rails:app']
    generators = Rails::Generators.subclasses.select do |generator|
      hidden_namespaces.exclude? generator.namespace
    end

    shell = Thor::Shell::Basic.new
    generators_opts = generators.inject({}) do |hash, generator|
      options = (generator.class_options_help(shell).values.flatten +
                  generator.class_options.values).uniq.map do |opt|
        boolean_opt = opt.type == :boolean || opt.banner.empty?
        boolean_opt ? opt.switch_name : \"#{opt.switch_name}=\"
      end
      hash[generator.namespace.gsub(/^rails:/, '')] = options
      hash
    end

    File.open(File.join(Rails.root, '${RAILSCOMP_FILE}'), 'w') do |f|
      YAML.dump(generators_opts, f)
    end
  " | ruby > /dev/null
}

__rails_generators_opts(){
  echo "
    require 'yaml'
    generator = '$1'
    generators_opts = YAML.load_file('${RAILSCOMP_FILE}')
    opts = generator.empty? ? generators_opts.keys : generators_opts[generator]
    opts.each { |opt| puts opt }
  " | ruby
}

__rails_generators(){
  recent=`ls -t "$RAILSCOMP_FILE" Gemfile 2> /dev/null | head -n 1`
  if [[ $recent != "$RAILSCOMP_FILE" ]]; then
    __rails_generators_create_cache
  fi
  __railscomp "$(__rails_generators_opts)"
}

__rails_generator_options(){
  local cur generator
  # Ignore breaks at "=" & ":" while fetching current words
  _get_comp_words_by_ref -n =: cur

  if [[ $cur == *:* ]]; then
  # Namespaced generators should also not work.
  # Hence call rails_types only for select generators like model, migrate etc.
    __railscmd generator "model scaffold test_unit:model test_unit:scaffold resource"
    if [ -z "$generator" ]; then
      __railscomp "$(__rails_generators_opts $1)"
    else
      __rails_types "$cur"
    fi
  else
    __railscomp "$(__rails_generators_opts $1)"
  fi
}

#
# @param $1 file's path
# @param $2 filename suffix
# @param $3 name's suffix
# @param $4 kind. Defaults to class.
__rails_destroy(){
  local cur
  # Ignore breaks at "=" & ":" while fetching current words
  _get_comp_words_by_ref -n =: cur

  case "$cur" in
    -*) __railscomp "--pretend --force --skip --quiet" ;;
    *) __railscomp "$(find "$1" -name "*$2.rb" -exec grep ".*${4-class}.*$3.*" {} \; \
                  | awk '{ print $2 }' | sed s/$3$//g)" ;;
  esac
}

# end of generators ------------------------------------------------------------


# rails commands ---------------------------------------------------------------

_rails_new(){
  if [ "${COMP_WORDS[1]}" == "plugin" ]; then
    __rails_new "--ruby= --template= --skip-gemfile --skip-bundle --skip-git --skip-keeps
      --skip-active-record --skip-sprockets --database= --javascript= --skip-javascript
      --dev --edge --skip-test-unit --rc= --no-rc --dummy-path= --full --mountable
      --skip-gemspec --skip-gemfile-entry --force --pretend --quiet --skip --help"
  else
    __rails_new "--ruby= --template= --skip-gemfile --skip-bundle --skip-git --skip-keeps
     --skip-active-record --skip-sprockets --database= --javascript= --skip-javascript --dev --edge
     --skip-test-unit --rc= --no-rc --force --pretend --quiet --skip --help"
  fi
}

_rails_plugin(){
  if [[ -f "bin/rails" ]]; then
    __railscomp "--help --verbose --root= install remove"
  elif [[ -f "script/rails" ]]; then
    __railscomp "--help --verbose --root= install remove"
  else
    __railscomp "new"
  fi
}

_rails_server(){
  local cur prev environment
  # Ignore breaks at "=" & ":" while fetching current words
  _get_comp_words_by_ref -n =: cur prev
  case "$cur" in
    -e*|--environment=*)
      __rails_env
      return
      ;;
  esac

  case "$prev" in
    --config=*|--pid=*) _filedir ;;
    -e) __railscomp "development test production" ;;
    *) __railscomp "--help --pid= -e --environment= --debugger --daemon --config= --binding= --port=" ;;
  esac
}

_rails_console(){
  __railscomp "test development production --sandbox --debugger --help"
}

_rails_dbconsole(){
  local environment

  __railscmd environment "test development production"

  if [ -z "$environment" ]; then
    __railscomp "test development production"
  else
    __railscomp "--include-password --header --mode"
  fi
}

_rails_generate(){
  local cur generator generators
  # Ignore breaks at "=" & ":" while fetching current words
  _get_comp_words_by_ref -n =: cur

  generators=$(test -f "$RAILSCOMP_FILE" && __rails_generators_opts)
  __railscmd generator "$generators"

  if [ -z "$generator" ]; then
    case "$cur" in
      -*) __railscomp "--help" ;;
      *) __rails_generators ;;
    esac
    return
  fi

  __rails_generator_options "$generator"
}

_rails_destroy(){
  local cur generator generators
  # Ignore breaks at "=" & ":" while fetching current words
  _get_comp_words_by_ref -n =: cur

  generators=$(test -f "$RAILSCOMP_FILE" && __rails_generators_opts)
  __railscmd generator "$generators"

  if [ -z "$generator" ]; then
    case "$cur" in
      -*) __railscomp "--help" ;;
      *) __rails_generators ;;
    esac
    return
  fi

  case "$generator" in
    model|scaffold|resource) __rails_destroy "app/models/" ;;
    migration|session_migration) __rails_destroy "db/migrate/" ;;
    mailer) __rails_destroy "app/mailers/" ;;
    observer) __rails_destroy "app/models/" "_observer" "Observer" ;;
    controller|scaffold_controller) __rails_destroy "app/controllers/" "_controller" "Controller" ;;
    helper) __rails_destroy "app/helpers/" "_helper" "Helper" "module" ;;
    integration_test) __rails_destroy "test/integration/" "_test" "Test" ;;
    performance_test) __rails_destroy "test/performance/" "_test" "Test" ;;
    generator) __rails_destroy "lib/generators/" "_generator" "Generator" ;;
    *) __railscomp "--pretend --force --skip --quiet" ;;
  esac
}

_rails_runner(){
  local cur prev
  # Ignore breaks at "=" & ":" while fetching current words
  _get_comp_words_by_ref -n =: cur prev

  case "$cur" in
    -e*|--environment=*)
      __rails_env
      return
      ;;
  esac

  case "$prev" in
    -e) __railscomp "development test production" ;;
    *) __railscomp "--help -e --environment=" ;;
  esac
}

# end of rails commands --------------------------------------------------------


_rails(){
  local cur prev options command commands
  # Exclude '=' and ':' from the list of wordbreaks
  _get_comp_words_by_ref cur

  options="--help --version"
  if [[ -f "bin/rails" ]]; then
    commands="s server c console g generate d destroy r runner plugin db dbconsole"
  elif [[ -f "script/rails" ]]; then
    commands="s server c console g generate d destroy r runner plugin db dbconsole"
  else
    commands="new plugin"
  fi

  __railscmd command "$commands"

  if [ -z "$command" ]; then
    case "$cur" in
      -*) __railscomp "$options" ;;
      *) __railscomp "$commands" ;;
    esac
    return
  fi

  case "$command" in
    new)          _rails_new ;;
    plugin)       _rails_plugin ;;
    s|server)     _rails_server ;;
    c|console)    _rails_console ;;
    db|dbconsole) _rails_dbconsole ;;
    g|generate)   _rails_generate ;;
    d|destroy)    _rails_destroy ;;
    r|runner)     _rails_runner ;;
    *) COMPREPLY=() ;;
  esac
}

complete -o default -o nospace -F _rails rails
