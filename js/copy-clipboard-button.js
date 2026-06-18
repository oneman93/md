/**
 * Add "Copy Password" buttons next to every <pre> that contains 'Password' text.
 * When a <pre> has multiple Password lines, '--Password' is ignored and the first 'Password:' value is copied.
 * @param {HTMLElement} app - The zero-md element (used to read app.src)
 */
console.log('[BannerCopy] copy-clipboard-button.js loaded');

function addBannerCredentialCopyButtons(app) {
    console.log('[BannerCopy] addBannerCredentialCopyButtons called', { app: !!app, src: app ? app.src : 'N/A' });

    if (!app || !app.src) {
        console.log('[BannerCopy] Early exit: app or app.src missing');
        return;
    }

    var container = document.getElementById('mdcontainer');
    if (!container) {
        console.log('[BannerCopy] Early exit: #mdcontainer not found');
        return;
    }
    console.log('[BannerCopy] Container found, children:', container.children.length, container.innerHTML.substring(0, 200) + '...');

    /**
     * Extract the first real password from pre text for copying. Ignores lines starting with '--Password:'.
     * Returns the value after the first 'Password:' (no leading '--').
     */
    function extractPasswordFromPre(text) {
        var lines = (text || '').split(/\r?\n/);
        for (var j = 0; j < lines.length; j++) {
            var line = lines[j].trim();
            // Ignore --Password lines; use only the first Password: line
            if (/^--\s*Password:\s*/i.test(line)) continue;
            if (/^Password:\s*/i.test(line)) {
                var value = line.replace(/^Password:\s*/i, '').trim();
                if (value.length > 0) return value;
                if (j + 1 < lines.length) {
                    value = lines[j + 1].trim();
                    if (value.length > 0) return value;
                }
            }
        }
        return '';
    }

    /**
     * Extract ALL password values to blur (including --Password: lines).
     */
    function extractAllPasswordValuesToBlur(text) {
        var values = [];
        var lines = (text || '').split(/\r?\n/);
        for (var j = 0; j < lines.length; j++) {
            var line = lines[j].trim();
            var match = line.match(/^(?:--\s*)?Password:\s*(.+)/i);
            if (match && match[1].trim().length > 0) {
                values.push(match[1].trim());
            }
        }
        return values;
    }

    function showCopiedForTwoSec(btn, originalLabel) {
        btn.textContent = 'Copied!';
        setTimeout(function () {
            btn.textContent = originalLabel;
        }, 2000);
    }

    function makeCopyButton(label, password) {
        var btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'btn btn-sm btn-secondary btn-banner-copy';
        btn.textContent = label;
        btn.style.marginLeft = '8px';
        btn.style.marginTop = '6px';
        btn.addEventListener('click', function () {
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(password).then(function () {
                    showCopiedForTwoSec(btn, label);
                }).catch(function () {
                    fallbackCopy(password, btn, label);
                });
            } else {
                fallbackCopy(password, btn, label);
            }
        });
        return btn;
    }

    /**
     * Blur all given password values inside a <pre> element.
     * Uses textContent + innerHTML rebuild to handle PrismJS-split text nodes.
     */
    function blurAllPasswordsInPre(preEl, passwords) {
        if (!passwords || passwords.length === 0 || !preEl) return;
        var codeEl = preEl.querySelector('code') || preEl;
        var plainText = codeEl.textContent;

        var hasMatch = passwords.some(function(p) { return plainText.indexOf(p) >= 0; });
        if (!hasMatch) return;

        function escHtml(s) {
            return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        }

        // Rebuild from plain text (strips PrismJS highlighting, acceptable for credential blocks)
        var result = escHtml(plainText);
        passwords.forEach(function(password) {
            var escapedPwd = escHtml(password);
            var re = new RegExp(escapedPwd.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');
            result = result.replace(re, '<span class="password-blur">' + escapedPwd + '</span>');
        });
        codeEl.innerHTML = result;

        // Add eye toggle icons next to each blurred password span
        codeEl.querySelectorAll('.password-blur').forEach(function(span) {
            var eye = document.createElement('span');
            eye.className = 'password-eye-toggle';
            eye.title = 'Show password';
            eye.innerHTML = '<i class="fas fa-eye"></i>';
            eye.style.cssText = 'cursor:pointer;margin-left:4px;color:#888;vertical-align:middle;';
            eye.addEventListener('click', function() {
                var isBlurred = span.classList.contains('password-blur');
                if (isBlurred) {
                    span.classList.remove('password-blur');
                    eye.innerHTML = '<i class="fas fa-eye-slash"></i>';
                    eye.title = 'Hide password';
                } else {
                    span.classList.add('password-blur');
                    eye.innerHTML = '<i class="fas fa-eye"></i>';
                    eye.title = 'Show password';
                }
            });
            span.parentNode.insertBefore(eye, span.nextSibling);
        });
    }

    function fallbackCopy(text, btn, originalLabel) {
        try {
            var ta = document.createElement('textarea');
            ta.value = text;
            ta.style.position = 'fixed';
            ta.style.left = '-9999px';
            document.body.appendChild(ta);
            ta.select();
            document.execCommand('copy');
            document.body.removeChild(ta);
            showCopiedForTwoSec(btn, originalLabel);
        } catch (e) {
            console.warn('Copy failed', e);
        }
    }

    // Prefer pre inside markdown body; fallback to any pre in container
    var root = container.querySelector('.markdown-body') || container;
    var preElements = root.querySelectorAll('pre');
    console.log('[BannerCopy] pre elements count:', preElements.length);

    function insertButtonAfter(el, btn) {
        if (el.parentNode) {
            el.parentNode.insertBefore(btn, el.nextSibling);
        }
    }

    for (var i = 0; i < preElements.length; i++) {
        var pre = preElements[i];
        var text = (pre.textContent || '').trim();
        if (text.length > 0 && /Password/i.test(text)) {
            var password = extractPasswordFromPre(text);
            if (password) {
                var btn = makeCopyButton('Copy Password', password);
                var wrapper = pre.closest('.copy-code-wrapper');
                var btnContainer = wrapper ? wrapper.querySelector('.copy-code-btns') : null;
                if (btnContainer) {
                    btnContainer.appendChild(btn);
                    console.log('[BannerCopy] Added Copy Password into .copy-code-btns for pre[' + i + ']');
                } else {
                    insertButtonAfter(pre, btn);
                    console.log('[BannerCopy] Fallback: Added Copy Password after pre[' + i + ']');
                }
                // Blur ALL password values (including --Password: lines) in one pass
                blurAllPasswordsInPre(pre, extractAllPasswordValuesToBlur(text));
            }
        }
    }
    console.log('[BannerCopy] Done.');
}
