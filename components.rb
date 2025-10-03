# frozen_string_literal: true

require_relative 'zephyr_wasm'

# Counter component - demonstrates state management
ZephyrWasm.component('x-counter') do
  observed_attributes :initial

  on_connect do
    # Initialize count from attribute or default to 0
    count = (self['initial'] || '0').to_i
    set_state(:count, count)
  end

  template do
    div(class: 'counter-container') do
      button(
        class: 'btn btn-decrement',
        on_click: ->(_e) {
          current = state[:count] || 0
          set_state(:count, current - 1)
        }.to_js
      ) do
        text('-')
      end

      span(class: 'counter-value') do
        text(state[:count] || 0)
      end

      button(
        class: 'btn btn-increment',
        on_click: ->(_e) {
          current = state[:count] || 0
          set_state(:count, current + 1)
        }.to_js
      ) do
        text('+')
      end
    end
  end
end

# Toggle button component
ZephyrWasm.component('x-toggle') do
  observed_attributes :label, :checked

  on_connect do
    is_checked = self['checked'] == 'true'
    set_state(:checked, is_checked)
  end

  template do
    div(class: 'toggle-wrapper') do
      button(
        class: state[:checked] ? 'toggle active' : 'toggle',
        on_click: ->(_e) {
          new_state = !state[:checked]
          set_state(:checked, new_state)
          self['checked'] = new_state.to_s
          
          # Dispatch custom event
          event = JS.global[:CustomEvent].new(
            'toggle-change',
            { 
              bubbles: true,
              detail: { checked: new_state }.to_js
            }.to_js
          )
          element.call(:dispatchEvent, event)
        }.to_js
      ) do
        text(self['label'] || 'Toggle')
      end
    end
  end
end

# Todo list component - demonstrates list rendering
ZephyrWasm.component('x-todo-list') do
  on_connect do
    set_state(:todos, [])
    set_state(:input_value, '')
  end

  template do
    div(class: 'todo-list') do
      div(class: 'todo-input-group') do
        tag(:input,
          type: 'text',
          placeholder: 'Enter a task...',
          value: state[:input_value] || '',
          on_input: ->(e) {
            set_state(:input_value, e[:target][:value].to_s)
          }.to_js
        )

        button(
          class: 'btn btn-primary',
          on_click: ->(_e) {
            value = state[:input_value]&.strip
            if value && !value.empty?
              todos = state[:todos] || []
              todos << { id: Time.now.to_i, text: value, done: false }
              set_state(:todos, todos)
              set_state(:input_value, '')
            end
          }.to_js
        ) do
          text('Add')
        end
      end

      tag(:ul, class: 'todo-items') do
        todos = state[:todos] || []
        
        render_each(todos) do |todo|
          tag(:li, class: todo[:done] ? 'done' : '') do
            tag(:input,
              type: 'checkbox',
              checked: todo[:done],
              on_change: ->(e) {
                todos = state[:todos]
                item = todos.find { |t| t[:id] == todo[:id] }
                item[:done] = e[:target][:checked]
                set_state(:todos, todos)
              }.to_js
            )

            span { text(todo[:text]) }

            button(
              class: 'btn-delete',
              on_click: ->(_e) {
                todos = state[:todos].reject { |t| t[:id] == todo[:id] }
                set_state(:todos, todos)
              }.to_js
            ) do
              text('×')
            end
          end
        end
      end
    end
  end
end

# Tabs component - demonstrates more complex UI
ZephyrWasm.component('x-tabs-wasm') do
  observed_attributes :active

  on_connect do
    active = self['active'] || 'tab1'
    set_state(:active, active)
    
    # Parse tabs from child elements or data attribute
    set_state(:tabs, [
      { id: 'tab1', label: 'Tab 1', content: 'Content 1' },
      { id: 'tab2', label: 'Tab 2', content: 'Content 2' },
      { id: 'tab3', label: 'Tab 3', content: 'Content 3' }
    ])
  end

  template do
    div(class: 'tabs-container') do
      # Tab list
      div(class: 'tab-list', role: 'tablist') do
        tabs = state[:tabs] || []
        active = state[:active]

        render_each(tabs) do |tab|
          button(
            class: tab[:id] == active ? 'tab-button active' : 'tab-button',
            role: 'tab',
            on_click: ->(_e) {
              set_state(:active, tab[:id])
              self['active'] = tab[:id]
            }.to_js
          ) do
            text(tab[:label])
          end
        end
      end

      # Tab content
      div(class: 'tab-content') do
        tabs = state[:tabs] || []
        active_tab = tabs.find { |t| t[:id] == state[:active] }
        
        if active_tab
          div(class: 'tab-panel') do
            text(active_tab[:content])
          end
        end
      end
    end
  end
end
