# 💎 Zephyr WASM

[![Gem Version](https://badge.fury.io/rb/zephyr_rb.svg)](https://badge.fury.io/rb/zephyr_rb)

**Build reactive web components using Ruby and WebAssembly**

Zephyr WASM is a lightweight framework for creating interactive web components using Ruby, compiled to WebAssembly and running entirely in the browser. Write your UI logic in Ruby with a declarative template syntax, and let the browser handle the rest.

## ✨ Features

- **Pure Ruby** - Write components in idiomatic Ruby
- **Reactive State** - Automatic re-rendering on state changes
- **Web Components** - Standard custom elements that work anywhere
- **Zero Build Step** - Load Ruby files directly in the browser
- **Lifecycle Hooks** - `on_connect` and `on_disconnect` callbacks
- **Event Handling** - First-class support for DOM events
- **Template DSL** - Clean, declarative component templates

## 🚀 Build ZephyrRB

run the following script:
```bash
ruby build.rb
```
this will generate the zephyrRB.js file

## 🚀 Quick Start

### 1. Serve Your Files

You need an HTTP server (ruby.wasm can't load files via `file://`):

```bash
# Python
python3 -m http.server 8000

# Ruby
ruby -run -ehttpd . -p8000

# Node
npx http-server -p 8000
```

### 2. Create Your HTML

```html
<!DOCTYPE html>
<html>
<head>
    <title>My Zephyr App</title>
</head>
<body>
<!-- Use your components -->
<x-counter initial="5"></x-counter>

<!-- Load required items from ZephyrRB-->
<script src="/dist/zephyrRB.js"></script>
</body>
</html>
```

### 3. Define Components

Create `components.rb`:

```ruby
# Counter component
ZephyrWasm.component('x-counter') do
  observed_attributes :initial

  on_connect do
    count = (self['initial'] || '0').to_i
    set_state(:count, count)
  end

  template do |b|
    comp = self

    b.div(class: 'counter') do
      b.button(on_click: ->(_) { comp.set_state(:count, comp.state[:count] - 1) }) do
        b.text('-')
      end

      b.span { b.text(comp.state[:count]) }

      b.button(on_click: ->(_) { comp.set_state(:count, comp.state[:count] + 1) }) do
        b.text('+')
      end
    end
  end
end
```

### 4. Open in Browser

Visit `http://localhost:8000` and see your component in action! 🎉

## 📦 File Structure

```
ZephyrRB/
├── src/
│   ├── browser.script.iife.js
│   ├── component.rb
│   ├── components.rb
│   ├── dom_builder.rb
│   ├── registry.rb
│   ├── zephyr-bridge.js
│   └── zephyr_wasm.rb
├── dist/ 
│   └── zephyrRB.js
├── lib/ 
│   ├── cli.rb
│   └── version.rb
├── README.md
├── zephyr_rb.gemspec
└── build.rb
```

## 📚 Component API

### Basic Structure

```ruby
ZephyrWasm.component('x-my-component') do
  # Declare observed HTML attributes
  observed_attributes :foo, :bar

  # Lifecycle: called when component is added to DOM
  on_connect do
    # Initialize state
    set_state(:count, 0)
  end

  # Lifecycle: called when component is removed from DOM
  on_disconnect do
    # Cleanup if needed
  end

  # Define your component's UI
  template do |b|
    comp = self  # Capture component reference

    b.div(class: 'my-component') do
      b.h1 { b.text("Hello from Ruby!") }
    end
  end
end
```

### State Management

```ruby
# Set state (triggers re-render)
set_state(:key, value)

# Read state
state[:key]

# Multiple state updates
set_state(:count, 0)
set_state(:loading, false)
```

### Attributes

```ruby
# Read HTML attributes
value = self['data-id']

# Write HTML attributes
self['data-id'] = 'new-value'

# Observed attributes automatically update state
observed_attributes :user_id

on_connect do
  # state[:user_id] is automatically set from the attribute
  puts state[:user_id]
end
```

### Event Handlers

```ruby
template do |b|
  comp = self

  # Click handler
  b.button(on_click: ->(_e) { comp.set_state(:clicked, true) }) do
    b.text('Click me')
  end

  # Input handler
  b.tag(:input, 
    type: 'text',
    on_input: ->(e) { comp.set_state(:value, e[:target][:value].to_s) }
  )

  # Any DOM event works: on_change, on_submit, on_keydown, etc.
end
```

### Template DSL

```ruby
template do |b|
  comp = self

  # HTML elements (method name = tag name)
  b.div(class: 'container') do
    b.h1 { b.text('Title') }
    b.p { b.text('Paragraph') }
  end

  # Attributes
  b.div(id: 'main', class: 'active', data_value: '123')

  # Generic tag method
  b.tag(:input, type: 'text', placeholder: 'Enter text...')

  # Text nodes
  b.span { b.text('Hello') }

  # Conditional rendering
  b.render_if(comp.state[:show]) do
    b.p { b.text('Visible!') }
  end

  # List rendering
  b.render_each(comp.state[:items] || []) do |item|
    b.li { b.text(item[:name]) }
  end

  # Boolean properties (checked, disabled, selected)
  b.tag(:input, type: 'checkbox', checked: true)

  # Inline styles
  b.div(style: { color: 'red', font_size: '16px' })
end
```

## 🎯 Complete Examples

### Counter with Reset

```ruby
ZephyrWasm.component('x-counter') do
  observed_attributes :initial

  on_connect do
    initial = (self['initial'] || '0').to_i
    set_state(:count, initial)
    set_state(:initial, initial)
  end

  template do |b|
    comp = self
    count = comp.state[:count] || 0

    b.div(class: 'counter') do
      b.button(on_click: ->(_) { comp.set_state(:count, count - 1) }) do
        b.text('-')
      end

      b.span(class: 'count') { b.text(count) }

      b.button(on_click: ->(_) { comp.set_state(:count, count + 1) }) do
        b.text('+')
      end

      b.button(on_click: ->(_) { comp.set_state(:count, comp.state[:initial]) }) do
        b.text('Reset')
      end
    end
  end
end
```

### Toggle Button

```ruby
ZephyrWasm.component('x-toggle') do
  observed_attributes :label, :checked

  on_connect do
    set_state(:checked, self['checked'] == 'true')
  end

  template do |b|
    comp = self
    is_checked = comp.state[:checked]
    label = comp['label'] || 'Toggle'

    b.button(
      class: is_checked ? 'toggle active' : 'toggle',
      on_click: ->(_) {
        new_state = !comp.state[:checked]
        comp.set_state(:checked, new_state)
        comp['checked'] = new_state.to_s

        # Dispatch custom event
        event = JS.global[:CustomEvent].new(
          'toggle-change',
          { bubbles: true, detail: { checked: new_state }.to_js }.to_js
        )
        comp.element.call(:dispatchEvent, event)
      }
    ) do
      b.text(label)
    end
  end
end
```

### Todo List

```ruby
ZephyrWasm.component('x-todo-list') do
  on_connect do
    set_state(:todos, [])
    set_state(:input_value, '')
  end

  template do |b|
    comp = self

    b.div(class: 'todo-list') do
      # Input section
      b.div(class: 'input-group') do
        b.tag(:input,
          type: 'text',
          placeholder: 'Enter a task...',
          value: comp.state[:input_value] || '',
          on_input: ->(e) { comp.set_state(:input_value, e[:target][:value].to_s) }
        )

        b.button(
          on_click: ->(_) {
            value = comp.state[:input_value]&.strip
            if value && !value.empty?
              todos = (comp.state[:todos] || []).dup
              todos << { 
                id: JS.global[:Date].new.call(:getTime), 
                text: value, 
                done: false 
              }
              comp.set_state(:todos, todos)
              comp.set_state(:input_value, '')
            end
          }
        ) { b.text('Add') }
      end

      # Todo items
      b.tag(:ul) do
        todos = comp.state[:todos] || []
        b.render_each(todos) do |todo|
          b.tag(:li, class: todo[:done] ? 'done' : '') do
            b.tag(:input,
              type: 'checkbox',
              checked: !!todo[:done],
              on_change: ->(e) {
                updated_todos = (comp.state[:todos] || []).map { |t|
                  t[:id] == todo[:id] ? { **t, done: !!e[:target][:checked] } : t
                }
                comp.set_state(:todos, updated_todos)
              }
            )

            b.span { b.text(todo[:text]) }

            b.button(
              class: 'delete',
              on_click: ->(_) {
                filtered = (comp.state[:todos] || []).reject { |t| t[:id] == todo[:id] }
                comp.set_state(:todos, filtered)
              }
            ) { b.text('×') }
          end
        end
      end
    end
  end
end
```

## 🔧 Advanced Usage

### Custom Events

```ruby
# Dispatch custom events from your component
event = JS.global[:CustomEvent].new(
  'my-event',
  { 
    bubbles: true, 
    detail: { foo: 'bar' }.to_js 
  }.to_js
)
element.call(:dispatchEvent, event)
```

### DOM Queries

```ruby
on_connect do
  # Query inside component
  button = query('.my-button')
  
  # Query all
  items = query_all('.item')
end
```

### Accessing the Element

```ruby
on_connect do
  # Direct access to the DOM element
  element[:id] = 'my-component'
  element.call(:setAttribute, 'data-loaded', 'true')
end
```

### Working with JavaScript

```ruby
# Call JavaScript functions
JS.global[:console].call(:log, 'Hello from Ruby!')

# Access global objects
date = JS.global[:Date].new
timestamp = date.call(:getTime)

# Call methods on JS objects
element.call(:scrollIntoView)
```

## 🎨 Styling

Add CSS to your HTML:

```html
<style>
  .counter {
    display: flex;
    gap: 1rem;
    align-items: center;
  }

  .counter button {
    padding: 0.5rem 1rem;
    border: none;
    border-radius: 4px;
    background: #667eea;
    color: white;
    cursor: pointer;
  }

  .counter button:hover {
    background: #5568d3;
  }
</style>
```

## ⚠️ Important Notes

### Must Use HTTP Server

Ruby WASM cannot load files via `file://` protocol. Always serve your files:

```bash
python3 -m http.server 8000
```

### Component Names Must Include Hyphen

Custom element names require a hyphen:

```ruby
# ✅ Good
ZephyrWasm.component('x-counter')
ZephyrWasm.component('my-button')

# ❌ Bad
ZephyrWasm.component('counter')  # Missing hyphen!
```

### Capture Component Reference in Templates

Always capture `self` as a local variable in templates:

```ruby
template do |b|
  comp = self  # ✅ Capture this!

  b.button(on_click: ->(_) {
    comp.set_state(:clicked, true)  # Use comp, not self
  })
end
```

### Event Handlers Return Procs

Event handlers should be Ruby procs that will be converted to JS:

```ruby
# ✅ Good
on_click: ->(_e) { comp.set_state(:count, 1) }

# ❌ Bad - don't call .to_js yourself
on_click: ->(_e) { comp.set_state(:count, 1) }.to_js
```

## 🐛 Troubleshooting

### Components Don't Appear

1. Check browser console for errors
2. Ensure you're using an HTTP server (not `file://`)
3. Verify all `.rb` files are in the same directory as `index.html`
4. Check Network tab for 404 errors

### "Component Already Registered" Warning

This happens if you reload without refreshing. It's harmless but you can add:

```ruby
ZephyrWasm::Registry.clear
```

### State Not Updating

Make sure you're using `set_state` and not modifying state directly:

```ruby
# ✅ Good
set_state(:count, state[:count] + 1)

# ❌ Bad - won't trigger re-render
state[:count] += 1
```

## 🏗️ How It Works

1. **Ruby Files Load**: Browser fetches your `.rb` files via `<script type="text/ruby" src="...">`
2. **Components Register**: Ruby code registers component metadata in `window.ZephyrWasmRegistry`
3. **Bridge Watches**: `zephyr-bridge.js` uses a Proxy to watch for new components
4. **Custom Elements Defined**: Bridge defines custom elements using `setTimeout()` to avoid nested VM calls
5. **Component Lifecycle**: When elements connect to DOM, Ruby component instances are created
6. **Reactive Rendering**: State changes trigger re-renders using DocumentFragment for efficiency

## 📄 License

MIT License - feel free to use in your projects!

## 🤝 Contributing

This is an experimental framework. Issues and pull requests welcome!

## 🙏 Credits

Built with:
- [ruby.wasm](https://github.com/ruby/ruby.wasm) - Ruby in the browser
- Web Components - Standard browser APIs
- Love for Ruby 💎

---

**Happy coding with Ruby and WebAssembly!** 🚀