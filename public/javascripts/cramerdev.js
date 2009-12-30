/** Redmine js extensions for cramerdev */

/*global document, $$, Element */

document.observe("dom:loaded", function () {

/**
 * Change any custom field that ends in "URL:" to a link containing the
 *  value
 */
$$("table.attributes tr th").each(function (label) {
    var el, t;
    if (label.innerHTML.match(/^.*URL\:$/) !== null) {
        el = label.next();
        t = el.innerHTML;
        el.update(new Element("a", { href: t }).update(t));
    }
});

});
