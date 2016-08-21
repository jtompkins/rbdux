# Rbdux

![Rbdux Logo](/assets/Logo-Dark2x.png)

## What is Rbdux?

Rbdux is a library (heavily inspired by [ReduxJS]()) that helps enable one-way data flow in Ruby programs. Rbdux exposes a very small API surface area, making it easy to learn and easy to drop in to a program of any size.

## Using Rbdux

If you're not familiar with the one-way data flow pattern, check out this great [cartoon intro to Redux](https://code-cartoons.com/a-cartoon-intro-to-redux-3afb775501a6#.vlnlx0iwy). Almost every concept transfers over to Rbdux.

Rbdux mostly differs from Redux in order to make using the library more Ruby-like - some API calls are changed to match Ruby standards, and some places where you would pass an anonymous function to Redux take classes or blocks in Rbdux.

### Setting Up Actions

The most fundamental construct in Rbdux is the `Action` - a type that represents a particular form of interaction with the user (and the details of that interaction in the form of a data payload).

You can define an action in Rbdux using the `Rbdux::Action.define` class method:

```ruby
Rbdux::Action.define('new_todo')
```

Defining an action results in the creation of a new class, with three class methods defined for you:

```ruby
NewTodo.with_payload('A todo item!')
NewTodo.with_error('Can\'t add todo!')
NewTodo.empty
```

Each class method creates a new instance of your action type, differing only in the payload.

### Using the Store

Like Redux, Rbdux represents the state of your application with a singleton store - but unlike Redux, Rbdux's store is a class: `Rbdux::Store`.

The `Store` is responsible for accessing and manipulating your application's state - but it delegates the actual storage of the state to another class, called a _store container_, about which we'll have more to say later. For now, it's enough to know that you can specify your application's initial state by passing a store container to the Rbdux store using the `Rbdux::Store.with_store` class method:

```ruby
Rbdux::Store
  .with_store(
    Rbdux::Stores::MemoryStore.with_state(
      todos: []
    )
  )
```

`Rbdux::Store` has a single class method, `.with_store`; any other messages passed to the `Store` are delegated to the singleton instance.

#### Defining Reducers

Your application's state is assumed to be immutable; it should never be manipulated directly. Instead, when a user interaction is received by the system (via a dispatched `Action`), the state can be mutated by a function called a `reducer`.

Reducers all share a of couple important behaviors - first, they work by copying all or part of the application state, modifying the copy, and then replacing the original state with the modified copy, and second, they are _pure functions_ - that is, they are idempotent and have no side effects.

You can define a reducer for your application with the `Store` instance's `#reduce` method, which takes an Action type, a block, and an optional _state key_. The Store uses the action type to determine which reducers are called when an action is dispatched. The block defines the reducer function. The _store key_ is used to tell the store that the reducer operates only on a sub-set of the application state - if a key is provided, the store will pass the part of the state that matches the key to the reducer.

```ruby
Rbdux::Store.reduce(NewTodoAction, :todos) do |state, action|
  state.add(action.payload)
end
```

#### Dispatching Actions

Once you've defined a reducer and an action, you can dispatch the action to the reducer using the Store instance's `#dispatch` method:

```ruby
Rbdux::Store.dispatch(NewTodoAction.with_payload('A new todo item!'))
```

#### Subscribing to Changes

A program that doesn't know about state changes isn't much of a program. Your application can be notified of state changes by subscribing to the Store with the `#subscribe` method:

```ruby
token = Rbdux::Store.subscribe { do_a_thing }
```

`#subscribe` takes a block, which will be called when the store's state is updated.

This method returns a unique token that can be passed to the `#unsubscribe` method to stop receiving notifications:

```ruby
Rbdux::Store.unsubscribe(token)
```

#### Accessing Store State

Accessing the state is one place where Rbdux differs from Redux - Rbdux doesn't allow direct access to the state. Instead, you can access the state through the `#fetch` method:

```ruby
todos = Rbdux::Store.fetch(:todos)
```

Like other implementations of `#fetch` in Ruby's standard library, you may also pass an optional second argument, which will be returned if the key isn't found:

```ruby
todos = Rbdux::Store.fetch(:todos, [])
```

...or you can pass a block, which will be called if the key isn't defined in the state:

```ruby
todos = Rbdux::Store.fetch(:todos) do
  raise 'Key not found!'
end
```

If you don't pass `#fetch` a key, the entire application state is returned.

### Advanced Configuration

While Rbdux is still very new, there are two extension points you should know about.

#### Middleware

It's often helpful to be able to intercept an action before it is passed to the reducers, or to be notified of a change state before the store is updated. To help out with that, Rbdux borrows the _middleware_ concept from Redux, Rack, and many other libraries.

Rbdux has two middleware hooks: before an action is passed to the reducers, and after the reducers run but before the store is updated with the new state.

To register middleware, you call the `#add_middleware` method, passing in an object that can respond to `#before`, `#after`, or both. The `#before` method receives a reference to the store and the dispatched action; if `#before` returns a value, it replaces the originally-dispatched action and is passed on to the next middleware in the chain. The `#after` receives a reference to the store, and the _previous_ and _next_ application states.

```ruby
class LoggerMiddleware
  def before(store, action)
    puts action.inspect
  end

  def after(store, prev, next)
    puts "old: #{prev} - new: #{next}"
  end
end

Rbdux::Store.add_middleware(LoggerMiddleware.new)
```

#### Thunk Middleware

One common question about one-way libraries is how external data should be accessed - the reducers must be pure functions, so they shouldn't reach out to databases or external APIs, so where do we access those resources?

Rbdux ships with a middleware called `Thunk` to help solve this problem. `Thunk` takes advantage of a special property of `Action`s - they can receive a block when they are defined. If the `Thunk` middleware is active, it will call this block when an action of that type dispatched; the block (which is not expected or assumed to be a pure function) can then make any I/O or HTTP requests you need:

```ruby
Rbdux::Store.add_middleware(Rbdux::Middleware.Thunk.new)

Rbdux::Action.define('an_action') do
  # make any external calls you need!
end
```

`Thunk` will pass the return value of the block on to the next middleware in the chain.

With that structure in place, a common pattern for making external calls is to define two actions: one action represents the _request_ for data, and the second action represents the _response or result_ of that request.

In your application, dispatch the request action with whatever data you need to make the service call.

In the Action block, you can take the payload of the request action and make service calls, then return a response action with the response data in the payload:

```ruby
require 'net/http'


Rbdux::Action.define('get_data')
  do |store, action|
    uri = URI('http://example.com/todos')
    data = Net::HTTP.get(uri)

    DataRetrievedAction.with_payload(data)
  end

Rbdux::Action.define('data_retrieved')
```

#### Store Containers

We noted earlier that the `Store` delegates the actual storage of application state to a _store container_, but what exactly makes up the container?

Any object that responds to the container protocol can act as a store container:

| Message | Arguments | Returns |
|---------|-----------|---------|
| `#fetch` | `key`<br>(Optional) a default value<br>(Optional) a block that will be called if the key isn't found | The state associated with the key |
| `#all` | | All application state |
| `#set` | `key`, `value` | `nil` |
| `#replace` | A new set of application state | `nil` |


Rbdux ships with two built-in containers: `MemoryStore` is a simple Redux-style `Hash` store, and `ImmutableMemoryStore` uses the `Hamster` gem to provide immutable storage of the application state.

Both built-in stores respond to the `.with_state` class method, which allows you to specify the inital state of the store:

```ruby
Rbdux::Stores::MemoryStore.with_state(todos: [])
```

## API Reference

### `Rbdux::Action`

| Message | Arguments | Returns |
|---------|-----------|---------|
| `.define` | `type_name` : `String` | A reference to the new Action type |

### Defined Actions

| Message | Arguments | Returns |
|---------|-----------|---------|
| `.empty` | | An empty action |
| `.with_payload` | an `Object` | An action with the specified payload |
| `.with_error` | An `Error` object, or a `String` error message | An action with the specified error |
| `#payload` | | The action's payload |
| `#error?` | | `Boolean` |

### `Rbdux::Store`

| Message | Arguments | Returns |
|---------|-----------|---------|
| `.with_store` | A store container | The `Store` instance |
| `#add_middleware` | A middleware | The `Store` instance |
| `#fetch` | (Optional) `state_key` | The value of the state associated with the key, or the entire state |
| `#reduce` | `action`: `Class` <br> (Optional) `state_key` <br> A block defining the reducer | The `Store` instance |
| `#dispatch` | The action to dispatch | `nil` |
| `#subscribe` | A block that be called with the store updates | A unique token : `String` |
| `#unsubscribe` | The token returned from `#subscribe` : `String` | `nil` |

### Middleware

Any object can act as an Rdbux middleware, as long as it responds to the `middleware` protocol:

| Message | Arguments | Returns |
|---------|-----------|---------|
| #before | `action`, `store` | a replacement action, or `nil` |
| #after | `previous_state`, `new_state` | `nil` |

### `MemoryStore`

| Message | Arguments | Returns |
|---------|-----------|---------|
| `.with_state` | The initial application state as a `Hash` | A `MemoryStore` instance |

### `ImmutableMemoryStore`

| Message | Arguments | Returns |
|---------|-----------|---------|
| `.with_state` | The initial application state as a `Hash` | An `ImmutableMemoryStore` instance |
