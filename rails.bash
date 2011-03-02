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
#  VERSION: 0.1.0


RAILSCOMP_FILE=".rails_generators~"
RUNTIME_OPTS="--force --skip --pretend --quiet"

__railscomp(){
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $( compgen -W "$1" -- "$cur" ) )
}

#
# @param $1 Name of variable to return result to
# @param $2 Command list
__railscmd(){
  any_command=$(echo $2 | sed -e 's/\s\+/|/g')
  for (( i=0; i < ${#COMP_WORDS[@]}-1; i++ )); do
    if [[ ${COMP_WORDS[i]} == @($any_command) ]]; then
      eval $1="${COMP_WORDS[i]}"
    fi
  done
}

__rails_env(){
  __railscomp "{-e,--environment=}{test,development,production}"
}

# Generators -------------------------------------------------------------------

__rails_generator_cache() {

  # TODO hard-coded options. Get them from COMP_WORDS.
  orm="active_record"
  test_framework="test_unit"
  template_engine="erb"

  echo "
    require 'rubygems'
    require 'rails/generators'
    require 'config/application'

    Rails::Generators.configure!

    hidden_namespaces = [
      'rails',
      '${orm}:migration',
      '${orm}:model',
      '${orm}:observer',
      '${orm}:session_migration',
      '${test_framework}:controller',
      '${test_framework}:helper',
      '${test_framework}:integration',
      '${test_framework}:mailer',
      '${test_framework}:model',
      '${test_framework}:observer',
      '${test_framework}:scaffold',
      '${test_framework}:view',
      '${test_framework}:performance',
      '${test_framework}:plugin',
      '${template_engine}:controller',
      '${template_engine}:scaffold',
      '${template_engine}:mailer'
    ]

    rails_generators = [
      'controller',
      'generator',
      'helper',
      'integration_test',
      'mailer',
      'migration',
      'model',
      'observer',
      'performance_test',
      'plugin',
      'resource',
      'scaffold',
      'scaffold_controller',
      'session_migration',
      'stylesheets',
    ]

    generators = Rails::Generators.help.map{|i| i[1]}.flatten - hidden_namespaces + rails_generators

    File.open(File.join(Rails.root, '${RAILSCOMP_FILE}'), 'w') do |f|
      generators.each { |g| f.puts g }
    end
  " | ruby > /dev/null
}

__rails_generators(){
  recent=`ls -t "$RAILSCOMP_FILE" Gemfile 2> /dev/null | head -n 1`
  if [[ $recent != "$RAILSCOMP_FILE" ]]; then
    __rails_generator_cache
  fi
  __railscomp "`cat "$RAILSCOMP_FILE"`"
}

#
# @param $1 Field's name
__rails_types(){
  __railscomp "${1%:*}:{string,text,integer,float,decimal,datetime,timestamp,date,time,binary,boolean}" 
}

#
# @param $1 Option's list
__rails_generator_with_fields_and_options(){
  local cur
  _get_comp_words_by_ref cur

  if [[ $cur == *:* ]]; then
    __rails_types "$cur"
  else
    __railscomp "$1 $RUNTIME_OPTS"
  fi
}

__rails_controller_generator(){
  __railscomp "-e --template-engine= -t --test-framework= --helper $RUNTIME_OPTS" 
}

__rails_generator_generator(){
  __railscomp "--namespace $RUNTIME_OPTS"
}

__rails_helper_generator(){
  __railscomp "-t --test-framework= $RUNTIME_OPTS" 
}

__rails_integration_test_generator(){
  __railscomp "--integration-tool= $RUNTIME_OPTS"
}

__rails_mailer_generator(){
  __railscomp "-e --template-engine= -t --test-framework= $RUNTIME_OPTS"
}

__rails_migration_generator(){
  __rails_generator_with_fields_and_options "-o --orm="
}

__rails_model_generator(){
  __rails_generator_with_fields_and_options "-o --orm= --fixture -r --fixture-replacement= --migration --parent= --timestamps -t --test-framework="
}

__rails_observer_generator(){
  __railscomp "-o --orm= -t --test-framework= $RUNTIME_OPTS"
}

__rails_performance_test_generator(){
  __railscomp "--performance-tool= $RUNTIME_OPTS" 
}

__rails_plugin_generator(){
  __railscomp "-t --test-framework= -g --generator -r --tasks= $RUNTIME_OPTS" 
}

__rails_resource_generator(){
  __rails_generator_with_fields_and_options "force-plural -a --actions= -c --resource-controller= -o --orm= --fixture -r --fixture-replacement= --migration --parent= --timestamps -e --template-engine= -t --test-framework= --helper"
}

__rails_scaffold_generator(){
  __rails_generator_with_fields_and_options "-c --scaffold-controller= -o --orm= --force-plural -y --stylesheets -t --test_framework= -e --template-engine= --helper"
}

__rails_scaffold_controller_generator(){
  __railscomp "-t --test-framework= -e --template-engine= -o --orm= --force-plural --helper $RUNTIME_OPTS"
}

__rails_session_migration(){
  __railscomp "-o --orm= $RUNTIME_OPTS"
}

__rails_stylesheets_generator(){
  __railscomp "$RUNTIME_OPTS" 
}

# end of Generators ------------------------------------------------------------


# Rails commands ---------------------------------------------------------------

_rails_generate(){
  local cur generator generators
  _get_comp_words_by_ref cur

  generators=$(test -f "$RAILSCOMP_FILE" && cat "$RAILSCOMP_FILE")
  __railscmd generator "$generators"

  if [ -z "$generator" ]; then
    case "$cur" in
      -*) __railscomp "-h --help" ;;
      *) __rails_generators ;;
    esac
    return
  fi

  local completion_func="__rails_${generator}_generator"
  declare -F $completion_func >/dev/null && $completion_func && return
}

_rails_new(){
  local cur prev
  _get_comp_words_by_ref cur prev

  case "$cur" in
    -d*|--database=*)
      __railscomp "{-d,--database=}{mysql,oracle,postgresql,sqlite3,frontbase,ibm_db}"
      return
      ;;
  esac
 
  case "$prev" in
    -r*|--ruby=*|-b*|--builder=*|-m*|--template=*) _filedir ;;
    *) __railscomp "-G --skip-git --dev --edge --skip-gemfile -O --skip-active-record
      -J --skip-prototype -T --skip-test-unit -s --skip -f --force -p --pretend
      -q --quiet -h --help -v --version -b -builder= -m --template= -d --database= -r --ruby="
  esac
}

_rails_server(){
  local cur prev
  _get_comp_words_by_ref cur prev

  case "$cur" in
    -e*|--environment=*)
      __rails_env
      return
      ;;
  esac
 
  case "$prev" in
    -c*|--config=*|-P*|--pid=*) _filedir ;;
    *) __railscomp "-h --help -P --pid= -e --environment= -u --debugger -d --daemon -c --config= -b --binding= -p --port=" ;;
  esac
}

_rails_console(){
  __railscomp "test development production -s --sandbox --debugger"
}

_rails_profiler(){
  local cur prev
  _get_comp_words_by_ref cur

  case "$cur" in
    -*) __railscomp "-h --help" ;;
    *) __railscomp "flat graph graph_html"
  esac
}

_rails_plugin(){
  local cur prev
  _get_comp_words_by_ref cur prev
 
  case "$prev" in
    -r*|--root=*) _filedir ;;
    *) __railscomp "-h --help -v --verbose -r --root= -s --source= install remove" ;;
  esac
}

_rails_runner(){
  local cur prev
  _get_comp_words_by_ref cur prev

  case "$cur" in
    -e*|--environment=*)
      __rails_env
      return
      ;;
  esac

  case "$prev" in
    runner) __railscomp "-h --help -e --environment=" ;;
    -e*|--environment=*) _filedir ;;
    *) COMPREPLY==() ;;
  esac
}

_rails_benchmarker(){
  __railscomp "-h --help"
}

# end of Rails commands --------------------------------------------------------


_rails(){
  local cur options command commands
  _get_comp_words_by_ref cur

  options="-h --help -v --version"
  if [[ -f "script/rails" ]]; then
    commands="s server c console g generate destroy profiler plugin runner benchmarker db dbconsole"
  else
    commands="new"
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
    s|server)     _rails_server ;;
    c|console)    _rails_console ;;
    g|generate)   _rails_generate ;;
    destroy)      _rails_generate ;;
    profiler)     _rails_profiler ;;
    plugin)       _rails_plugin ;;
    runner)       _rails_runner ;;
    benchmarker)  _rails_benchmarker ;;
    db|dbconsole) COMPREPLY=() ;;
    *) COMPREPLY=() ;;
  esac
}

complete -o default -o nospace -F _rails rails
