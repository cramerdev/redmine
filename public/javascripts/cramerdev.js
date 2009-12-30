/** Redmine js extensions for cramerdev */

/*global document, $$, Element */

document.observe("dom:loaded", function () {

/**
 * Change any custom field that ends in "URL:" to a link containing the
 *  value
 */
$$(".issue table tr td[valign='top'] b").each(function (label) {
    var el, t;
    if (label.innerHTML.match(/^.*URL\:$/) !== null) {
        el = label.up().next().down();
        t = el.innerHTML;
        el.update(new Element("a", { href: t }).update(t));
    }
});

});
