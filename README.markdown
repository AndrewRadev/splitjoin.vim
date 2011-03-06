This plugin is meant to simplify a task I've found too common in my workflow:
switching between a single-line statement and a multi-line one.

The idea is to have a single key binding for transforming a line like this:

    <div id="foo">bar</div>

Into this:

    <div id="foo">
      bar
    </div>

And the other way around.

For now, this transformation for HTML tags is all that works (with issues),
although this could also work for ruby blocks, if/unless statements and option
hashes. It shouldn't be a problem to do this for other languages as well, but
these are the ones I'm interested in in the moment.
