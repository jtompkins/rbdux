require 'hamster'

require_relative '../../lib/action'
require_relative '../../lib/store'

Todo = Struct.new(:text, :completed)

class CommandProcessor
  def parse_command(text)
    command, *params = text.split(' ')

    case command
    when 'add'
      add_todo(params.join(' '))
    when 'toggle'
      toggle_todo(params.first.to_i)
    when 'visible'
      toggle_visibility
    when 'exit'
      system 'clear'
      exit(true)
    else
      add_todo(text.chomp)
    end
  end

  def add_todo(text)
    Rbdux::Store.dispatch(NewTodoAction.with_payload(Todo.new(text, false)))
  end

  def toggle_todo(id)
    Rbdux::Store.dispatch(ToggleTodoAction.with_payload(id))
  end

  def toggle_visibility
    Rbdux::Store.dispatch(ToggleVisibilityAction.empty)
  end

  def gather_input
    puts
    print '> '
    parse_command(gets)
  end
end

class TodoRenderer
  def render
    system 'clear'

    puts 'TODOs'
    puts '============='
    puts

    todos = Rbdux::Store.state[:todos]

    if Rbdux::Store.state[:visibility] != :show_completed
      todos = todos.reject(&:completed)
    end

    todos.each_with_index do |t, i|
      puts "#{i + 1}. #{t.completed ? '[X]' : '[ ]'} #{t.text}"
    end
  end
end

class TodoApp
  def initialize(processor, renderer)
    @processor = processor
    @renderer = renderer

    Rbdux::Store.subscribe { run }
  end

  def run
    @renderer.render
    @processor.gather_input
  end
end

Rbdux::Action.define('toggle_todo')
Rbdux::Action.define('new_todo')
Rbdux::Action.define('toggle_visibility')

Rbdux::Store
  .with_state(Hamster::Hash.new(visibility: :hide_completed, todos: Hamster::Vector.empty))
  .when_merging do |old_state, new_state, state_key|
    to_merge =  if state_key
                  Hamster::Hash.new(state_key => new_state)
                else
                  new_state
                end

    old_state.merge(to_merge)
  end

Rbdux::Store.reduce(ToggleVisibilityAction, :visibility) do |state, _|
  state == :hide_completed ? :show_completed : :hide_completed
end

Rbdux::Store.reduce(NewTodoAction, :todos) do |state, action|
  state.add(action.payload)
end

Rbdux::Store.reduce(ToggleTodoAction, :todos) do |state, action|
  idx = action.payload - 1

  todo = state[idx]

  todo.completed = !todo.completed unless todo.nil?

  state.put(idx, todo)
end

TodoApp.new(CommandProcessor.new, TodoRenderer.new).run
