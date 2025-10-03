// zephyr-bridge.js
(() => {
    const defined = new Set();
    const pending = new Map();
    let scheduled = false;

    function defineOne(tag, meta) {
        if (!tag || customElements.get(tag) || defined.has(tag)) return;

        class RubyBackedElement extends HTMLElement {
            static get observedAttributes() {
                return (meta && meta.observedAttributes) || [];
            }
            connectedCallback() {
                // Safe: this runs in a clean JS task after our scheduler fires
                window.ZephyrWasm?.initComponent?.(this, tag);
            }
            disconnectedCallback() {
                window.ZephyrWasm?.disconnectComponent?.(this);
            }
            attributeChangedCallback(name, oldValue, newValue) {
                window.ZephyrWasm?.attributeChangedComponent?.(this, name, oldValue, newValue);
            }
        }

        customElements.define(tag, RubyBackedElement);
        defined.add(tag);
        window.log?.(`✅ Registered component: ${tag}`);
    }

    function flush() {
        scheduled = false;
        for (const [tag, meta] of pending) defineOne(tag, meta);
        pending.clear();
        // Optional: reveal content area if you hide UI while loading
        const loading = document.getElementById('loading');
        const content = document.getElementById('content');
        if (loading && content) {
            loading.style.display = 'none';
            content.style.display = 'block';
            window.log?.('🎉 Zephyr WASM is ready!');
        }
    }

    function scheduleDefine(tag, meta) {
        pending.set(tag, meta);
        if (!scheduled) {
            scheduled = true;
            // Use a macrotask (setTimeout) to ensure Ruby has fully unwound
            setTimeout(flush, 0);
        }
    }

    // Wrap ZephyrWasmRegistry so Ruby writes schedule a later define
    const existing = window.ZephyrWasmRegistry || {};
    const proxy = new Proxy(existing, {
        set(target, prop, value) {
            target[prop] = value;
            scheduleDefine(prop, value);
            return true;
        }
    });
    window.ZephyrWasmRegistry = proxy;

    // If Ruby populated entries before this script loaded, schedule them now
    for (const [tag, meta] of Object.entries(existing)) {
        scheduleDefine(tag, meta);
    }
})();
