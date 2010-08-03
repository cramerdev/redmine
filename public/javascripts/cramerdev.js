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

/**
 * Turn off autocomplete on input fields (except username on log in) cuz
 * it's lame to see that popup everytime I enter a ticket that starts
 * with the same letters. - Marino 8/3/2010
 */
$$('input[type="text"]').each(function (i) {
    if (i.id !== "username") {
        i.writeAttribute("autocomplete", "off");
    }
});

});
