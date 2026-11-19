// CharPhone common utilities

var CP_CSRF_TOKEN = '';

function isReadOnlyMode() {
    return !!(document.body && document.body.classList.contains('readonly-mode'));
}

function postAction(url) {
    if (isReadOnlyMode()) {
        showToast('\u552F\u8B80\u5C55\u793A\u6A21\u5F0F\u7121\u6CD5\u57F7\u884C\u6B64\u64CD\u4F5C', 'error');
        return false;
    }
    var u;
    try {
        u = new URL(url, window.location.href);
    } catch (e) {
        return false;
    }
    if (u.origin !== window.location.origin) return false;
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = u.pathname;
    form.style.display = 'none';
    u.searchParams.forEach(function(value, key) {
        var input = document.createElement('input');
        input.type = 'hidden';
        input.name = key;
        input.value = value;
        form.appendChild(input);
    });
    if (CP_CSRF_TOKEN) {
        var csrf = document.createElement('input');
        csrf.type = 'hidden';
        csrf.name = '_csrf';
        csrf.value = CP_CSRF_TOKEN;
        form.appendChild(csrf);
    }
    document.body.appendChild(form);
    form.submit();
    return true;
}

(function initCsrf() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    var token = meta ? meta.getAttribute('content') : '';
    if (!token) return;
    CP_CSRF_TOKEN = token;

    function isSafeMethod(method) {
        var m = (method || 'GET').toUpperCase();
        return m === 'GET' || m === 'HEAD' || m === 'OPTIONS';
    }

    function appendToBody(body) {
        if (body instanceof FormData) {
            if (!body.has('_csrf')) body.append('_csrf', token);
        } else if (body instanceof URLSearchParams) {
            if (!body.has('_csrf')) body.append('_csrf', token);
        }
    }

    function injectForms() {
        document.querySelectorAll('form').forEach(function(form) {
            var method = (form.getAttribute('method') || 'GET').toUpperCase();
            if (isSafeMethod(method)) return;
            if (form.querySelector('input[name="_csrf"]')) return;
            var input = document.createElement('input');
            input.type = 'hidden';
            input.name = '_csrf';
            input.value = token;
            form.appendChild(input);
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', injectForms);
    } else {
        injectForms();
    }
    var observer = new MutationObserver(injectForms);
    observer.observe(document.documentElement, { childList: true, subtree: true });

    var stateChangingAction = /[?&]action=(delete|close|unclose|cancel|pause|restore|reverse)(&|$)/i;
    document.addEventListener('click', function(e) {
        if (e.defaultPrevented || e.returnValue === false) return;
        var anchor = e.target && e.target.closest ? e.target.closest('a[href]') : null;
        if (!anchor) return;
        if (anchor.hasAttribute('download') || (anchor.target && anchor.target !== '_self')) return;
        var href = anchor.getAttribute('href');
        if (!href || href.charAt(0) === '#') return;
        var url;
        try {
            url = new URL(href, window.location.href);
        } catch (err) {
            return;
        }
        if (url.origin !== window.location.origin) return;
        if (!stateChangingAction.test(url.search)) return;
        e.preventDefault();
        postAction(url.href);
    });

    var originalFetch = window.fetch;
    if (originalFetch) {
        window.fetch = function(input, init) {
            init = init || {};
            var method = init.method || (input && input.method) || 'GET';
            if (!isSafeMethod(method)) {
                var headers = new Headers(init.headers || (input instanceof Request ? input.headers : undefined));
                headers.set('X-CSRF-Token', token);
                init.headers = headers;
                appendToBody(init.body);
            }
            return originalFetch.call(this, input, init);
        };
    }

    if (window.XMLHttpRequest) {
        var originalOpen = XMLHttpRequest.prototype.open;
        var originalSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method) {
            this.__csrfMethod = method;
            return originalOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function(body) {
            if (!isSafeMethod(this.__csrfMethod)) {
                try { this.setRequestHeader('X-CSRF-Token', token); } catch (e) {}
                appendToBody(body);
            }
            return originalSend.apply(this, arguments);
        };
    }
})();

(function initReadOnlyGuard() {
    var writeAction = /open(Add|Edit|Payment|Reverse)/i;
    var writeHref = /(?:\/|^)(add_|edit_)|[?&]action=(?:delete|close|unclose|cancel|pause|restore|reverse)(?:&|$)/i;

    function block(e) {
        if (!isReadOnlyMode()) return;
        var el = e.target && e.target.closest ? e.target.closest('a,button,[onclick]') : null;
        if (!el) return;
        var onclick = el.getAttribute('onclick') || '';
        var href = el.getAttribute('href') || '';
        if (!writeAction.test(onclick) && !writeHref.test(href) && !el.hasAttribute('data-write')) return;
        e.preventDefault();
        e.stopPropagation();
        showToast('\u552F\u8B80\u5C55\u793A\u6A21\u5F0F\u7121\u6CD5\u57F7\u884C\u6B64\u64CD\u4F5C', 'error');
    }

    document.addEventListener('click', block, true);
    document.addEventListener('submit', function(e) {
        if (!isReadOnlyMode()) return;
        var method = (e.target.getAttribute && e.target.getAttribute('method') || 'GET').toUpperCase();
        if (method === 'GET') return;
        e.preventDefault();
        e.stopPropagation();
        showToast('\u552F\u8B80\u5C55\u793A\u6A21\u5F0F\u7121\u6CD5\u57F7\u884C\u6B64\u64CD\u4F5C', 'error');
    }, true);
})();

function showToast(msg, type) {
    type = type || 'success';
    var toast = document.createElement('div');
    toast.className = 'toast toast-' + type;
    toast.textContent = msg;
    document.body.appendChild(toast);
    requestAnimationFrame(function() { toast.classList.add('toast-show'); });
    setTimeout(function() {
        toast.classList.remove('toast-show');
        setTimeout(function() { toast.remove(); }, 400);
    }, 3000);
}

(function initCommonUI() {
    function onReady(fn) {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', fn);
        } else {
            fn();
        }
    }

    function initTableScrollHint() {
        function checkScroll() {
            document.querySelectorAll('.table-container').forEach(function(el) {
                var canScroll = el.scrollWidth > el.clientWidth + 2;
                el.classList.toggle('has-scroll', canScroll);
                if (canScroll) {
                    var atEnd = el.scrollLeft + el.clientWidth >= el.scrollWidth - 2;
                    el.classList.toggle('scrolled-end', atEnd);
                }
            });
        }
        window.addEventListener('load', checkScroll);
        window.addEventListener('resize', checkScroll);
        document.addEventListener('scroll', checkScroll, true);
        var observer = new MutationObserver(checkScroll);
        observer.observe(document.body, { childList: true, subtree: true });
        checkScroll();
    }

    function initFilterCollapse() {
        document.querySelectorAll('.filter-bar').forEach(function(form) {
            if (form.parentElement && form.parentElement.classList.contains('filter-collapse-inner')) return;
            var wrapper = document.createElement('div');
            wrapper.className = 'filter-wrapper collapsed';
            var toggle = document.createElement('button');
            toggle.type = 'button';
            toggle.className = 'filter-toggle';
            toggle.setAttribute('aria-expanded', 'false');
            var text = document.createElement('span');
            text.className = 'filter-toggle-text';
            text.textContent = '\u7BE9\u9078\u689D\u4EF6';
            var state = document.createElement('span');
            state.className = 'filter-toggle-state';
            var arrow = document.createElement('span');
            arrow.className = 'filter-toggle-arrow';
            arrow.setAttribute('aria-hidden', 'true');
            toggle.appendChild(text);
            toggle.appendChild(state);
            toggle.appendChild(arrow);
            var collapse = document.createElement('div');
            collapse.className = 'filter-collapse';
            var inner = document.createElement('div');
            inner.className = 'filter-collapse-inner';
            collapse.appendChild(inner);
            wrapper.appendChild(toggle);
            wrapper.appendChild(collapse);
            form.parentNode.insertBefore(wrapper, form);
            inner.appendChild(form);
            toggle.addEventListener('click', function() {
                var collapsed = wrapper.classList.toggle('collapsed');
                toggle.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
            });
        });
    }

    onReady(function() {
        try { initTableScrollHint(); } catch (e) { console.error('initTableScrollHint failed:', e); }
        try { initFilterCollapse(); } catch (e) { console.error('initFilterCollapse failed:', e); }
    });
})();