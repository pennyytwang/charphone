(function () {
    'use strict';

    var ALLOWED_TAGS = [
        'a', 'blockquote', 'br', 'code', 'del', 'em', 'h1', 'h2', 'h3', 'h4',
        'h5', 'h6', 'hr', 'li', 'ol', 'p', 'pre', 'strong', 'table', 'tbody',
        'td', 'th', 'thead', 'tr', 'ul'
    ];
    var ALLOWED_ATTR = ['href', 'title'];
    var ALLOWED_URI_REGEXP = /^(?:(?:https?|mailto):|\/(?!\/)|#)/i;

    function fallback(el, text) {
        if (!el) {
            return;
        }
        el.classList.remove('md-body');
        el.textContent = text == null ? '' : String(text);
    }

    function wrapTables(html) {
        if (!window.DOMParser) {
            return html;
        }
        var doc = new window.DOMParser().parseFromString('<div>' + html + '</div>', 'text/html');
        var root = doc.body.firstChild;
        if (!root) {
            return html;
        }
        var tables = root.querySelectorAll('table');
        for (var i = 0; i < tables.length; i++) {
            var table = tables[i];
            var wrap = doc.createElement('div');
            wrap.className = 'md-table-wrap';
            table.parentNode.insertBefore(wrap, table);
            wrap.appendChild(table);
        }
        var links = root.querySelectorAll('a[href]');
        for (var j = 0; j < links.length; j++) {
            links[j].setAttribute('target', '_blank');
            links[j].setAttribute('rel', 'noopener noreferrer');
        }
        return root.innerHTML;
    }

    function render(text) {
        var source = text == null ? '' : String(text);
        if (!window.marked || typeof window.marked.parse !== 'function' || !window.DOMPurify) {
            return null;
        }
        var html;
        try {
            html = window.marked.parse(source, {
                gfm: true,
                breaks: true,
                pedantic: false,
                silent: false
            });
        } catch (e) {
            return null;
        }
        var clean;
        try {
            clean = window.DOMPurify.sanitize(html, {
                ALLOWED_TAGS: ALLOWED_TAGS,
                ALLOWED_ATTR: ALLOWED_ATTR,
                ALLOW_DATA_ATTR: false,
                FORBID_ATTR: ['style'],
                ALLOWED_URI_REGEXP: ALLOWED_URI_REGEXP
            });
        } catch (e) {
            return null;
        }
        return wrapTables(clean);
    }

    function renderInto(el, text) {
        if (!el) {
            return;
        }
        var html = render(text);
        if (html == null) {
            fallback(el, text);
            return;
        }
        el.classList.add('md-body');
        el.innerHTML = html;
    }

    window.CharPhoneAiFormat = {
        render: render,
        renderInto: renderInto
    };
})();
