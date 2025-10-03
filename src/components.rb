# frozen_string_literal: true
require "js"

# =============================================================================
# BUTTON COMPONENT
# =============================================================================
ZephyrWasm.component('x-button') do
  observed_attributes :label, :disabled, :variant

  on_connect do
    set_state(:label, self['label'] || '')
    set_state(:disabled, self['disabled'] == 'true')
    set_state(:variant, self['variant'] || 'default')
  end

  template do |b|
    comp = self
    label = comp.state[:label] || comp['label'] || ''
    disabled = comp.state[:disabled]
    variant = comp.state[:variant] || 'default'

    bg_color = case variant
               when 'primary' then '#4f46e5'
               when 'danger' then '#ef4444'
               when 'success' then '#10b981'
               else '#ffffff'
               end

    text_color = variant == 'default' ? '#000000' : '#ffffff'
    border = variant == 'default' ? '1px solid #e5e7eb' : 'none'

    b.button(
      disabled: disabled,
      style: {
        padding: '6px 10px',
        border_radius: '8px',
        border: border,
        background: bg_color,
        color: text_color,
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? '0.6' : '1',
        font_size: '14px',
        font_weight: '500'
      },
      on_click: ->(e) {
        return if comp.state[:disabled]
        event = JS.global[:CustomEvent].new(
          'button-click',
          { bubbles: true, composed: true }.to_js
        )
        comp.element.call(:dispatchEvent, event)
      }
    ) { b.text(label) }
  end
end

# =============================================================================
# INPUT COMPONENT
# =============================================================================
ZephyrWasm.component('x-input') do
  observed_attributes :value, :type, :placeholder, :required, :disabled, :error, :label

  on_connect do
    set_state(:value, self['value'] || '')
    set_state(:type, self['type'] || 'text')
    set_state(:error, self['error'])
  end

  template do |b|
    comp = self
    value = comp.state[:value] || ''
    input_type = comp.state[:type] || 'text'
    placeholder = comp['placeholder'] || ''
    disabled = comp.hasAttribute('disabled')
    error = comp.state[:error] || comp['error']
    label_text = comp['label']

    b.div(style: { display: 'block', margin_bottom: error ? '4px' : '12px' }) do
      # Label
      if label_text
        b.tag(:label, style: {
          display: 'block',
          margin_bottom: '4px',
          font_size: '14px',
          font_weight: '500',
          color: '#374151'
        }) { b.text(label_text) }
      end

      # Input
      b.tag(:input,
            type: input_type,
            value: value,
            placeholder: placeholder,
            disabled: disabled,
            style: {
              width: '100%',
              padding: '8px 12px',
              border: error ? '1px solid #ef4444' : '1px solid #e5e7eb',
              border_radius: '6px',
              font_size: '14px',
              outline: 'none',
              background: disabled ? '#f9fafb' : 'white',
              color: disabled ? '#9ca3af' : 'black',
              box_sizing: 'border-box'
            },
            on_input: ->(e) {
              new_value = e[:target][:value].to_s
              comp.set_state(:value, new_value)
              comp['value'] = new_value

              event = JS.global[:CustomEvent].new(
                'input-change',
                { bubbles: true, composed: true, detail: { value: new_value }.to_js }.to_js
              )
              comp.element.call(:dispatchEvent, event)
            }
      )

      # Error message
      if error && !error.empty?
        b.div(style: {
          font_size: '12px',
          color: '#ef4444',
          margin_top: '4px'
        }) { b.text(error) }
      end
    end
  end
end

# =============================================================================
# SELECT COMPONENT
# =============================================================================
ZephyrWasm.component('x-select') do
  observed_attributes :value, :options, :placeholder, :disabled, :label

  on_connect do
    set_state(:value, self['value'] || '')
    set_state(:options, parse_options)
  end

  def parse_options
    options_attr = self['options']
    return [] unless options_attr

    begin
      JSON.parse(options_attr)
    rescue
      []
    end
  end

  template do |b|
    comp = self
    value = comp.state[:value] || ''
    options = comp.state[:options] || []
    placeholder = comp['placeholder']
    disabled = comp.hasAttribute('disabled')
    label_text = comp['label']

    b.div(style: { display: 'block', margin_bottom: '12px' }) do
      # Label
      if label_text
        b.tag(:label, style: {
          display: 'block',
          margin_bottom: '4px',
          font_size: '14px',
          font_weight: '500',
          color: '#374151'
        }) { b.text(label_text) }
      end

      # Select
      b.tag(:select,
            disabled: disabled,
            style: {
              width: '100%',
              padding: '8px 12px',
              border: '1px solid #e5e7eb',
              border_radius: '6px',
              font_size: '14px',
              outline: 'none',
              background: disabled ? '#f9fafb' : 'white',
              color: disabled ? '#9ca3af' : 'black',
              cursor: disabled ? 'not-allowed' : 'pointer',
              box_sizing: 'border-box'
            },
            on_change: ->(e) {
              new_value = e[:target][:value].to_s
              comp.set_state(:value, new_value)
              comp['value'] = new_value

              event = JS.global[:CustomEvent].new(
                'select-change',
                { bubbles: true, composed: true, detail: { value: new_value }.to_js }.to_js
              )
              comp.element.call(:dispatchEvent, event)
            }
      ) do
        # Placeholder option
        if placeholder
          b.tag(:option, value: '', disabled: true, selected: value.empty?) do
            b.text(placeholder)
          end
        end

        # Options
        options.each do |opt|
          opt_value = opt['value'] || opt[:value]
          opt_label = opt['label'] || opt[:label] || opt_value
          b.tag(:option, value: opt_value, selected: opt_value == value) do
            b.text(opt_label)
          end
        end
      end
    end
  end
end

# =============================================================================
# CHECKBOX COMPONENT
# =============================================================================
ZephyrWasm.component('x-checkbox') do
  observed_attributes :checked, :label, :disabled

  on_connect do
    set_state(:checked, self['checked'] == 'true')
  end

  template do |b|
    comp = self
    checked = comp.state[:checked]
    label_text = comp['label'] || ''
    disabled = comp.hasAttribute('disabled')

    b.div(style: {
      display: 'flex',
      align_items: 'center',
      gap: '8px',
      margin_bottom: '12px'
    }) do
      b.tag(:input,
            type: 'checkbox',
            checked: checked,
            disabled: disabled,
            style: {
              width: '16px',
              height: '16px',
              cursor: disabled ? 'not-allowed' : 'pointer'
            },
            on_change: ->(e) {
              new_checked = !!e[:target][:checked]
              comp.set_state(:checked, new_checked)
              comp['checked'] = new_checked.to_s

              event = JS.global[:CustomEvent].new(
                'checkbox-change',
                { bubbles: true, composed: true, detail: { checked: new_checked }.to_js }.to_js
              )
              comp.element.call(:dispatchEvent, event)
            }
      )

      if label_text && !label_text.empty?
        b.tag(:label, style: {
          font_size: '14px',
          color: disabled ? '#9ca3af' : '#374151',
          cursor: disabled ? 'not-allowed' : 'pointer',
          user_select: 'none'
        }) { b.text(label_text) }
      end
    end
  end
end

# =============================================================================
# TEXTAREA COMPONENT
# =============================================================================
ZephyrWasm.component('x-textarea') do
  observed_attributes :value, :placeholder, :rows, :disabled, :label

  on_connect do
    set_state(:value, self['value'] || '')
  end

  template do |b|
    comp = self
    value = comp.state[:value] || ''
    placeholder = comp['placeholder'] || ''
    rows = (comp['rows'] || '3').to_i
    disabled = comp.hasAttribute('disabled')
    label_text = comp['label']

    b.div(style: { display: 'block', margin_bottom: '12px' }) do
      # Label
      if label_text
        b.tag(:label, style: {
          display: 'block',
          margin_bottom: '4px',
          font_size: '14px',
          font_weight: '500',
          color: '#374151'
        }) { b.text(label_text) }
      end

      # Textarea
      b.tag(:textarea,
            placeholder: placeholder,
            disabled: disabled,
            style: {
              width: '100%',
              padding: '8px 12px',
              border: '1px solid #e5e7eb',
              border_radius: '6px',
              font_size: '14px',
              outline: 'none',
              background: disabled ? '#f9fafb' : 'white',
              color: disabled ? '#9ca3af' : 'black',
              font_family: 'inherit',
              resize: 'vertical',
              min_height: "#{rows * 24}px",
              box_sizing: 'border-box'
            },
            on_input: ->(e) {
              new_value = e[:target][:value].to_s
              comp.set_state(:value, new_value)
              comp['value'] = new_value

              event = JS.global[:CustomEvent].new(
                'textarea-change',
                { bubbles: true, composed: true, detail: { value: new_value }.to_js }.to_js
              )
              comp.element.call(:dispatchEvent, event)
            }
      ) { b.text(value) }
    end
  end
end

# =============================================================================
# CARD COMPONENT
# =============================================================================
ZephyrWasm.component('x-card') do
  observed_attributes :variant, :elevated, :bordered

  on_connect do
    set_state(:variant, self['variant'] || 'default')
  end

  template do |b|
    comp = self
    variant = comp.state[:variant] || 'default'
    elevated = comp.hasAttribute('elevated')
    bordered = comp.hasAttribute('bordered')

    border_style = case variant
                   when 'primary' then '2px solid #3b82f6'
                   when 'success' then '2px solid #10b981'
                   when 'warning' then '2px solid #f59e0b'
                   when 'danger' then '2px solid #ef4444'
                   else bordered ? '1px solid #e5e7eb' : 'none'
                   end

    bg_color = case variant
               when 'primary' then '#eff6ff'
               when 'success' then '#ecfdf5'
               when 'warning' then '#fffbeb'
               when 'danger' then '#fef2f2'
               else '#ffffff'
               end

    b.div(style: {
      background: bg_color,
      border: border_style,
      border_radius: '8px',
      padding: '20px',
      box_shadow: elevated ? '0 4px 6px -1px rgba(0, 0, 0, 0.1)' : 'none',
      transition: 'all 0.2s ease'
    }) do
      # Render slotted content
      b.tag(:slot)
    end
  end
end

# =============================================================================
# TABS COMPONENT
# =============================================================================
ZephyrWasm.component('x-tabs') do
  observed_attributes :active

  on_connect do
    set_state(:active, self['active'] || 'tab1')
    set_state(:tabs, [
      { id: 'tab1', label: 'Tab 1', content: 'Content for Tab 1' },
      { id: 'tab2', label: 'Tab 2', content: 'Content for Tab 2' },
      { id: 'tab3', label: 'Tab 3', content: 'Content for Tab 3' }
    ])
  end

  template do |b|
    comp = self
    active = comp.state[:active]
    tabs = comp.state[:tabs] || []

    b.div(style: { display: 'flex', flex_direction: 'column', width: '100%' }) do
      # Tab list
      b.div(
        role: 'tablist',
        style: {
          display: 'flex',
          border_bottom: '1px solid #e5e7eb',
          background: '#f9fafb'
        }
      ) do
        tabs.each do |tab|
          is_active = tab[:id] == active
          b.button(
            role: 'tab',
            style: {
              background: is_active ? 'white' : 'transparent',
              border: 'none',
              border_bottom: is_active ? '2px solid #4f46e5' : '2px solid transparent',
              padding: '12px 16px',
              cursor: 'pointer',
              font_size: '14px',
              font_weight: '500',
              color: is_active ? '#111827' : '#6b7280',
              transition: 'all 0.15s ease'
            },
            on_click: ->(_e) {
              comp.set_state(:active, tab[:id])
              comp['active'] = tab[:id]

              event = JS.global[:CustomEvent].new(
                'tab-change',
                { bubbles: true, composed: true, detail: { tab: tab[:id] }.to_js }.to_js
              )
              comp.element.call(:dispatchEvent, event)
            }
          ) { b.text(tab[:label]) }
        end
      end

      # Tab content
      b.div(style: { padding: '20px', background: 'white' }) do
        active_tab = tabs.find { |t| t[:id] == active }
        if active_tab
          b.div { b.text(active_tab[:content]) }
        end
      end
    end
  end
end

# =============================================================================
# ACCORDION COMPONENT
# =============================================================================
ZephyrWasm.component('x-accordion') do
  observed_attributes :expanded

  on_connect do
    set_state(:expanded, (self['expanded'] || '').split(',').map(&:strip))
    set_state(:sections, [
      { id: 'section1', title: 'Section 1', content: 'Content for section 1' },
      { id: 'section2', title: 'Section 2', content: 'Content for section 2' },
      { id: 'section3', title: 'Section 3', content: 'Content for section 3' }
    ])
  end

  template do |b|
    comp = self
    expanded = comp.state[:expanded] || []
    sections = comp.state[:sections] || []

    b.div(style: {
      border: '1px solid #e5e7eb',
      border_radius: '8px',
      overflow: 'hidden'
    }) do
      sections.each_with_index do |section, index|
        is_expanded = expanded.include?(section[:id])

        # Header
        b.button(
          style: {
            width: '100%',
            background: is_expanded ? 'white' : '#f9fafb',
            border: 'none',
            border_bottom: index < sections.length - 1 ? '1px solid #e5e7eb' : 'none',
            padding: '16px 20px',
            text_align: 'left',
            cursor: 'pointer',
            font_size: '14px',
            font_weight: '500',
            display: 'flex',
            justify_content: 'space-between',
            align_items: 'center',
            transition: 'background 0.15s ease'
          },
          on_click: ->(_e) {
            new_expanded = expanded.dup
            if is_expanded
              new_expanded.delete(section[:id])
            else
              new_expanded << section[:id]
            end
            comp.set_state(:expanded, new_expanded)
            comp['expanded'] = new_expanded.join(',')
          }
        ) do
          b.span { b.text(section[:title]) }
          b.span(style: {
            transform: is_expanded ? 'rotate(180deg)' : 'rotate(0deg)',
            transition: 'transform 0.2s ease'
          }) { b.text('▼') }
        end

        # Content
        if is_expanded
          b.div(style: {
            padding: '20px',
            border_bottom: index < sections.length - 1 ? '1px solid #e5e7eb' : 'none'
          }) { b.text(section[:content]) }
        end
      end
    end
  end
end

# =============================================================================
# DIALOG/MODAL COMPONENT
# =============================================================================
ZephyrWasm.component('x-dialog') do
  observed_attributes :open, :title

  on_connect do
    set_state(:open, self['open'] == 'true')
  end

  template do |b|
    comp = self
    is_open = comp.state[:open]
    title = comp['title'] || 'Dialog'

    if is_open
      # Backdrop
      b.div(
        style: {
          position: 'fixed',
          top: '0',
          left: '0',
          right: '0',
          bottom: '0',
          background: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          align_items: 'center',
          justify_content: 'center',
          z_index: '1000'
        },
        on_click: ->(e) {
          if e[:target] == e[:currentTarget]
            comp.set_state(:open, false)
            comp['open'] = 'false'
          end
        }
      ) do
        # Dialog
        b.div(
          role: 'dialog',
          style: {
            background: 'white',
            border_radius: '8px',
            box_shadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
            max_width: '90vw',
            max_height: '90vh',
            width: '600px',
            display: 'flex',
            flex_direction: 'column'
          },
          on_click: ->(e) { e.call(:stopPropagation) }
        ) do
          # Header
          b.div(style: {
            padding: '16px 20px',
            border_bottom: '1px solid #e5e7eb',
            display: 'flex',
            justify_content: 'space-between',
            align_items: 'center'
          }) do
            b.tag(:h2, style: {
              margin: '0',
              font_size: '18px',
              font_weight: '600'
            }) { b.text(title) }

            b.button(
              style: {
                background: 'none',
                border: 'none',
                font_size: '18px',
                cursor: 'pointer',
                padding: '4px',
                border_radius: '4px'
              },
              on_click: ->(_e) {
                comp.set_state(:open, false)
                comp['open'] = 'false'
              }
            ) { b.text('×') }
          end

          # Content
          b.div(style: {
            padding: '20px',
            overflow_y: 'auto',
            flex: '1'
          }) do
            b.tag(:slot)
          end
        end
      end
    end
  end
end

# =============================================================================
# BREADCRUMB COMPONENT
# =============================================================================
ZephyrWasm.component('x-breadcrumb') do
  observed_attributes :path

  on_connect do
    set_state(:items, parse_path)
  end

  def parse_path
    path_attr = self['path']
    return [] unless path_attr

    begin
      JSON.parse(path_attr)
    rescue
      path_attr.split(',').map { |item| { label: item.strip } }
    end
  end

  template do |b|
    comp = self
    items = comp.state[:items] || []

    b.tag(:nav, style: { padding: '8px 0' }) do
      b.tag(:ol, style: {
        display: 'flex',
        align_items: 'center',
        list_style: 'none',
        margin: '0',
        padding: '0',
        gap: '8px'
      }) do
        items.each_with_index do |item, index|
          is_last = index == items.length - 1

          b.tag(:li, style: {
            display: 'flex',
            align_items: 'center',
            gap: '8px'
          }) do
            if item['href'] && !is_last
              b.tag(:a,
                    href: item['href'],
                    style: {
                      color: '#4f46e5',
                      text_decoration: 'none',
                      padding: '4px 8px',
                      border_radius: '4px'
                    }
              ) { b.text(item['label'] || item[:label]) }
            else
              b.span(style: {
                color: is_last ? '#374151' : '#6b7280',
                font_weight: is_last ? '500' : '400',
                padding: '4px 8px'
              }) { b.text(item['label'] || item[:label]) }
            end

            unless is_last
              b.span(style: { color: '#9ca3af' }) { b.text('/') }
            end
          end
        end
      end
    end
  end
end

# =============================================================================
# VIRTUAL LIST COMPONENT (Simplified)
# =============================================================================
ZephyrWasm.component('x-virtual-list') do
  observed_attributes 'item-count', 'item-height'

  on_connect do
    item_count = (self['item-count'] || '0').to_i
    item_height = (self['item-height'] || '24').to_i

    set_state(:item_count, item_count)
    set_state(:item_height, item_height)
    set_state(:scroll_top, 0)
  end

  template do |b|
    comp = self
    item_count = comp.state[:item_count] || 0
    item_height = comp.state[:item_height] || 24
    scroll_top = comp.state[:scroll_top] || 0

    viewport_height = 400
    start_index = [0, (scroll_top / item_height).floor - 3].max
    visible_count = [(viewport_height / item_height).ceil + 6, item_count - start_index].min

    b.div(
      style: {
        overflow: 'auto',
        height: '400px',
        position: 'relative'
      },
      on_scroll: ->(e) {
        comp.set_state(:scroll_top, e[:target][:scrollTop].to_i)
      }
    ) do
      b.div(style: {
        height: "#{item_count * item_height}px",
        position: 'relative'
      }) do
        visible_count.times do |i|
          index = start_index + i
          break if index >= item_count

          b.div(style: {
            position: 'absolute',
            top: "#{index * item_height}px",
            left: '0',
            right: '0',
            height: "#{item_height}px",
            padding: '8px',
            border_bottom: '1px solid #eee',
            background: index % 2 == 0 ? '#f9f9f9' : 'white'
          }) { b.text("Item #{index}") }
        end
      end
    end
  end
end

# Counter component - demonstrates state management
ZephyrWasm.component('x-counter') do
  observed_attributes :initial

  on_connect do
    count = (self['initial'] || '0').to_i
    set_state(:count, count)
  end

  template do |b|
    comp = self

    b.div(class: 'counter-container') do
      b.button(
        class: 'btn btn-decrement',
        on_click: ->(_e) {
          current = comp.state[:count] || 0
          comp.set_state(:count, current - 1)
        }
      ) { b.text('-') }

      b.span(class: 'counter-value') { b.text(comp.state[:count] || 0) }

      b.button(
        class: 'btn btn-increment',
        on_click: ->(_e) {
          current = comp.state[:count] || 0
          comp.set_state(:count, current + 1)
        }
      ) { b.text('+') }
    end
  end
end

# Toggle button component
ZephyrWasm.component('x-toggle') do
  observed_attributes :label, :checked

  on_connect do
    set_state(:checked, self['checked'] == 'true')
  end

  template do |b|
    comp = self
    btn_class  = comp.state[:checked] ? 'toggle active' : 'toggle'
    label_text = comp['label'] || 'Toggle'

    b.div(class: 'toggle-wrapper') do
      b.button(
        class: btn_class,
        on_click: ->(_e) {
          new_state = !comp.state[:checked]
          comp.set_state(:checked, new_state)
          comp['checked'] = new_state.to_s

          event = JS.global[:CustomEvent].new(
            'toggle-change',
            { bubbles: true, detail: { checked: new_state }.to_js }.to_js
          )
          comp.element.call(:dispatchEvent, event)
        }
      ) { b.text(label_text) }
    end
  end
end

# Todo list component - demonstrates list rendering
ZephyrWasm.component('x-todo-list') do
  on_connect do
    set_state(:todos, [])
    set_state(:input_value, '')
  end

  template do |b|
    comp = self

    b.div(class: 'todo-list') do
      b.div(class: 'todo-input-group') do
        b.tag(:input,
              type: 'text',
              placeholder: 'Enter a task...',
              value: comp.state[:input_value] || '',
              on_input: ->(e) {
                comp.set_state(:input_value, e[:target][:value].to_s)
              }
        )

        b.button(
          class: 'btn btn-primary',
          on_click: ->(_e) {
            value = comp.state[:input_value]&.strip
            if value && !value.empty?
              todos = (comp.state[:todos] || []).dup
              todos << { id: JS.global[:Date].new.call(:getTime), text: value, done: false }
              comp.set_state(:todos, todos)
              comp.set_state(:input_value, '')
            end
          }
        ) { b.text('Add') }
      end

      b.tag(:ul, class: 'todo-items') do
        todos = comp.state[:todos] || []
        b.render_each(todos) do |todo|
          b.tag(:li, class: todo[:done] ? 'done' : '') do
            b.tag(:input,
                  type: 'checkbox',
                  checked: !!todo[:done],
                  on_change: ->(e) {
                    todos = (comp.state[:todos] || []).map { |t|
                      if t[:id] == todo[:id]
                        { **t, done: !!e[:target][:checked] }
                      else
                        t
                      end
                    }
                    comp.set_state(:todos, todos)
                  }
            )
            b.span { b.text(todo[:text]) }
            b.button(
              class: 'btn-delete',
              on_click: ->(_e) {
                todos = (comp.state[:todos] || []).reject { |t| t[:id] == todo[:id] }
                comp.set_state(:todos, todos)
              }
            ) { b.text('×') }
          end
        end
      end
    end
  end
end

# Tabs component - demonstrates more complex UI
ZephyrWasm.component('x-tabs') do
  observed_attributes :active

  on_connect do
    set_state(:active, self['active'] || 'tab1')
    set_state(:tabs, [
      { id: 'tab1', label: 'Tab 1', content: 'Content 1' },
      { id: 'tab2', label: 'Tab 2', content: 'Content 2' },
      { id: 'tab3', label: 'Tab 3', content: 'Content 3' }
    ])
  end

  template do |b|
    comp = self

    b.div(class: 'tabs-container') do
      # Tab list
      b.div(class: 'tab-list', role: 'tablist') do
        tabs   = comp.state[:tabs] || []
        active = comp.state[:active]
        b.render_each(tabs) do |tab|
          b.button(
            class: tab[:id] == active ? 'tab-button active' : 'tab-button',
            role: 'tab',
            on_click: ->(_e) {
              comp.set_state(:active, tab[:id])
              comp['active'] = tab[:id]
            }
          ) { b.text(tab[:label]) }
        end
      end

      # Tab content
      b.div(class: 'tab-content') do
        tabs = comp.state[:tabs] || []
        active_tab = tabs.find { |t| t[:id] == comp.state[:active] }
        if active_tab
          b.div(class: 'tab-panel') { b.text(active_tab[:content]) }
        end
      end
    end
  end
end