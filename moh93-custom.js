// Production-specific custom functions for md.htm
// This file contains functions needed for production URLs that may have complex query parameters

/**
 * Get query string for `src` parameter to the end, including other AWS parameters, etc, signature
 * This function extracts everything after "src=" to handle URLs with query parameters
 * @param {string} key - The query parameter key (should be "src")
 * @returns {string} The decoded value of the query parameter
 */
function getQuery2(key) {
    var query = window.location.search.substring(1);
    let index = query.indexOf(key);
    var srcString = query.substring(index, query.length);
    srcString = srcString.replace("src=", "");
    
    // Decode the URL-encoded string
    try {
        srcString = decodeURIComponent(srcString);
    } catch (e) {
        // If decoding fails, use the original string
        console.log('Failed to decode srcString:', e);
    }
    
    console.log('srcString', srcString);

    return srcString;
}

