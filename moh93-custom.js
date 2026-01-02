// Production-specific custom functions for md.htm
// This file contains functions needed for production URLs that may have complex query parameters

/**
 * Gets a query parameter value including everything after the parameter name.
 * This function extracts everything after "key=" to handle URLs with nested query parameters,
 * such as when the parameter value itself is a URL with query parameters (e.g., AWS signed URLs).
 * 
 * Example URLs and return values:
 * - URL: "?src=https://example.com/page.md"
 *   Returns: "https://example.com/page.md"
 * 
 * - URL: "?src=https://example.com/page.md&other=value"
 *   Returns: "https://example.com/page.md&other=value"
 * 
 * - URL: "?src=https://s3.amazonaws.com/bucket/file.md?AWSAccessKeyId=123&Signature=abc&Expires=456"
 *   Returns: "https://s3.amazonaws.com/bucket/file.md?AWSAccessKeyId=123&Signature=abc&Expires=456"
 * 
 * - URL: "?src=https%3A%2F%2Fexample.com%2Fpage.md" (URL-encoded)
 *   Returns: "https://example.com/page.md" (decoded)
 * 
 * @param {string} key - The query parameter key (typically "src")
 * @returns {string} The decoded value of the query parameter, including any trailing query parameters
 */
function getQueryParamSuffix(key) {
    var query = window.location.search.substring(1);
    var index = query.indexOf(key);
    var paramString = query.substring(index, query.length);
    // Remove the key and equals sign (e.g., "src=" or "key=")
    paramString = paramString.replace(key + "=", "");
    
    // Decode the URL-encoded string
    try {
        paramString = decodeURIComponent(paramString);
    } catch (e) {
        // If decoding fails, use the original string
        console.log('Failed to decode paramString:', e);
    }
    
    console.log('paramString', paramString);

    return paramString;
}

/**
 * Extracts the current document's S3 key from app.src URL.
 * This function parses the app.src URL to extract the key parameter, which represents
 * the S3 key of the currently loaded markdown document.
 * 
 * @param {string|object} appSrc - The app.src value (URL string) or app object with src property
 * @returns {string} The current document's S3 key (e.g., "_LoadingDocuments/andys-loading.md") or empty string if not found
 */
function getCurrentDocumentKey(appSrc) {
    try {
        // Handle both string and object inputs
        var srcValue = typeof appSrc === 'string' ? appSrc : (appSrc && appSrc.src ? appSrc.src : '');
        
        if (!srcValue) {
            return '';
        }
        
        var currentDocKey = '';
        
        // Try to extract key parameter from app.src URL using regex
        var keyMatch = srcValue.match(/[?&]key=([^&]+)/);
        if (keyMatch) {
            currentDocKey = decodeURIComponent(keyMatch[1]);
        } else {
            // Fallback: try using URL object
            try {
                var currentSrcUrl = new URL(srcValue);
                if (currentSrcUrl.searchParams.has('key')) {
                    currentDocKey = currentSrcUrl.searchParams.get('key');
                }
            } catch (urlError) {
                // If URL parsing fails, app.src might be a relative path
                console.log('app.src is not a full URL, treating as relative path');
            }
        }
        
        return currentDocKey;
    } catch (e) {
        console.log('Could not extract current document key:', e);
        return '';
    }
}

/**
 * Ensure wrapWithMdHtml is always enabled for moh93 project
 * This ensures all hyperlinks use the src parameter format (wrapped with md.htm)
 */
(function() {
    // Set localStorage flag immediately when script loads (for moh93 project)
    // This ensures wrapWithMdHtml() will be called when md.htm initializes
    // The variable window._isMoh93Project is set in md.htm head section before this script loads
    if (window._isMoh93Project) {
        var _isWrapped = "ls-is-wrapper";
        // Always set localStorage to enable wrapping for moh93 project
        localStorage.setItem(_isWrapped, '1');
    }
})();

/**
 * Resolves relative path indicators (./ and ../) based on the current document's key.
 * This function is used to correctly construct S3 keys for hyperlinks based on the current document's location.
 * 
 * Handles ./ pattern: Removes ./ and uses the path as-is (relative to current directory).
 * - If path already starts with _LoadingDocuments, use as-is
 * - Otherwise, if current key has a baseDir, prepend it (unless we're at root)
 * 
 * Handles ../ pattern: Goes up one directory level from the current key.
 * Examples:
 * - If current key is _LoadingDocuments/andys-loading.md and link is ../work-index.md, the result is work-index.md (root level)
 * - If current key is _LoadingDocuments/xxx/andys-loading.md and link is ../other.md, it goes to _LoadingDocuments/other.md
 * 
 * For paths without relative indicators: Prepends base directory if we're in a subdirectory.
 * 
 * @param {string} path - The path to resolve (may contain ./ or ../)
 * @param {string} currentKey - The current document's S3 key (e.g., "_LoadingDocuments/andys-loading.md")
 * @returns {string} The resolved path (S3 key)
 */
function resolveRelativePath(path, currentKey) {
    var resolved = path;
    var currentBaseDir = '';
    
    // Determine current base directory from currentKey
    if (currentKey) {
        var lastSlashIndex = currentKey.lastIndexOf('/');
        if (lastSlashIndex >= 0) {
            currentBaseDir = currentKey.substring(0, lastSlashIndex + 1);
        }
    }
    
    // Handle ./ pattern - remove ./ and use path as-is (relative to current directory)
    if (resolved.startsWith('./')) {
        resolved = resolved.substring(2);
        // If path already starts with _LoadingDocuments, use as-is
        // Otherwise, if current key has a baseDir, prepend it (unless we're at root)
        if (!resolved.startsWith('_LoadingDocuments') && currentBaseDir && !resolved.startsWith(currentBaseDir)) {
            resolved = currentBaseDir + resolved;
        }
    }
    // Handle ../ pattern - go up one directory level from current key
    else if (resolved.startsWith('../')) {
        resolved = resolved.substring(3); // Remove ../
        // If current key has a directory, go up one level
        if (currentKey) {
            var lastSlashIndex = currentKey.lastIndexOf('/');
            if (lastSlashIndex > 0) {
                // Current key has directory, get parent directory
                var parentDir = currentKey.substring(0, lastSlashIndex);
                var grandparentSlashIndex = parentDir.lastIndexOf('/');
                if (grandparentSlashIndex >= 0) {
                    // There's a grandparent directory
                    resolved = parentDir.substring(0, grandparentSlashIndex + 1) + resolved;
                } else {
                    // Parent is at root level (e.g., _LoadingDocuments -> root)
                    resolved = resolved; // Stay at root
                }
            } else {
                // Current key is at root (no directory), ../ stays at root
                resolved = resolved;
            }
        } else {
            // Current key is empty (root), ../ stays at root
            resolved = resolved;
        }
    }
    // No relative indicators - prepend base directory if we're in a subdirectory
    else {
        if (currentBaseDir && !resolved.startsWith(currentBaseDir) && !resolved.startsWith('/')) {
            resolved = currentBaseDir + resolved;
        }
    }
    
    return resolved;
}

/**
 * Scroll to top button for mobile in moh93 project
 */
(function() {
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initScrollToTop);
    } else {
        initScrollToTop();
    }
    
    function initScrollToTop() {
        // Only create for moh93 project
        if (!window._isMoh93Project) {
            return;
        }
        
        // Create the scroll to top button
        var scrollBtn = document.createElement('button');
        scrollBtn.className = 'scroll-to-top-btn';
        scrollBtn.innerHTML = '↑';
        scrollBtn.setAttribute('aria-label', 'Scroll to top');
        scrollBtn.setAttribute('title', 'Scroll to top');
        
        // Add click handler - scroll to show inputSearch
        scrollBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            // Find the inputSearch element
            var inputSearch = document.getElementById('inputSearch');
            if (inputSearch) {
                // Scroll to show the inputSearch element
                inputSearch.scrollIntoView({ 
                    behavior: 'smooth', 
                    block: 'start' 
                });
            } else {
                // Fallback: scroll to top
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth'
                });
            }
            
            return false;
        });
        
        // Append to body
        document.body.appendChild(scrollBtn);
        
        // Show/hide button based on scroll position and viewport
        function toggleScrollButton() {
            // Only show on mobile (viewport width <= 768px)
            if (window.innerWidth <= 768) {
                // Always show on mobile, or show when scrolled down
                scrollBtn.classList.add('show');
            } else {
                scrollBtn.classList.remove('show');
            }
        }
        
        // Check scroll position on scroll and resize
        window.addEventListener('scroll', toggleScrollButton);
        window.addEventListener('resize', toggleScrollButton);
        
        // Initial check - show on load
        toggleScrollButton();
    }
})();

